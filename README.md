# wyoming-kokoro-cpu

CPU-only Docker image for [chiabre/wyoming-kokoro](https://github.com/chiabre/wyoming-kokoro) — a Wyoming-protocol wrapper around Kokoro-ONNX TTS, consumable by Home Assistant's Voice Assist.

Upstream ships source only; this repo packages it as a reproducible image.

## Quick start

```bash
docker run -d \
  --name wyoming-kokoro \
  -p 10200:10200 \
  -v /path/to/data:/data \
  -e KOKORO_MODEL=fp32 \
  ghcr.io/iknox/wyoming-kokoro-cpu:latest
```

Home Assistant → Settings → Devices & services → Add integration → Wyoming Protocol → host `<your-host>`, port `10200`.

## Environment variables

- `KOKORO_MODEL` — `fp32` (CPU, default), `int8` (edge/low-power), or `fp16` (NVIDIA GPU only; won't work in CPU container).

## Command-line arguments

Anything passed after the image name gets forwarded to the upstream `wyoming_kokoro.py`. Notable args:

- `--uri tcp://0.0.0.0:10200` — listen address (default baked in).
- `--voice af_heart` — default voice. See [chiabre's README](https://github.com/chiabre/wyoming-kokoro#-voices) for the full catalog.
- `--speed 1.0` — playback speed multiplier.

## First-run

Model + voice files (~80 MB for fp32) download on first boot into `/data`. Subsequent starts are instant.

## Building

```bash
docker build -t ghcr.io/iknox/wyoming-kokoro-cpu:latest .
```

## Upstream

- Runtime: https://github.com/chiabre/wyoming-kokoro (MIT license, 1.0.0)
- Model files: https://github.com/thewh1teagle/kokoro-onnx (Apache-2.0)
