#!/usr/bin/env bash
# Download Kokoro model + voices on first run if /data is empty, then hand off
# to the Wyoming server with whatever argv the container was started with.

set -euo pipefail

DATA_DIR="${DATA_DIR:-/data}"
BASE_URL="https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0"
MODEL_VARIANT="${KOKORO_MODEL:-fp32}"   # fp32 (CPU), int8, fp16 (GPU only)

mkdir -p "$DATA_DIR"

case "$MODEL_VARIANT" in
    fp32) MODEL_FILE="kokoro-v1.0.onnx" ;;
    int8) MODEL_FILE="kokoro-v1.0.int8.onnx" ;;
    fp16) MODEL_FILE="kokoro-v1.0.fp16.onnx" ;;
    *)
        echo "[entrypoint] unknown KOKORO_MODEL='$MODEL_VARIANT' — expected fp32|int8|fp16" >&2
        exit 1
        ;;
esac

if [ ! -s "$DATA_DIR/voices-v1.0.bin" ]; then
    echo "[entrypoint] fetching voices-v1.0.bin (~27 MB)..."
    wget -q -O "$DATA_DIR/voices-v1.0.bin" "$BASE_URL/voices-v1.0.bin"
fi

if [ ! -s "$DATA_DIR/$MODEL_FILE" ]; then
    echo "[entrypoint] fetching $MODEL_FILE..."
    wget -q -O "$DATA_DIR/$MODEL_FILE" "$BASE_URL/$MODEL_FILE"
fi

echo "[entrypoint] data dir contents:"
ls -la "$DATA_DIR"

echo "[entrypoint] launching: python -m wyoming_kokoro $*"
exec python wyoming_kokoro.py "$@"
