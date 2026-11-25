# PrismML llama.cpp (Vulkan) - Bonsai 2.5 27B server
#
# Overlays the PrismML fork prebuilt Vulkan binaries onto the official
# ggml-org llama.cpp Vulkan server base. Stock llama.cpp cannot load
# Bonsai PTQ1_0/PQ2_0, and older stock builds load Q2_0 as garbage.
#
# Build:
#   docker build -t bonsai-prism-vulkan:local \
#     --build-arg PRISM_TAG=prism-b12178-03ec600 \
#     -f docker/Dockerfile docker
#
# Run (example):
#   docker run --rm -it \
#     --device /dev/dri --group-add video \
#     -p 8081:8080 \
#     -v /mnt/user/models:/models \
#     bonsai-prism-vulkan:local \
#     -m /models/bonsai-2.5-27b/Ternary-Bonsai-2.5-27B-PTQ1_0-mtp.gguf \
#     --host 0.0.0.0 --port 8080 \
#     -ngl 99 -fa on -c 8192 -np 1 \
#     -ctk q4_0 -ctv q4_0 \
#     --jinja --min-p 0 \
#     --temp 0.7 --top-p 0.8 --top-k 20 \
#     --presence-penalty 1.5 --repeat-penalty 1.0 \
#     --reasoning-budget 0

FROM ghcr.io/ggml-org/llama.cpp:server-vulkan

ARG PRISM_TAG=prism-b12178-03ec600
ARG PRISM_BUILD=ubuntu-vulkan-x64

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Overlay PrismML prebuilt binaries + libs onto /app. The prebuilt executables
# carry RUNPATH=$ORIGIN, so sibling .so files resolve next to the binary.
RUN set -eux; \
    cd /tmp; \
    curl -fsSL -o prism.tar.gz \
      "https://github.com/PrismML-Eng/llama.cpp/releases/download/${PRISM_TAG}/llama-${PRISM_TAG}-bin-${PRISM_BUILD}.tar.gz"; \
    tar -xzf prism.tar.gz; \
    cp -rf "/tmp/llama-${PRISM_TAG}/"* /app/; \
    rm -rf "/tmp/llama-${PRISM_TAG}" prism.tar.gz; \
    chmod +x /app/llama-server /app/llama-cli /app/llama-bench || true

ENV LD_LIBRARY_PATH=/app

# Default: run start.sh (editable defaults for Bonsai 2.5 27B PTQ1_0-mtp).
# Unraid template can override with --entrypoint /bin/bash and seed /config/start.sh.
EXPOSE 8080
ENTRYPOINT ["/bin/bash", "/app/start.sh"]
CMD []
