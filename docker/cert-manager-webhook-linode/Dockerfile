FROM golang:1.25-alpine AS build_deps

ARG WEBHOOK_VERSION

RUN apk add --no-cache git

WORKDIR /workspace

RUN git clone https://github.com/linode/cert-manager-webhook-linode.git . && \
    git checkout ${WEBHOOK_VERSION}

RUN go mod download

FROM build_deps AS build

COPY --from=build_deps /workspace .

RUN CGO_ENABLED=0 go build -o webhook -ldflags '-w -extldflags "-static"' .

FROM alpine:3.23

RUN apk add --no-cache ca-certificates

COPY --from=build /workspace/webhook /usr/local/bin/webhook

ENTRYPOINT ["webhook"]