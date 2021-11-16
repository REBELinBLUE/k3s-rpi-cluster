#
# Compile
#

FROM golang:1.13-alpine as build

ARG VERSION
ARG KUBECTL_VERSION

ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=arm \
    GOARM=7

RUN apk add --no-cache curl ca-certificates git bash

# build kured
WORKDIR /go/src/github.com/weaveworks/kured

RUN curl -L -o /usr/bin/kubectl "https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/${GOARCH}/kubectl" && \
    chmod +x /usr/bin/kubectl

RUN git clone --depth 1 -b "${VERSION}" https://github.com/weaveworks/kured.git .
RUN go build -o kured ./cmd/kured/

#
# Deploy
#

FROM arm32v6/alpine:3.11.3

RUN apk add --no-cache bash ca-certificates

COPY --from=build /usr/bin/kubectl /usr/bin/kubectl
RUN chmod +x /usr/bin/kubectl

COPY --from=build /go/src/github.com/weaveworks/kured/kured /usr/bin/kured
RUN chmod +x /usr/bin/kured

ENTRYPOINT ["/usr/bin/kured"]
