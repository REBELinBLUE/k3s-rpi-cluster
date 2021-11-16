#
# Compile
#

FROM golang:1.12-alpine as build

ARG VELERO_AWS_PLUGIN_VERSION

ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOARCH=arm \
    GOARM=7 \
    GOOS=linux

WORKDIR /go/src/github.com/vmware-tanzu/velero-plugin-for-aws

RUN apk add --no-cache curl ca-certificates git
RUN git clone https://github.com/vmware-tanzu/velero-plugin-for-aws.git .
RUN git checkout ${VELERO_AWS_PLUGIN_VERSION}
RUN go build -o /go/bin/velero-plugin-for-aws ./velero-plugin-for-aws

#
# Deploy
#

FROM arm32v7/alpine:3.10

RUN apk add --no-cache bash ca-certificates
RUN mkdir /plugins

COPY --from=build /go/bin/velero-plugin-for-aws /plugins/velero-plugin-for-aws
RUN chmod +x /plugins/velero-plugin-for-aws

ENTRYPOINT ["/bin/bash", "-c", "cp /plugins/* /target/."]