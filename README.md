## About

This action can be used to generate [*kubeconfig file*](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/) for [Kubernetes native *Service Accounts* (SA)](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/).

It's advised to use **Kubernetes native SA** for deployment workflows rather than cloud provider's User accounts because:
- User accounts are for humans. Service accounts are for processes.
- User accounts are intended to be global. Names must be unique across all namespaces of a cluster. Service accounts are namespaced.
- Typically, a cluster's user accounts might be synced from a corporate database or cloud IAM, where new user account creation requires special privileges and is tied to complex business processes. Service account creation is intended to be more lightweight, allowing cluster users to create service accounts for specific tasks by following the principle of least privilege.

## Example usage

```yaml
- name: Setup KUBECONFIG
  uses: vbem/kubeconfig4sa@main
  with:
    server:     https://your-kubeapi-server:6443
    ca-base64:  ${{ secrets.K8S_CA_BASE64 }}
    token:      ${{ secrets.K8S_SA_TOKEN }}
    namespace:  myns
    
- name: Deploy K8s mainfest files
  run: kubectl apply -f .
```

## Customizing

### inputs


Name | Type | Required | Default | Description
--- | --- | --- | --- | ---
server | String | Y |  | K8s cluster API server URL



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
