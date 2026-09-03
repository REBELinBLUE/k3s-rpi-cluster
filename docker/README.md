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
