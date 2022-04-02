[![Testing](https://github.com/vbem/kubeconfig4sa/actions/workflows/test.yml/badge.svg)](https://github.com/vbem/kubeconfig4sa/actions/workflows/test.yml)
[![Super Linter](https://github.com/vbem/kubeconfig4sa/actions/workflows/linter.yml/badge.svg)](https://github.com/vbem/kubeconfig4sa/actions/workflows/linter.yml)
[![Marketplace](https://img.shields.io/badge/GitHub%20Actions-Marketplace-orange?logo=github)](https://github.com/marketplace/actions/kubernetes-set-context-and-kubeconfig-for-service-account-sa)

# Set kubeconfig for service account

This action can be used to generate [*kubeconfig file*](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/) for [Kubernetes native *Service Accounts* (SA)](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/).

It's advised to use **Kubernetes native SA** for deployment workflows rather than cloud provider's User accounts because:
- User accounts are for humans. Service accounts are for processes.
- User accounts are intended to be global. Names must be unique across all namespaces of a cluster. Service accounts are namespaced.
- Typically, a cluster's user accounts might be synced from a corporate database or cloud IAM, where new user account creation requires special privileges and is tied to complex business processes. Service account creation is intended to be more lightweight, allowing cluster users to create service accounts for specific tasks by following the principle of least privilege.

Meanwhile, as mentioned in GitHub official document: [**Never use structured data as a secret**](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions#using-secrets). Put base64 content of whole *kubeconfig file* into a GitHub secret can cause secret redaction within logs to fail! Instead, create individual secrets for each sensitive value, such as *CA data* of cluster & *bearer token* of service account.

## Example usage

```yaml
- name: Setup KUBECONFIG
  uses: vbem/kubeconfig4sa@v1
  with:
    server:     https://your-kubeapi-server:6443
    ca-base64:  ${{ secrets.K8S_CA_BASE64 }}
    token:      ${{ secrets.K8S_SA_TOKEN }}
    namespace:  MYNS

- name: Deploy K8s mainfest files
  run: kubectl apply -f .
```

![Example](https://repository-images.githubusercontent.com/476765075/c8bf8e19-72f4-4904-b820-200b2b474d0d "vbem/kubeconfig4sa")

## SA preparation

Assuming you need to create a service account `deployer` for namespace `MYNS`, and then deploy K8s mainfest files via this action.

First, you may need to [create a SA](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#service-account-tokens) in you K8s cluster:
```shell
kubectl create sa deployer -n MYNS
```

Then, [grant particular permissions](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#service-account-permissions) to this SA:
```shell
kubectl create rolebinding deployer --clusterrole=cluster-admin --serviceaccount=MYNS:deployer
```

After that, extract *Certificate Authority base64 data* & *bearer token* from [*associated secret* of this SA](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#service-account-tokens):
```shell
as=$(kubectl get sa deployer -n MYNS -o jsonpath='{.secrets[0].name}') && echo "associated secret: $as"
ca=$(kubectl get secret $as -n MYNS -o jsonpath='{.data.ca\.crt}') && echo "K8S_CA_BASE64: $ca"
to=$(kubectl get secret $as -n MYNS -o jsonpath='{.data.token}'|base64 -d) && echo "K8S_SA_TOKEN: $to"
```

Remember to store both `K8S_CA_BASE64` & `K8S_SA_TOKEN` in your Git repo's [*Encrypted secrets*](https://docs.github.com/en/actions/security-guides/encrypted-secrets) or [*Environment secrets*](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment#environment-secrets).

## Inputs

ID | Type | Default | Description
--- | --- | --- | ---
`server` | String | *Required input* | K8s cluster API server URL
`ca-base64` | String  | *Required input* | K8s cluster Certificate Authority data base64
`cluster` | String | Host part of `server` | K8s cluster name in kubeconfig file
`token` | String | *Required input* | Service Account bearer token
`sa` | String | `sa` | Service Account name in kubeconfig file
`context` | String | `<sa>@<cluster>` | Context name in kubeconfig file
`namespace` | String | `<empty>` | Context namespace in kubeconfig file
`current` | Bool | `true` | Set as current-context in kubeconfig file
`kubeconfig` | String | `<runner.temp>/<context>.kubeconfig` | Path of kubeconfig file
`export` | Bool | `true` | Set the KUBECONFIG environment variable available to subsequent steps
`version` | Bool | `true` | Show client and server version information for the current context

## Outputs

ID | Type | Description
--- | --- | ---
`context` | String | Context name in kubeconfig file
`kubeconfig` | String | Path of kubeconfig file