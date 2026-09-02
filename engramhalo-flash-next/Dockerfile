# EngramHalo.cpp for Qwen3.8-Flash-Next on AMD Strix Halo (gfx1151).
#
# Upstream recipe: Aristo94/EngramHalo.cpp docs/strix-halo/Dockerfile.rocm-7.14
# (ROCm 7.14 is the stack the branch's kernel patches were measured on — do not
# bump it casually). The two vendored patches are copied verbatim from
# upstream's docs/strix-halo/ at pinned commit ENGRAMHALO_COMMIT.
#
# On top of upstream we bake in a tuned llama-server entrypoint (config B,
# long-context/agent profile: SSD-backed engram table + MTP sidecar), so the
# Unraid container needs no config mounts or env vars — only /models.

# ---- build stage -----------------------------------------------------------
FROM registry.fedoraproject.org/fedora:44 AS builder

RUN <<'EOF'
tee /etc/yum.repos.d/rocm.repo <<REPO
[rocm]
name=ROCm 7.14.0
baseurl=https://repo.amd.com/rocm/packages-multi-arch/rhel10/x86_64
enabled=1
priority=50
gpgcheck=1
gpgkey=https://repo.amd.com/rocm/packages-multi-arch/gpg/rocm.gpg
REPO
EOF

RUN dnf -y --nodocs --setopt=install_weak_deps=False \
  install \
  make gcc gcc-c++ cmake libcurl-devel ninja-build rdma-core-devel \
  amdrocm-core-devel7.14-gfx1151 \
  git-core sudo rsync patch \
  && dnf clean all && rm -rf /var/cache/dnf/*

ENV ROCM_PATH=/opt/rocm \
  HIP_PATH=/opt/rocm \
  PATH=/opt/rocm/bin:/opt/rocm/core/bin:/opt/rocm/core/lib/llvm/bin:$PATH \
  LD_LIBRARY_PATH=/opt/rocm/core/lib/rocm_sysdeps/lib:/opt/rocm/core/lib

WORKDIR /opt/llama.cpp
ARG ENGRAMHALO_REPO=https://github.com/Aristo94/EngramHalo.cpp.git
ARG ENGRAMHALO_COMMIT=1b560afacd0a5ed5e43b8586d0c6136a3c282e03
RUN git clone --recursive https://github.com/Aristo94/EngramHalo.cpp.git . \
  && git checkout ${ENGRAMHALO_COMMIT} \
  && git submodule update --recursive

# iGPU host-buffer workaround for ggml-org/llama.cpp#25992 (upstream PR #25863).
# Correctness fix for multi-slot response mix-up on integrated GPUs.
COPY llama-cpp-25992-rocm-host-buffer.patch /tmp/
# Per-buffer mmap / async-upload loader patch (measured loader config).
COPY llama-cpp-qwen38-per-buffer-mmap.patch /tmp/
RUN if git apply --check /tmp/llama-cpp-25992-rocm-host-buffer.patch; then \
      git apply /tmp/llama-cpp-25992-rocm-host-buffer.patch; \
    elif git apply --reverse --check /tmp/llama-cpp-25992-rocm-host-buffer.patch; then \
      echo "#25992 workaround already present upstream"; \
    else \
      echo "WARNING: #25992 workaround no longer applies; multi-slot serving may return wrong responses"; \
    fi \
  && if git apply --check /tmp/llama-cpp-qwen38-per-buffer-mmap.patch; then \
      git apply /tmp/llama-cpp-qwen38-per-buffer-mmap.patch; \
    else \
      echo "per-buffer mmap loader patch skipped as obsolete"; \
    fi \
  && cmake -S . -B build \
  -DGGML_HIP=ON \
  -DAMDGPU_TARGETS=gfx1151 \
  -DCMAKE_BUILD_TYPE=Release \
  -DGGML_RPC=ON \
  -DROCM_PATH=/opt/rocm \
  -DHIP_PLATFORM=amd \
  && cmake --build build --config Release -- -j$(nproc) \
  && cmake --install build --config Release

RUN mkdir -p /usr/local/lib64 \
  && find /opt/llama.cpp/build -type f -name 'lib*.so*' -exec cp {} /usr/local/lib64/ \; \
  && ldconfig

# ---- runtime stage ---------------------------------------------------------
FROM registry.fedoraproject.org/fedora-minimal:44

RUN <<'EOF'
tee /etc/yum.repos.d/rocm.repo <<REPO
[rocm]
name=ROCm 7.14.0
baseurl=https://repo.amd.com/rocm/packages-multi-arch/rhel10/x86_64
enabled=1
priority=50
gpgcheck=1
gpgkey=https://repo.amd.com/rocm/packages-multi-arch/gpg/rocm.gpg
REPO
EOF

RUN microdnf -y --nodocs --setopt=install_weak_deps=0 \
  install \
  bash ca-certificates libatomic libstdc++ libgcc libgomp libibverbs sudo \
  amdrocm-runtime7.14 amdrocm-blas7.14-gfx1151 \
  radeontop procps-ng \
  && microdnf clean all && rm -rf /var/cache/dnf/* \
  && ln -s core-7.14 /opt/rocm/core \
  && ln -s core-7.14/bin /opt/rocm/bin \
  && ln -s core-7.14/include /opt/rocm/include \
  && ln -s core-7.14/lib /opt/rocm/lib \
  && ln -s core-7.14/libexec /opt/rocm/libexec \
  && ln -s core-7.14/lib/llvm /opt/rocm/llvm \
  && ln -s core-7.14/share /opt/rocm/share \
  && ln -s core-7.14/lib/llvm/amdgcn /opt/rocm/amdgcn

ENV ROCM_PATH=/opt/rocm \
  HIP_PATH=/opt/rocm \
  PATH=/opt/rocm/bin:/opt/rocm/core/bin:/opt/rocm/core/lib/llvm/bin:$PATH \
  LD_LIBRARY_PATH=/opt/rocm/core/lib/rocm_sysdeps/lib:/opt/rocm/core/lib

COPY --from=builder /usr/local/ /usr/local/
RUN echo "/usr/local/lib" > /etc/ld.so.conf.d/local.conf \
  && echo "/usr/local/lib64" >> /etc/ld.so.conf.d/local.conf \
  && echo "/opt/rocm/core/lib" > /etc/ld.so.conf.d/rocm.conf \
  && echo "/opt/rocm/core/lib/rocm_sysdeps/lib" >> /etc/ld.so.conf.d/rocm.conf \
  && ldconfig \
  && find /usr/local/lib /usr/local/lib64 -maxdepth 1 -type f -name 'libllama*.so*' \
     -exec cp -n {} /usr/lib64/ \; \
  && ldconfig

# Baked server config — tuned per docs/strix-halo README config B (long-context
# agent profile). All values have in-image defaults; env overrides exist only
# for operators who want them, nothing is required from the container runtime.
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV MODEL=/models/Qwen3.8-Flash-Next-UD-IQ4_XS/Qwen3.8-Flash-Next-UD-IQ4_XS-00001-of-00003.gguf \
    MTP=/models/mtp-sidecars/EasiiX-Qwen3.8-Flash-Next-Q8_0.gguf \
    CTX=163840 \
    NP=1 \
    THREADS=4 \
    MODE=ssd \
    EXTRA_ARGS=

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
