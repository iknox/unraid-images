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

# Garage refuses to load secrets from a world-readable config file, and
# `docker exec /garage` can't see the entrypoint's runtime env — without
# this, CLI subcommands inside the container fail with "wrong length"
# because they can neither read the secret from config nor env.
chmod 600 /etc/garage.toml

echo "[entrypoint] wrote /etc/garage.toml (mode 600)"

# --- Auto-bootstrap single-node layout on first boot ----------------------
# Garage v2 requires an explicit cluster layout before any bucket ops.
# Detect first-run by the presence of a marker file in metadata dir;
# after that, the layout is persisted in Garage's metadata so re-running
# is harmless but unnecessary.
LAYOUT_MARKER="$GARAGE_METADATA_DIR/.garage-env-layout-applied"

# Fork a background helper that waits for garage to come up, then assigns
# + applies the layout once. It exits cleanly whether successful or if the
# marker already exists.
(
    if [ -f "$LAYOUT_MARKER" ]; then
        exit 0
    fi
    # Wait up to 30s for garage RPC to be reachable.
    for i in $(seq 1 30); do
        if /garage status >/dev/null 2>&1; then
            break
        fi
        sleep 1
    done
    if ! /garage status >/dev/null 2>&1; then
        echo "[entrypoint] garage didn't become ready — skipping layout auto-assign" >&2
        exit 0
    fi
    # If a layout already exists (e.g. container recreated with same volume),
    # skip. Otherwise stage + apply version 1.
    if /garage layout show 2>/dev/null | grep -q "No nodes currently have a role"; then
        NODE_ID=$(/garage node id -q 2>/dev/null | cut -d'@' -f1)
        if [ -n "$NODE_ID" ]; then
            echo "[entrypoint] auto-assigning single-node layout to $NODE_ID"
            /garage layout assign -z dc1 -c 1G "$NODE_ID" >/dev/null 2>&1 || true
            /garage layout apply --version 1 >/dev/null 2>&1 || true
        fi
    fi
    touch "$LAYOUT_MARKER"
) &

# --- Hand off to garage ---------------------------------------------------
exec /garage "$@"
