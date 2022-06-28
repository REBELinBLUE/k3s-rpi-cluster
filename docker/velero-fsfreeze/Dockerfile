FROM arm64v8/alpine:3.10

RUN apk add --no-cache ca-certificates
RUN apk add --update --no-cache busybox util-linux

ENTRYPOINT ["/bin/sh", "-c", "while true; do sleep 10000; done"]