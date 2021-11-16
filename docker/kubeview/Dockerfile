#
# Compile
#

FROM node:10-alpine as vue-build

ARG KUBEVIEW_VERSION

RUN apk add --no-cache openssh-client 'git>=2.12.0' 'gnutls>=3.6.7' gnupg gawk socat build-base gcc wget bash curl \
    && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing git-secret

WORKDIR /build

RUN git clone https://github.com/REBELinBLUE/kubeview.git . && \
    git checkout master

# Install all the Vue.js dev tools & CLI, and our app dependencies
RUN cp web/client/package*.json ./ && \
    npm install --silent

# Copy in the Vue.js app source
RUN cp web/client/.env.production . && \
    cp web/client/.eslintrc.js . && \
    cp -R web/client/public ./public && \
    cp -R web/client/src ./src

# Run Vue CLI build & bundle, and output to ./dist
RUN npm run build

FROM golang:1.12-alpine as go-build

ARG goPackage="github.com/rebelinblue/kubeview/cmd/server"
ARG version="${KUBEVIEW_VERSION}"
ARG buildInfo="Local Docker build"

COPY --from=vue-build /build/cmd /build/cmd
COPY --from=vue-build /build/go.mod /build
COPY --from=vue-build /build/go.sum /build

WORKDIR /build

ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=arm

ENV PORT 8000

# Install system dependencies
RUN apk --no-cache add git gcc musl-dev

# Fetch and cache Go modules
RUN go mod download

# Now run the build
# Disabling cgo results in a fully static binary that can run without C libs
# Also inject version and build details
RUN GO111MODULE=on CGO_ENABLED=0 GOOS=linux go build \
    -ldflags "-X main.version=$version -X 'main.buildInfo=$buildInfo'" \
    -o server \
    $goPackage

#
# Deploy
#

FROM scratch
WORKDIR /app

EXPOSE 8000

# Copy in output from Vue bundle (the dist)
# Copy the server binary
COPY --from=vue-build /build/dist ./frontend
COPY --from=go-build /build/server .

# That's it! Just run the server with incluster mode enabled
ENV IN_CLUSTER=true
CMD [ "./server"]
