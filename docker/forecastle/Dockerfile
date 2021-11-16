#
# Compile
#

FROM alpine:3.10.0 as clone

ARG FORECASTLE_VERSION

RUN apk add --no-cache git

WORKDIR /usr/src/app

RUN git clone https://github.com/stakater/Forecastle.git .
RUN git checkout ${FORECASTLE_VERSION}

FROM node:12.11.1 as build-ui

WORKDIR /usr/src/app/frontend

COPY --from=clone /usr/src/app/frontend .
RUN yarn install --network-timeout 500000 && yarn build

FROM golang:1.13.1-alpine as build

ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=arm

RUN mkdir -p "${GOPATH}/src/github.com/stakater/Forecastle/frontend/"

RUN apk add --no-cache git build-base

WORKDIR $GOPATH/src/github.com/stakater/Forecastle

ARG PACKR_VERSION=2.7.1
ARG PACKR_FILENAME=packr_${PACKR_VERSION}_linux_386.tar.gz
ARG PACKR_URL=https://github.com/gobuffalo/packr/releases/download/v${PACKR_VERSION}/${PACKR_FILENAME}

RUN mkdir -p /tmp/packr/ && \
    wget ${PACKR_URL} -O /tmp/packr/${PACKR_FILENAME} && \
    tar -xzvf /tmp/packr/${PACKR_FILENAME} -C /tmp/packr/ && \
    mv /tmp/packr/packr2 /usr/local/bin/packr2 && \
    rm -rf /tmp/packr

COPY --from=clone /usr/src/app/pkg ./pkg
COPY --from=clone /usr/src/app/forecastle.go .
COPY --from=clone /usr/src/app/go.sum .
COPY --from=clone /usr/src/app/go.mod .

COPY --from=build-ui /usr/src/app/frontend/build ./frontend/build

RUN go mod download && \
    packr2 build -a --installsuffix cgo --ldflags="-s" -o /Forecastle && \
    packr2 clean && \
    chmod +x /Forecastle

FROM alpine:3.10.0@sha256:ca1c944a4f8486a153024d9965aafbe24f5723c1d5c02f4964c045a16d19dc54 as certs

RUN apk --no-cache add ca-certificates

#
# Deploy
#

FROM arm32v6/alpine:3.10.0

COPY --from=certs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /Forecastle /bin/Forecastle

ENTRYPOINT ["/bin/Forecastle"]
