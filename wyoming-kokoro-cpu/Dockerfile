# CPU-only Wyoming Kokoro TTS image.
# Wraps chiabre/wyoming-kokoro (1.0.0) in a reproducible container.
#
# Dependencies are managed via uv + uv.lock for reproducible installs.
# Bumping the python tag without updating the lock will fail at `uv sync`
# rather than mid-pip-install, which is exactly what we want.

FROM python:3.12-slim AS base

# espeak-ng is Kokoro's phonemizer. wget for first-run model download.
# uv is bundled in via its official static binary — no curl/network needed
# at runtime, and no python toolchain pollution.
RUN apt-get update \
 && apt-get install --no-install-recommends -y espeak-ng wget ca-certificates \
 && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:0.11.16 /uv /uvx /usr/local/bin/

WORKDIR /app

# Install Python deps from the lockfile first so they cache across code changes.
# --frozen: refuse to update the lock; CI must commit lock updates explicitly.
# --no-dev: skip dev-only deps (we have none, but kept for hygiene).
# UV_PROJECT_ENVIRONMENT points at /usr so packages land system-site rather
# than in a .venv we'd then have to activate at runtime.
ENV UV_PROJECT_ENVIRONMENT=/usr/local
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project

# Vendored chiabre runtime — single python file, kept in-repo so upstream
# changes don't silently shift under us and builds stay reproducible offline.
COPY wyoming_kokoro.py .
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

# /data is where kokoro models + voices live. Declare as volume so users
# don't accidentally bake models into the image.
VOLUME ["/data"]

EXPOSE 10200/tcp

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["--uri", "tcp://0.0.0.0:10200", "--data-dir", "/data", "--voice", "af_heart", "--cpu"]
