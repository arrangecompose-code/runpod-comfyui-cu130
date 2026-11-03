# RunPod ComfyUI CUDA 13 / ComfyUI v0.43.0

- Base: the original working `v0.35.0` image, pinned to its Linux/amd64 digest
- ComfyUI: `v0.43.0` (stable release, source commit `426f5eea52a7ece1dd599fff4cb6cd1f352ddd24`)
- CUDA 13.0 / PyTorch 2.10.0+cu130 / Python 3.12 are retained
- No models bundled
- ModelAttentionBackend is verified during build
- RunPod workspace path remains `/workspace/runpod-slim/ComfyUI`
- Original `/start.sh` and bundled ComfyUI-Manager are retained. User models,
  workflows, custom nodes, virtual environment and `comfyui_args.txt` remain on
  the existing workspace, using the original upgrade/preservation logic.
- The Default template's existing start command is retained byte for byte:
  parallel RAM model copy, pip-warmup bypass, Jupyter suppression, and the
  conditional baked-code startup switch are not replaced.
- The image build starts a CPU-only ComfyUI server and checks H3 node registration
  and model discovery through both the workspace and the extra RAM-model path.
  This does not verify GPU model loading, generation, or user-installed nodes.
- Published image: `ghcr.io/arrangecompose-code/runpod-comfyui-cu130:v0.43.0`.
  The old `v0.35.0` tag is not overwritten.
