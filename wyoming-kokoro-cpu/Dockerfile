# CPU-only Wyoming Kokoro TTS image.
# Wraps chiabre/wyoming-kokoro (1.0.0) in a reproducible container.

FROM python:3.14-slim AS base

# espeak-ng is Kokoro's phonemizer. wget for first-run model download.
RUN apt-get update \
 && apt-get install --no-install-recommends -y espeak-ng wget ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python deps first so they cache across code changes.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Pull chiabre's runtime. We keep this vendored in our repo (a single python
# file) rather than cloning at build time, so upstream changes don't silently
# shift under us and image builds stay reproducible offline.
COPY wyoming_kokoro.py .
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

# /data is where kokoro models + voices live. Declare as volume so users
# don't accidentally bake models into the image.
VOLUME ["/data"]

EXPOSE 10200/tcp

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["--uri", "tcp://0.0.0.0:10200", "--data-dir", "/data", "--voice", "af_heart", "--cpu"]
