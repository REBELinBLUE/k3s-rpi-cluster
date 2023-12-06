# ARM Docker Images

> Note: These builds were run on macOS with docker desktop, I have not attempted to build them elsewhere

## Dev Utils

```bash
cd dev

docker build -f Dockerfile \
    -t rebelinblue/utils:0.1 \
    -t rebelinblue/utils:latest .

docker push rebelinblue/utils
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
