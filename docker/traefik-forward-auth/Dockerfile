#
# Compile
#

FROM golang:1.12-alpine AS builder

ARG FORWARD_AUTH_VERSION
ARG BUILD_DATE
ARG VCS_REF

ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=arm

WORKDIR /go/src/github.com/funkypenguin/traefik-forward-auth

RUN apk add --no-cache git

RUN git clone https://github.com/funkypenguin/traefik-forward-auth.git . && \
    git checkout master
    #${FORWARD_AUTH_VERSION}

# Add libraries
RUN apk add --no-cache git && \
  go get "github.com/namsral/flag" && \
  go get "github.com/sirupsen/logrus" && \
  apk del git

# Copy & build
RUN go build -a -installsuffix nocgo -o /traefik-forward-auth .

#
# Deploy
#

FROM arm32v6/alpine:3.10

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /traefik-forward-auth /

ENTRYPOINT ["/traefik-forward-auth"]