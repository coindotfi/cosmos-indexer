FROM golang:1.22-alpine3.18 AS build-env

# Customize to your build env

# TARGETPLATFORM should be one of linux/amd64 or linux/arm64
ARG TARGETPLATFORM

# Use muslc for static libs
ARG BUILD_TAGS=muslc
ARG LD_FLAGS=-linkmode=external -extldflags '-Wl,-z,muldefs -static'

# Install cli tools for building and final image
RUN apk add --update --no-cache curl make git libc-dev bash gcc linux-headers eudev-dev ncurses-dev libc6-compat jq htop atop iotop

# Install build dependencies.
RUN if [ "${TARGETPLATFORM}" = "linux/amd64" ] ; then \
      wget -P /lib https://github.com/CosmWasm/wasmvm/releases/download/v1.2.3/libwasmvm_muslc.x86_64.a ; \
      cp /lib/libwasmvm_muslc.x86_64.a /lib/libwasmvm_muslc.a ; \
    fi

RUN if  [ "${TARGETPLATFORM}" = "linux/arm64" ] ; then \
      wget -P /lib https://github.com/CosmWasm/wasmvm/releases/download/v1.2.3/libwasmvm_muslc.aarch64.a ; \
      cp /lib/libwasmvm_muslc.aarch64.a /lib/libwasmvm_muslc.a ; \
    fi

# Build main app.
WORKDIR /go/src/app
COPY . .
RUN if [ "${TARGETPLATFORM}" = "linux/amd64" ] ; then \
      GOOS=linux GOARCH=amd64 CGO_ENABLED=1 go install -ldflags ${LD_FLAGS} -tags ${BUILD_TAGS} ; \
    fi

RUN if [ "${TARGETPLATFORM}" = "linux/arm64" ] ; then \
      GOOS=linux GOARCH=arm64 CGO_ENABLED=1 go install -ldflags ${LD_FLAGS} -tags ${BUILD_TAGS} ; \
    fi

# Use busybox to create a user
FROM busybox:stable-musl AS busybox
RUN addgroup --gid 1137 -S cosmos-indexer && adduser --uid 1137 -S cosmos-indexer -G cosmos-indexer

# Use scratch for the final image
FROM alpine:3.18
WORKDIR /home/cosmos-indexer

# Label should match your github repo
LABEL org.opencontainers.image.source="https://github.com/defiantlabs/cosmos-indexer"

# Installs all binaries built with go.
COPY --from=build-env /go/bin /bin

# Other binaries we want to keep.
COPY --from=build-env /usr/bin/ldd /bin/ldd
COPY --from=build-env /usr/bin/curl /bin/curl
COPY --from=build-env /usr/bin/jq /bin/jq
COPY --from=build-env /usr/bin/htop /bin/htop
COPY --from=build-env /usr/bin/atop /bin/atop

# Install Libraries
# cosmos-indexer
COPY --from=build-env /usr/lib/libgcc_s.so.1 /lib/
COPY --from=build-env /lib/ld-musl*.so.1* /lib

# jq Libraries
COPY --from=build-env /usr/lib/libonig.so.5 /lib

# curl Libraries
COPY --from=build-env /usr/lib/libcurl.so.4 /lib
COPY --from=build-env /lib/libz.so.1 /lib
COPY --from=build-env /usr/lib/libnghttp2.so.14 /lib
COPY --from=build-env /lib/libssl.so.3 /lib
COPY --from=build-env /lib/libcrypto.so.3 /lib
COPY --from=build-env /usr/lib/libbrotlidec.so.1 /lib
COPY --from=build-env /usr/lib/libbrotlicommon.so.1 /lib

# htop/atop libs
COPY --from=build-env /usr/lib/libncursesw.so.6 /lib

# Install trusted CA certificates
COPY --from=build-env /etc/ssl/cert.pem /etc/ssl/cert.pem

# Copy user from busybox to scratch
COPY --from=busybox /etc/passwd /etc/passwd
COPY --from=busybox --chown=1137:1137 /home/cosmos-indexer /home/cosmos-indexer

# Set environment variables with default values
ENV POSTGRES_HOST="34.48.145.151" \
    POSTGRES_PORT="5432" \
    POSTGRES_DB="postgres" \
    POSTGRES_USER="postgres" \
    POSTGRES_PASSWORD="YSpPEENv" \
    LOG_PRETTY="true" \
    LOG_LEVEL="info" \
    INDEX_TRANSACTIONS="true" \
    INDEX_BLOCK_EVENTS="true" \
    START_BLOCK="1" \
    END_BLOCK="-1" \
    BLOCK_TIMER="10000" \
    WAIT_FOR_CHAIN="true" \
    WAIT_FOR_CHAIN_DELAY="10000" \
    EXIT_WHEN_CAUGHT_UP="true" \
    THROTTLING="6.0" \
    RPC_WORKERS="1" \
    REINDEX="true" \
    REATTEMPT_FAILED_BLOCKS="true" \
    RPC_URL="https://rpc.coinfi.zone" \
    ACCOUNT_PREFIX="coin" \
    CHAIN_ID="sovereign" \
    CHAIN_NAME="CoinFi"

# Create entrypoint script to handle environment variable expansion
RUN echo '#!/bin/sh' > /entrypoint.sh && \
    echo 'cosmos-indexer index \' >> /entrypoint.sh && \
    echo '  --log.pretty=${LOG_PRETTY} \' >> /entrypoint.sh && \
    echo '  --log.level=${LOG_LEVEL} \' >> /entrypoint.sh && \
    echo '  --base.index-transactions=${INDEX_TRANSACTIONS} \' >> /entrypoint.sh && \
    echo '  --base.index-block-events=${INDEX_BLOCK_EVENTS} \' >> /entrypoint.sh && \
    echo '  --base.start-block=${START_BLOCK} \' >> /entrypoint.sh && \
    echo '  --base.end-block=${END_BLOCK} \' >> /entrypoint.sh && \
    echo '  --base.block-timer=${BLOCK_TIMER} \' >> /entrypoint.sh && \
    echo '  --base.wait-for-chain=${WAIT_FOR_CHAIN} \' >> /entrypoint.sh && \
    echo '  --base.wait-for-chain-delay=${WAIT_FOR_CHAIN_DELAY} \' >> /entrypoint.sh && \
    echo '  --base.exit-when-caught-up=${EXIT_WHEN_CAUGHT_UP} \' >> /entrypoint.sh && \
    echo '  --base.throttling=${THROTTLING} \' >> /entrypoint.sh && \
    echo '  --base.rpc-workers=${RPC_WORKERS} \' >> /entrypoint.sh && \
    echo '  --base.reindex=${REINDEX} \' >> /entrypoint.sh && \
    echo '  --base.reattempt-failed-blocks=${REATTEMPT_FAILED_BLOCKS} \' >> /entrypoint.sh && \
    echo '  --probe.rpc=${RPC_URL} \' >> /entrypoint.sh && \
    echo '  --probe.account-prefix=${ACCOUNT_PREFIX} \' >> /entrypoint.sh && \
    echo '  --probe.chain-id=${CHAIN_ID} \' >> /entrypoint.sh && \
    echo '  --probe.chain-name=${CHAIN_NAME} \' >> /entrypoint.sh && \
    echo '  --database.host=${POSTGRES_HOST} \' >> /entrypoint.sh && \
    echo '  --database.database=${POSTGRES_DB} \' >> /entrypoint.sh && \
    echo '  --database.port=${POSTGRES_PORT} \' >> /entrypoint.sh && \
    echo '  --database.user=${POSTGRES_USER} \' >> /entrypoint.sh && \
    echo '  --database.password=${POSTGRES_PASSWORD}' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

# Set home directory and user
WORKDIR /home/cosmos-indexer
USER cosmos-indexer

# Use the shell script as entrypoint
ENTRYPOINT ["/entrypoint.sh"]
