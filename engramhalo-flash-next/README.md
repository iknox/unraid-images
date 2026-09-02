# engramhalo-flash-next

Qwen3.8-Flash-Next on AMD Strix Halo (gfx1151) via [Aristo94/EngramHalo.cpp](https://github.com/Aristo94/EngramHalo.cpp) — a llama.cpp fork with RDNA 3.5 kernel patches, true QSA sparse-attention gather, a working MTP draft head, and the model's 27 GiB engram (n-gram) table kept **on SSD** (~1 GiB resident instead of pinned in memory).

Measured upstream vs the stock qwen4exp branch: code decode 24.4 → **39.3 t/s**, prefill at 131K depth roughly **doubled** (91 → 192 t/s), decode at depth up ~50% with MTP.

## What's baked in

- ROCm 7.14 (the stack the fork's kernel patches were measured on — deliberately not 10.0)
- Upstream's `#25992` host-buffer workaround (multi-slot correctness) and per-buffer-mmap loader patch, vendored at pinned commit
- A tuned `entrypoint.sh` (long-context/agent profile): `-fa on`, q8_0 KV, `-lm mmap --tensor-read-lazy on`, `-b 8192 -ub 2048 -t 4`, MTP + ngram-mod speculation with the [EasiiX sidecar](https://huggingface.co/EasiiX/Qwen3.8-Flash-Next-MTP-Strix-Halo-GGUF)

The Unraid container mounts **only** `/models` — no config files, no env vars required. Optional env overrides: `MODEL`, `MTP` (empty disables speculation), `CTX` (default 163840, the MTP-validated limit; use 262144 with `MTP=""`), `NP` (slots), `THREADS`, `MODE=ssd|ram` (ram = fastest short-context, ≤131k), `EXTRA_ARGS`.

## Host prerequisites (Unraid syslinux append line)

```
amdgpu.gttsize=117760 amdgpu.no_system_mem_limit=1 ttm.pages_limit=24576000
```

and BIOS UMA Frame Buffer Size at 512M (minimum) — the engram SSD-streaming and GTT allocations depend on it.

## Notes

- Never run with `--no-mmap`: it silently disables the lazy-read path that keeps the engram table off the GPU.
- Multi-slot (`NP>1`) + speculative decoding is not validated on this arch; the entrypoint drops nothing — if you raise NP, consider clearing `MTP`.
