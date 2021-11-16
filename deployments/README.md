# Deployments Not Using HelmRelease

- **flux**
    - **flux-cloud** - No chart exists
- **infra**
    - **linode-dynamic-dns** - Custom app
    - **minio** - Doesn't support initContainer
    - **traefik-forward-auth** - No chart exists
- **kube-system**
    - **kured** - Doesn't support initContainer
    - **local-path-provisioner** -
- **kubernetes-dashboard**
    - **dashboard** - Chart is for v1
- **monitoring**
    - **alertmanager** - Doesn't support initContainer
    - **prometheus**
- **vault**
    - **vault** - Custom app


