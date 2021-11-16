#
# Compile
#

FROM golang:1.13.1-alpine3.10 AS build

ARG CONFD_VERSION

ENV CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=arm

RUN apk add --no-cache make git

RUN mkdir -p /go/src/github.com/kelseyhightower/ && \
  ln -s /go/src/github.com/kelseyhightower/confd /app

WORKDIR /go/src/github.com/kelseyhightower/confd

RUN git clone https://github.com/kelseyhightower/confd.git . && \
    git checkout master && \
    make
 # ${CONFD_VERSION}

#
# Deploy
#

FROM arm32v6/alpine:3.10

COPY entrypoint.sh /entrypoint.sh

COPY --from=build /app/bin/confd /usr/bin/confd

RUN apk add --update --no-cache \
        openssl \
        curl \
        ca-certificates \
        bind-tools \
        net-tools \
        jq \
        bash && \
    mkdir /etc/confd && \
    chmod +x /usr/bin/confd /entrypoint.sh

# User needs to be root as the entrypoint needs to write to /etc
USER root

ENTRYPOINT ["/entrypoint.sh"]

CMD ["confd"]
