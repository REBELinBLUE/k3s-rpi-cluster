#
# Compile
#

FROM golang:1.13-alpine as build

ARG KUBECTL_VERSION
ARG HELM_VERSION
ARG HELM3_VERSION
ARG VERSION

ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOARCH=arm\
    GOARM=7 \
    GOOS=linux

RUN apk add --no-cache openssh-client git gnutls gnupg gawk socat curl ca-certificates \
    && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing git-secret

WORKDIR /go/src/github.com/fluxcd/helm-operator

RUN curl -k -sSfL -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/${GOARCH}/kubectl

RUN curl -k -sSfL -o /tmp/helm-${HELM_VERSION}-linux-${GOARCH}.tar.gz https://get.helm.sh/helm-${HELM_VERSION}-linux-${GOARCH}.tar.gz && \
    tar -xvf /tmp/helm-${HELM_VERSION}-linux-${GOARCH}.tar.gz -C /tmp && \
    mv /tmp/linux-${GOARCH}/helm /usr/local/bin/helm2 && \
    chmod +x /usr/local/bin/helm2 && \
    rm -rf /tmp/*

RUN curl -k -sSfL -o /tmp/helm-${HELM3_VERSION}-linux-${GOARCH}.tar.gz https://get.helm.sh/helm-${HELM3_VERSION}-linux-${GOARCH}.tar.gz && \
    tar -xvf /tmp/helm-${HELM3_VERSION}-linux-${GOARCH}.tar.gz -C /tmp && \
    mv /tmp/linux-${GOARCH}/helm /usr/local/bin/helm3 && \
    chmod +x /usr/local/bin/helm3 && \
    rm -rf /tmp/*

RUN git clone --depth 1 -b ${VERSION} https://github.com/fluxcd/helm-operator . && \
    go build -o helm-operator ./cmd/helm-operator

#
# Deploy
#

FROM arm32v6/alpine:3.10

ENV HELM_HOME=/var/fluxd/helm

WORKDIR /home/flux

RUN apk add --no-cache openssh-client ca-certificates tini git socat \
    && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing git-secret

COPY ./known_hosts.sh /home/flux/known_hosts.sh
RUN chmod +x /home/flux/known_hosts.sh \
    && sh /home/flux/known_hosts.sh /etc/ssh/ssh_known_hosts \
    && rm /home/flux/known_hosts.sh

COPY ./ssh_config /etc/ssh/ssh_config

RUN mkdir -p /var/fluxd/helm/repository/cache/
COPY ./helm-repositories.yaml /var/fluxd/helm/repository/repositories.yaml

COPY --from=build /go/src/github.com/fluxcd/helm-operator/helm-operator /usr/local/bin/helm-operator
RUN chmod +x /usr/local/bin/helm-operator

COPY --from=build /usr/local/bin/helm2 /usr/local/bin/helm2
RUN chmod +x /usr/local/bin/helm2

COPY --from=build /usr/local/bin/helm3 /usr/local/bin/helm3
RUN chmod +x /usr/local/bin/helm3

COPY --from=build /usr/local/bin/kubectl /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl

ENTRYPOINT ["/sbin/tini", "--", "helm-operator"]
