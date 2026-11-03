# Keep the exact working CUDA/PyTorch stack and /start.sh used by v0.35.0.
# Do not follow the mutable RunPod base tag when updating ComfyUI.
FROM ghcr.io/arrangecompose-code/runpod-comfyui-cu130@sha256:dc14eac173cb3416a722429a59d354149d96cbbcac99287a4074699d9d53f3ae

ARG COMFYUI_VERSION=v0.43.0

USER root

RUN set -eux; \
    rm -rf /tmp/ComfyUI-new; \
    git clone --depth 1 --branch "${COMFYUI_VERSION}" https://github.com/Comfy-Org/ComfyUI.git /tmp/ComfyUI-new; \
    rm -rf /tmp/ComfyUI-new/custom_nodes/*; \
    mkdir -p /tmp/ComfyUI-new/custom_nodes; \
    cp -a /opt/comfyui-baked/custom_nodes/ComfyUI-Manager /tmp/ComfyUI-new/custom_nodes/ComfyUI-Manager; \
    python3.12 -m pip install --no-cache-dir -c /opt/comfyui-runtime-constraints.txt -r /tmp/ComfyUI-new/requirements.txt; \
    rm -rf /opt/comfyui-baked; \
    mv /tmp/ComfyUI-new /opt/comfyui-baked; \
    printf 'COMFYUI_VERSION=%s\nBASE=runpod-comfyui-cuda13.0\n' "${COMFYUI_VERSION}" > /opt/comfyui-baked/.runpod-bundle-version; \
    python3.12 -c "import comfy_kitchen; assert hasattr(comfy_kitchen, 'int8_attention_is_available')"; \
    grep -q "class ModelAttentionBackend" /opt/comfyui-baked/comfy_extras/nodes_model_advanced.py; \
    echo 'a265753f3bf3f54b38a7badabe1656da414a5d50fa9abb4efe2fd2542e309084  /start.sh' | sha256sum -c -

# Exercise the installed image before it can be published. No GPU/model needed.
COPY scripts/verify-image.py /tmp/verify-image.py
RUN python3.12 /tmp/verify-image.py && rm /tmp/verify-image.py
