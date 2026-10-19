# Thin wrapper that materialises garage.toml from environment variables at
# container start, so operators never have to mount a config file. Also
# embeds the khairul169/garage-webui admin UI, which reads the materialised
# toml directly (see entrypoint.sh; disable with GARAGE_WEBUI=0).
#
# Upstream dxflrs/garage is FROM scratch — no shell. We extract the garage
# binary and repackage on top of alpine (for /bin/sh + envsubst).

# NOTE: take the webui binary from the upstream Docker image, NOT the GitHub
# release assets — the release builds are glibc-dynamic and fail to exec on
# alpine ("Error relocating …"). The image ships a static build, multi-arch.
ARG WEBUI_VERSION=1.1.0

FROM dxflrs/garage:v2.4.1 AS upstream
FROM khairul169/garage-webui:${WEBUI_VERSION} AS webui

FROM alpine:3.24
RUN apk add --no-cache gettext ca-certificates tzdata \
 && rm -rf /var/cache/apk/*

COPY --from=upstream /garage /garage
COPY --from=webui /bin/main /usr/local/bin/garage-webui
COPY entrypoint.sh /entrypoint.sh
COPY garage.toml.tmpl /garage.toml.tmpl
RUN chmod +x /entrypoint.sh

ENV RUST_BACKTRACE=1
ENV RUST_LOG=garage=info

# S3 API, admin API, web UI
EXPOSE 3900 3903 3909

ENTRYPOINT ["/entrypoint.sh"]
CMD ["server"]
