FROM golang:1.12-alpine as build

ARG EVENTROUTER_VERSION

ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=arm64

WORKDIR /go/src/github.com/heptiolabs/eventrouter

RUN apk add --no-cache openssh-client 'git>=2.12.0' 'gnutls>=3.6.7' gnupg gawk socat build-base gcc wget bash curl \
    && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing git-secret

RUN git clone https://github.com/heptiolabs/eventrouter.git .
RUN git checkout ${EVENTROUTER_VERSION}
RUN go build

#
# Deploy
#

FROM arm64v8/alpine:3.9

WORKDIR /app

RUN apk add --no-cache ca-certificates

COPY --from=build /go/src/github.com/heptiolabs/eventrouter/eventrouter /app/eventrouter

RUN chmod +x /app/eventrouter

USER nobody:nobody

CMD ["/bin/sh", "-c", "/app/eventrouter -v 3 -logtostderr"]