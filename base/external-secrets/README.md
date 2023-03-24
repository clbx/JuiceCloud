# External-Secrets

```
helm repo add external-secrets https://charts.external-secrets.io
helm repo update
```

```
helm upgrade --install external-secrets \
   external-secrets/external-secrets \
    -n external-secrets \
    --create-namespace \
    --set installCRDs=true
```

``vault-backend.yaml`` tells ExternalSecrets to look at my vault installation (``/base/vault``).

There is another secret being used that is not commited to this repository that holds the token used to access vault.

