# bonsai-prism-vulkan

PrismML llama.cpp (Vulkan) image for **Ternary Bonsai 2.5 27B** on AMD Strix Halo (`gfx1151`).

- Base: `ghcr.io/ggml-org/llama.cpp:server-vulkan`
- Overlay: [PrismML-Eng/llama.cpp](https://github.com/PrismML-Eng/llama.cpp) prebuilt Vulkan binary (`ubuntu-vulkan-x64`)
- Default model: `Ternary-Bonsai-2.5-27B-PTQ1_0-mtp.gguf` (~6 GB)
- API: OpenAI-compatible llama-server on `:8080` (`/v1/chat/completions`)

## Why

Stock llama.cpp cannot load Bonsai `PTQ1_0/PQ2_0` packings; older stock builds may load `Q2_0` as garbage. This image overlays the PrismML fork binaries onto the official Vulkan runtime.

## Runtime config

`/app/start.sh` is baked into the image and also seeded to `/config/start.sh` by the Unraid template on first boot. Edit `/config/start.sh` and restart to change model/context/speculative/extra args.

Key defaults:

| Var | Default | Notes |
|---|---:|---|
| `MODEL` | `/models/bonsai-2.5-27b/Ternary-Bonsai-2.5-27B-PTQ1_0-mtp.gguf` | PTQ1_0-mtp |
| `CTX` | `8192` | footprint/concurrency |
| `PARALLEL` | `1` | avoid extra slot memory |
| `CACHE_TYPE_K/V` | `q4_0` | KV footprint |
| `SPEC_TYPE` | `draft-mtp` | embedded MTP head |
| `SPEC_DRAFT_N_MAX` | `3` | Bonsai preset |
| `REASONING_BUDGET` | `0` | 0=fast/no thinking, -1=unrestricted, N>0=token budget |
| `AUTO_DOWNLOAD` | `1` | download model if missing |

## Build

```bash
docker build -t ghcr.io/iknox/bonsai-prism-vulkan:local \
  --build-arg PRISM_TAG=prism-b12178-03ec600 \
  bonsai-prism-vulkan
```

The GitHub Actions workflow in this repo builds/pushes on changes to `bonsai-prism-vulkan/**`.
