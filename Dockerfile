# Reuse the exact 15 official layers already used by v0.35.0.
# Pin the official base directly, without retaining the obsolete 207 MiB
# v0.35.0 application layer underneath the replacement application.
FROM runpod/comfyui@sha256:bad26aad809a442a0d2674827d58c03f95686d0ea6d0d0e0cbebacd787488797

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
