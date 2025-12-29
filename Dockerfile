ARG BBKCLI_VERSION=1.0

FROM alpine:3.23 AS bbkcli

# See: http://www.bredbandskollen.se/bredbandskollen-cli/
ARG BBKCLI_VERSION
ARG TARGETPLATFORM
RUN case ${TARGETPLATFORM} in \
         "linux/amd64")  BBKCLI_ARCH=amd64  ;; \
         "linux/arm64")  BBKCLI_ARCH=aarch64  ;; \
         "linux/arm/v7") BBKCLI_ARCH=armhf  ;; \
         "linux/386")    BBKCLI_ARCH=i386   ;; \
    esac \
    && echo "Fetch: https://frontend.bredbandskollen.se/download/bbk_cli_linux_${BBKCLI_ARCH:-amd64}-${BBKCLI_VERSION}" \
    && wget -q https://frontend.bredbandskollen.se/download/bbk_cli_linux_${BBKCLI_ARCH:-amd64}-${BBKCLI_VERSION} -O /bbk_cli

COPY ["./LICENSE", "/bbk_cli_license"]



# Main image
FROM alpine:3.23

RUN apk add --update --no-cache gcompat libstdc++ tzdata \
    && ln -sf /usr/local/bin/bbk_cli /usr/local/bin/bbk

COPY --from=bbkcli --chmod=0775 ["/bbk_cli", "/usr/local/bin/"]
COPY --from=bbkcli --chmod=0755 ["/bbk_cli_license", "/usr/local/src/bbk/LICENSE.txt"]

ARG BBKCLI_VERSION
ARG TARGETPLATFORM
ENV BBKCLI_VERSION=${BBKCLI_VERSION}
ENV PLATFORM_ARCH=${TARGETPLATFORM}
ENV TZ=Europe/Stockholm

LABEL org.opencontainers.image.title="Bredbandskollen CLI" \
      org.opencontainers.image.description="Bredbandskollen CLI, a bandwidth measurement tool" \
      org.opencontainers.image.authors="The Swedish Internet Foundation <support@bredbandskollen.se>" \
      org.opencontainers.image.vendor="The Swedish Internet Foundation" \
      org.opencontainers.image.url="https://www.bredbandskollen.se/om/mer-om-bbk/bredbandskollen-cli/" \
      org.opencontainers.image.licenses="MIT"

ENTRYPOINT [ "/usr/local/bin/bbk_cli" ]
