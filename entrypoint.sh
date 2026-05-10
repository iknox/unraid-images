#!/bin/sh
# Materialise /etc/garage.toml from env vars, auto-generating secrets where
# not provided. Then hand off to the upstream garage binary.

set -eu

# --- Sensible defaults for every non-secret key ---------------------------
: "${GARAGE_METADATA_DIR:=/var/lib/garage/meta}"
: "${GARAGE_DATA_DIR:=/var/lib/garage/data}"
: "${GARAGE_DB_ENGINE:=sqlite}"
: "${GARAGE_REPLICATION_FACTOR:=1}"
: "${GARAGE_RPC_BIND_ADDR:=[::]:3901}"
: "${GARAGE_RPC_PUBLIC_ADDR:=127.0.0.1:3901}"
: "${GARAGE_S3_API_BIND_ADDR:=[::]:3900}"
: "${GARAGE_S3_REGION:=garage}"
: "${GARAGE_S3_ROOT_DOMAIN:=.s3.garage.local}"
: "${GARAGE_ADMIN_BIND_ADDR:=[::]:3903}"

# --- Auto-generate secrets on first boot; persist in metadata dir ---------
# We stash them alongside metadata so they survive container recreation.
mkdir -p "$GARAGE_METADATA_DIR"
SECRETS_FILE="$GARAGE_METADATA_DIR/.garage-env-secrets"

if [ -f "$SECRETS_FILE" ]; then
    # shellcheck disable=SC1090
    . "$SECRETS_FILE"
fi

gen_if_unset() {
    eval "val=\${$1:-}"
    if [ -z "$val" ]; then
        new=$(tr -dc 'a-f0-9' </dev/urandom | head -c 64)
        eval "$1='$new'"
        echo "[entrypoint] generated $1"
        echo "$1='$new'" >> "$SECRETS_FILE"
    fi
}
gen_if_unset GARAGE_RPC_SECRET
gen_if_unset GARAGE_ADMIN_TOKEN
gen_if_unset GARAGE_METRICS_TOKEN

export GARAGE_METADATA_DIR GARAGE_DATA_DIR GARAGE_DB_ENGINE \
       GARAGE_REPLICATION_FACTOR GARAGE_RPC_BIND_ADDR GARAGE_RPC_PUBLIC_ADDR \
       GARAGE_RPC_SECRET GARAGE_S3_API_BIND_ADDR GARAGE_S3_REGION \
       GARAGE_S3_ROOT_DOMAIN GARAGE_ADMIN_BIND_ADDR GARAGE_ADMIN_TOKEN \
       GARAGE_METRICS_TOKEN

# Render template. envsubst is installed in the image via gettext.
envsubst < /garage.toml.tmpl > /etc/garage.toml

echo "[entrypoint] wrote /etc/garage.toml"

# --- Hand off to garage ---------------------------------------------------
exec /garage "$@"
