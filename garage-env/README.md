# garage-env

Thin wrapper around [Garage](https://garagehq.deuxfleurs.fr/) that reads every configuration value from environment variables instead of a TOML file.

Upstream Garage requires a `garage.toml` and only supports env-var overrides for three secret values. This image renders a full `garage.toml` from env at startup and auto-generates the three secrets on first boot (persisted to `$GARAGE_METADATA_DIR/.garage-env-secrets` so they survive container recreation).

The image also embeds the [khairul169/garage-webui](https://github.com/khairul169/garage-webui) admin UI (bucket/key/cluster management plus an object browser). It reads the materialised `garage.toml` in-container, so the admin token never leaves the container. On by default; disable with `GARAGE_WEBUI=0`.

Built for the [iknox/unraid-templates](https://github.com/iknox/unraid-templates) stack, where users configure every container via the Unraid template form.

## Environment variables

All optional; defaults in parentheses. Point them at whatever suits your deployment.

| Variable | Default | Notes |
|---|---|---|
| `GARAGE_METADATA_DIR` | `/var/lib/garage/meta` | Mount a persistent volume here |
| `GARAGE_DATA_DIR` | `/var/lib/garage/data` | Mount a persistent volume here |
| `GARAGE_DB_ENGINE` | `sqlite` | `sqlite` or `lmdb` |
| `GARAGE_REPLICATION_FACTOR` | `1` | 1 = single-node |
| `GARAGE_RPC_BIND_ADDR` | `[::]:3901` | |
| `GARAGE_RPC_PUBLIC_ADDR` | `127.0.0.1:3901` | |
| `GARAGE_RPC_SECRET` | auto-generated | 64-char hex |
| `GARAGE_S3_API_BIND_ADDR` | `[::]:3900` | |
| `GARAGE_S3_REGION` | `garage` | Must match your S3 client's region |
| `GARAGE_S3_ROOT_DOMAIN` | `.s3.garage.local` | |
| `GARAGE_ADMIN_BIND_ADDR` | `[::]:3903` | |
| `GARAGE_WEB_ENDPOINT_BIND_ADDR` | `[::]:3902` | Static-website hosting endpoint |
| `GARAGE_ADMIN_TOKEN` | auto-generated | |
| `GARAGE_METRICS_TOKEN` | auto-generated | |
| `GARAGE_WEBUI` | `1` | Set to `0` to disable the embedded web UI |
| `GARAGE_WEBUI_PORT` | `3909` | Web UI listen port |
| `AUTH_USER_PASS` | *(unset)* | `user:$2y$10$<bcrypt>` to require web UI login |

### Web UI security note

Without `AUTH_USER_PASS` the web UI is unauthenticated, and its `/api/config`
endpoint echoes the rendered toml — including the master admin, metrics and
RPC secrets. Fine on a trusted LAN; **never expose port 3909 (or proxy it)
without setting `AUTH_USER_PASS`**, and don't put it behind a public tunnel.

## Quick start

```bash
docker run -d --name garage \
  -p 3900:3900 -p 3903:3903 \
  -v /path/to/meta:/var/lib/garage/meta \
  -v /path/to/data:/var/lib/garage/data \
  ghcr.io/iknox/garage-env:latest
```

First boot: inspect the generated rendered config via `docker exec garage cat /etc/garage.toml`, or view the persisted secrets via `cat /path/to/meta/.garage-env-secrets`.

## License

This repo: MIT. Upstream Garage is AGPL-3.0 — the image just re-bundles it unmodified. Source: https://git.deuxfleurs.fr/Deuxfleurs/garage
