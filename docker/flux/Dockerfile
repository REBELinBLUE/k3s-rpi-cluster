#
# Compile
#

FROM golang:1.12-alpine as build

ARG FLUX_VERSION
ARG KUBECTL_VERSION
ARG KUSTOMIZE_VERSION
ARG SOPS_VERSION

ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=arm

WORKDIR /go/src/github.com/fluxcd/flux

RUN apk add --no-cache openssh-client 'git>=2.12.0' 'gnutls>=3.6.7' gnupg gawk socat build-base gcc wget bash curl \
    && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing git-secret

# Download kubectl
RUN curl -L -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/arm/kubectl

# Build flux
RUN git clone https://github.com/fluxcd/flux.git .
RUN git checkout ${FLUX_VERSION}
RUN go build -o fluxd ./cmd/fluxd
RUN go build -o fluxctl ./cmd/fluxctl

# Build kustomize
WORKDIR /go/src/github.com/kubernetes-sigs/kustomize
RUN git clone https://github.com/kubernetes-sigs/kustomize.git .
RUN git checkout ${KUSTOMIZE_VERSION}
RUN go build -o kustomize ./cmd/kustomize

WORKDIR /go/src/github.com/mozilla/sops/
RUN git clone https://github.com/mozilla/sops.git .
RUN git checkout ${SOPS_VERSION}
RUN go build -o sops ./cmd/sops

FROM quay.io/squaremo/kubeyaml:0.7.0 as kubeyaml

#
# Deploy
#

FROM arm32v6/alpine:3.10

WORKDIR /home/flux

RUN apk add --no-cache openssh-client ca-certificates tini 'git>=2.12.0' 'gnutls>=3.6.7' gnupg gawk socat \
    && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing git-secret

RUN [ ! -e /etc/nsswitch.conf ] && echo 'hosts: files dns' > /etc/nsswitch.conf
COPY ./kubeconfig /root/.kube/config

COPY ./known_hosts.sh /home/flux/known_hosts.sh
RUN sh /home/flux/known_hosts.sh /etc/ssh/ssh_known_hosts \
    && rm /home/flux/known_hosts.sh

# Add default SSH config, which points at the private key we'll mount
COPY ./ssh_config /etc/ssh/ssh_config

COPY --from=build /go/src/github.com/fluxcd/flux/fluxd /usr/local/bin/fluxd
RUN chmod +x /usr/local/bin/fluxd

COPY --from=build /go/src/github.com/fluxcd/flux/fluxctl /usr/local/bin/fluxctl
RUN chmod +x /usr/local/bin/fluxctl

COPY --from=build /go/src/github.com/kubernetes-sigs/kustomize /usr/local/bin/kustomize
RUN chmod +x /usr/local/bin/kustomize

COPY --from=build /go/src/github.com/mozilla/sops/sops /usr/local/bin/sops
RUN chmod +x /usr/local/bin/sops

COPY --from=build /usr/local/bin/kubectl /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl

COPY --from=kubeyaml /usr/lib/kubeyaml/ /usr/lib/kubeyaml/

ENV PATH=/bin:/usr/bin:/usr/local/bin:/usr/lib/kubeyaml

ENTRYPOINT ["/sbin/tini", "--", "fluxd"]