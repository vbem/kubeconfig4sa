# Kubernetes Set Context and KUBECONFIG for Service Account (SA)


# https://kubernetes.io/zh/docs/reference/access-authn-authz/service-accounts-admin/
# https://kubernetes.io/zh/docs/tasks/configure-pod-container/configure-service-account/
# https://kubernetes.io/zh/docs/tasks/run-application/access-api-from-pod/
# kubectl --server="https://kubernetes.default.svc.cluster.local" --certificate-authority=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt --token=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token) sub-commands

# https://kubernetes.io/zh/docs/reference/access-authn-authz/rbac/#service-account-permissions
# https://kubernetes.io/zh/docs/reference/access-authn-authz/rbac/#user-facing-roles
# kubectl create rolebinding sa-default-view --clusterrole=view --serviceaccount=dev-ds:default --namespace=dev-ds




kubectl create rolebinding deployer --clusterrole=cluster-admin --serviceaccount=deployer

kubectl create sa deployer

