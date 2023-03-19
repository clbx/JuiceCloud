# Authentik

```
helm repo add authentik https://charts.goauthentik.io
helm repo update
```

```
helm upgrade --install authentik authentik/authentik -f values.yaml --namespace auth
```

## LDAP Certs

I haven't automated issuing LDAP Certs for Authentik, so I just make them manually and then upload them to authentik. 

```
sudo certbot certonly -d ldap.juicecloud.org --dns-route53 -m clay@clbx.io --agree-tos --non-interactive --server https://acme-v02.api.letsencrypt.org/directory
```