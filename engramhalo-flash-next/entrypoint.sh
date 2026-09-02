#!/bin/bash
# Baked llama-server launch for EngramHalo.cpp + Qwen3.8-Flash-Next on Strix Halo.
# Intent mirrors Aristo94/EngramHalo.cpp docs/strix-halo README, config B
# (long-context/agent profile), adapted to the flag names of the pinned tree:
# the docs' `--tensor-read-lazy on` is `-lzm/--lazy-mode on` here, and load
# mode is `-lm/--load-mode`. All knobs have defaults; env overrides optional.
set -euo pipefail

MODEL="${MODEL:-/models/Qwen3.8-Flash-Next-UD-IQ4_XS/Qwen3.8-Flash-Next-UD-IQ4_XS-00001-of-00003.gguf}"
MTP="${MTP:-/models/mtp-sidecars/EasiiX-Qwen3.8-Flash-Next-Q8_0.gguf}"
CTX="${CTX:-163840}"
NP="${NP:-1}"
THREADS="${THREADS:-4}"
MODE="${MODE:-ssd}"   # ssd = engram table lazy-read from SSD (~1 GiB resident); ram = -lm none (fastest, <=131k ctx)
CHAT_KWARGS="${CHAT_KWARGS:-$(cat <<'KWARGS'
{"reasoning_effort":"low"}
KWARGS
)}"        # model default is xhigh, which overthinks for agent coding; pass {} to restore
EXTRA_ARGS="${EXTRA_ARGS:-}"

# hipBLASLt path is part of the measured configuration
export ROCBLAS_USE_HIPBLASLT=1

set -- -m "$MODEL" -ngl 999 -fa on -ctk q8_0 -ctv q8_0

if [ "$MODE" = "ram" ]; then
  set -- "$@" -lm none -c "$CTX"
else
  # NOTE: never pass --no-mmap here — it silently disables the lazy-read path
  # that keeps the 27 GiB engram table off the GPU.
  set -- "$@" -lm mmap -lzm on -c "$CTX"
fi

set -- "$@" -b 8192 -ub 2048 -t "$THREADS" --parallel "$NP" --jinja \
  --host 0.0.0.0 --port 8080

if [ -n "$MTP" ] && [ -f "$MTP" ]; then
  # MTP sidecar is validated up to a 164K slot on this branch
  set -- "$@" -md "$MTP" --spec-type draft-mtp,ngram-mod \
    --spec-draft-n-max 4 --spec-draft-p-min 0.75
fi

if [ -n "$CHAT_KWARGS" ]; then
  set -- "$@" --chat-template-kwargs "$CHAT_KWARGS"
fi

exec llama-server "$@" $EXTRA_ARGS
