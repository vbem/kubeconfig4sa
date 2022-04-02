#!/usr/bin/env bash

[[ -v _KIT_BASH ]] && return # avoid duplicated source
_KIT_BASH="$(realpath "${BASH_SOURCE[0]}")"; declare -r _KIT_BASH # sourced sential

# Log to stderr
#   $1: level string
#   $2: message string
#   stderr: message string
#   $?: 0
function kit::log::stderr {
    local level
    case "$1" in
        FATAL|ERR*)     level="\e[1;91m$1\e[0m" ;;
        WARN*)          level="\e[1;95m$1\e[0m" ;;
        INFO*|NOTICE)   level="\e[1;92m$1\e[0m" ;;
        DEBUG)          level="\e[1;96m$1\e[0m" ;;
        *)              level="\e[1;94m$1\e[0m" ;;
    esac
    echo -e "\e[2;97m[\e[0m$level\e[2;97m]\e[0m \e[93m$2\e[0m" >&2
    #echo "[$(date -Isecond) $1] $2" >&2
}

# Group stdin to stdout with title
# $1: group title
# https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#grouping-log-lines
function kit::wf::group {
    echo "::group::$1"      >&2
    echo "$(< /dev/stdin)"  >&2
    echo '::endgroup::'     >&2
}

# Set stdin as value to environment with given name
# $1: environment variable name
# https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#setting-an-environment-variable
function kit::wf::env {
    local val
    val="$(< /dev/stdin)"
    echo "$1<<__HEREDOC__"  >> "$GITHUB_ENV"
    echo "$val"             >> "$GITHUB_ENV"
    echo '__HEREDOC__'      >> "$GITHUB_ENV"
    kit::wf::group "💲 append '$1' to \$GITHUB_ENV" <<< "$val"
}

# Set stdin as value to output of current step with given name
# $1: output name
# https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#setting-an-output-parameter
# https://renehernandez.io/snippets/multiline-strings-as-a-job-output-in-github-actions/
function kit::wf::output {
    local val
    val="$(< /dev/stdin)"
    echo "::set-output name=$1::$val" >&2
    kit::wf::group "💬 set '$1' to step outputs" <<< "$val"
}

# Flatten JSON to key-value lines
#   $1: separator (default as ' 👉 ')
function kit::json::flatten {
    jq -Mcr --arg sep "${1:- 👉 }" 'paths(type!="object" and type!="array") as $p | {"key":$p|join("."),"value":getpath($p)} | "\(.key)\($sep)\(.value|@json)"'
}

# Set kube-config (for service-account), you should set KUBECONFIG
#   $1: K8S_NAME
#   $2: K8S_SERVER
#   $3: K8S_CA_BASE64
#   $4: K8S_USER
#   $5: K8S_TOKEN
#   $6: K8S_CONTEXT_NAMESPACE
function kit::k8s::configSet {
    local name="$1" server="$2" ca_base64="$3" user="$4" token="$5" ctx_ns="$6"
    kit::log::stderr DEBUG "🚢 kubectl config set ... for KUBECONFIG='$KUBECONFIG'"
    kubectl config set-cluster "$name" --server="$server"
    kubectl config set "clusters.$name.certificate-authority-data" "$ca_base64"
    kubectl config set-credentials "$user" --token="$token"
    kubectl config set-context "$user.$name" --cluster="$name" --user="$user" --namespace="$ctx_ns"
    kubectl config use-context "$user.$name"
}

# kubectl config view
function kit::k8s::configView {
    kubectl config view --raw=false | yq -Ce | kit::wf::group "🚢 kubectl config view for KUBECONFIG='$KUBECONFIG'"
}

# kubectl cluster-info
function kit::k8s::clusterInfo {
    kubectl cluster-info | kit::wf::group "🚢 kubectl cluster-info for KUBECONFIG='$KUBECONFIG'"
}

# kubectl cluster-info
function kit::k8s::version {
    kubectl version -o yaml | yq -Ce | kit::wf::group "🚢 kubectl version for KUBECONFIG='$KUBECONFIG'"
}

# Initialize kube-config and test
function kit::k8s::init {
    kit::k8s::configSet "$@"
    kit::k8s::configView && kit::k8s::version && kit::k8s::clusterInfo
    [[ -v KUBECONFIG ]] && kit::wf::env 'KUBECONFIG' <<< "$KUBECONFIG" || true
}

# Get dockerconfigjson
#   $1: CR_HOST
#   $2: CR_USER
#   $3: CR_TOKEN
function kit::k8s::dockerconfigjson {
    kit::log::stderr DEBUG "🔑 Generating dockerconfigjson for $2@$1"
    kubectl create secret docker-registry 'tmp' \
      --dry-run=client -o yaml \
      --docker-server="$1" \
      --docker-username="$2" \
      --docker-password="$3" \
    | yq -Me '.data[.dockerconfigjson]'
}


# Main function.
#   $?: 0 if successful and non-zero otherwise
function main {
    pwd
    env
}

main "$@"