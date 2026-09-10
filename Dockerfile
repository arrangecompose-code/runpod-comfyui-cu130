FROM runpod/comfyui:cuda13.0

ARG COMFYUI_VERSION=v0.35.0

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
    grep -q "class ModelAttentionBackend" /opt/comfyui-baked/comfy_extras/nodes_model_advanced.py
