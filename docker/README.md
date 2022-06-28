# ARM Docker Images

> Note: These builds were run on macOS with docker desktop, I have not attempted to build them elsewhere

## Event Router

```bash
cd event-router

docker build -f Dockerfile \
    --build-arg EVENTROUTER_VERSION="master" \
    -t rebelinblue/eventrouter:0.3 \
    -t rebelinblue/eventrouter:latest .

docker push rebelinblue/eventrouter
```

## Kubeview

```bash
cd kubeview

docker build -f Dockerfile \
    --build-arg KUBEVIEW_VERSION="0.1.14" \
    -t rebelinblue/kubeview-arm:0.1.14 \
    -t rebelinblue/kubeview-arm:latest .

docker push rebelinblue/kubeview-arm
```

## Traefik Forward Authentication

```bash
cd traefik-forward-auth

docker build -f Dockerfile \
    --build-arg FORWARD_AUTH_VERSION="v2.0.0-rc2" \
    -t rebelinblue/traefik-forward-auth:2.0.0-rc2 \
    -t rebelinblue/traefik-forward-auth:latest .

docker push rebelinblue/traefik-forward-auth
```

## Vault

```bash
cd vault

docker build -f Dockerfile \
    --build-arg VAULT_VERSION="1.11.0" \
    -t rebelinblue/vault:1.11.0 \
    -t rebelinblue/vault:latest .

docker push rebelinblue/vault
```

## Vault Consumer

```bash
cd vault-consumer

docker build -f Dockerfile \
    --build-arg CONFD_VERSION="v0.17.0-dev" \
    -t rebelinblue/vault-consumer:0.0.3 \
    -t rebelinblue/vault-consumer:latest .

docker push rebelinblue/vault-consumer
```

## Velero FS Freeze

```bash
cd velero-fsfreeze

docker build -f Dockerfile \
    -t rebelinblue/velero-fsfreeze:0.0.1 \
    -t rebelinblue/velero-fsfreeze:latest .

docker push rebelinblue/velero-fsfreeze
```

## Velero AWS Plug-in

```bash
cd velero-plugin-for-aws

docker build -f Dockerfile \
    --build-arg VELERO_AWS_PLUGIN_VERSION="v1.5.0" \
    -t rebelinblue/velero-plugin-for-aws:1.5.0 \
    -t rebelinblue/velero-plugin-for-aws:latest .

docker push rebelinblue/velero-plugin-for-aws
```
