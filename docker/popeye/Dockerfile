FROM golang:1.13.5-alpine AS build

ARG POPEYE_VERSION

ENV VERSION=v$POPEYE_VERSION \
    GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=arm \
    PACKAGE=github.com/derailed/popeye

WORKDIR /go/src/github.com/derailed/popeye

RUN apk add --no-cache openssh-client 'git>=2.12.0' 'gnutls>=3.6.7' gnupg gawk socat build-base gcc wget bash curl \
    && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing git-secret \
    && apk update && apk upgrade && apk --no-cache add git ca-certificates

RUN git clone https://github.com/derailed/popeye.git .
RUN git checkout v${POPEYE_VERSION}

RUN go build -o /go/bin/popeye -trimpath -ldflags="-w -s -X $PACKAGE/cmd.version=$VERSION" *.go

#
# Deploy
#

FROM arm32v6/alpine:3.11.2

COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /go/bin/popeye /bin/popeye

ENTRYPOINT [ "/bin/popeye" ]