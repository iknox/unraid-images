# Thin wrapper that materialises garage.toml from environment variables at
# container start, so operators never have to mount a config file.
#
# Upstream dxflrs/garage is FROM scratch — no shell. We extract the garage
# binary and repackage on top of alpine (for /bin/sh + envsubst).

FROM dxflrs/garage:v2.3.0 AS upstream

FROM alpine:3.23
RUN apk add --no-cache gettext ca-certificates tzdata \
 && rm -rf /var/cache/apk/*

COPY --from=upstream /garage /garage
COPY entrypoint.sh /entrypoint.sh
COPY garage.toml.tmpl /garage.toml.tmpl
RUN chmod +x /entrypoint.sh

ENV RUST_BACKTRACE=1
ENV RUST_LOG=garage=info

ENTRYPOINT ["/entrypoint.sh"]
CMD ["server"]
