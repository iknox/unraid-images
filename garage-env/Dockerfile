# Thin wrapper that materialises garage.toml from environment variables at
# container start, so operators never have to mount a config file. Also
# embeds the khairul169/garage-webui admin UI, which reads the materialised
# toml directly (see entrypoint.sh; disable with GARAGE_WEBUI=0).
#
# Upstream dxflrs/garage is FROM scratch — no shell. We extract the garage
# binary and repackage on top of alpine (for /bin/sh + envsubst).

# NOTE: upstream release tags carry no 'v' prefix.
ARG WEBUI_VERSION=1.1.0

FROM dxflrs/garage:v2.4.1 AS upstream

FROM alpine:3.24
ARG TARGETARCH
ARG WEBUI_VERSION
RUN apk add --no-cache gettext ca-certificates tzdata \
 && rm -rf /var/cache/apk/* \
 && wget -qO /usr/local/bin/garage-webui \
      "https://github.com/khairul169/garage-webui/releases/download/${WEBUI_VERSION}/garage-webui-v${WEBUI_VERSION}-linux-${TARGETARCH}" \
 && chmod +x /usr/local/bin/garage-webui

COPY --from=upstream /garage /garage
COPY entrypoint.sh /entrypoint.sh
COPY garage.toml.tmpl /garage.toml.tmpl
RUN chmod +x /entrypoint.sh

ENV RUST_BACKTRACE=1
ENV RUST_LOG=garage=info

# S3 API, admin API, web UI
EXPOSE 3900 3903 3909

ENTRYPOINT ["/entrypoint.sh"]
CMD ["server"]
