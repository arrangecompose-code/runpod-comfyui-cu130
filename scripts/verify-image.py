"""Verify core startup, H3 nodes and the existing baked-code/RAM-model paths."""
import hashlib
import importlib.metadata
import json
import pathlib
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request

import torch

assert torch.__version__ == '2.10.0+cu130', torch.__version__
assert torch.version.cuda == '13.0', torch.version.cuda
for package, expected in {
    'torchvision': '0.25.0+cu130',
    'torchaudio': '2.10.0+cu130',
    'comfyui-frontend-package': '1.57.4',
    'comfy-kitchen': '0.2.40',
    'comfy-aimdo': '0.6.0',
}.items():
    assert importlib.metadata.version(package) == expected, package

start = pathlib.Path('/start.sh').read_bytes()
assert hashlib.sha256(start).hexdigest() == 'a265753f3bf3f54b38a7badabe1656da414a5d50fa9abb4efe2fd2542e309084'
assert b'python main.py $FIXED_ARGS &' in start
assert pathlib.Path('/opt/comfyui-baked/custom_nodes/ComfyUI-Manager/prestartup_script.py').is_file()
subprocess.run(['bash', '-n', '/start.sh'], check=True)

required_nodes = {
    'UNETLoader', 'CLIPLoader', 'VAELoader', 'KSampler',
    'ModelAttentionBackend', 'EmptyMiniMaxH3LatentAV',
    'MiniMaxH3ImageToVideo', 'MiniMaxH3ReferenceToVideo',
    'MiniMaxH3AddGuide', 'MiniMaxH3SigmaShift',
}

with tempfile.TemporaryDirectory(prefix='h3-image-check-') as tmp:
    root = pathlib.Path(tmp)
    base = root / 'workspace'
    ram = root / 'ram'
    (base / 'user').mkdir(parents=True)
    (base / 'models/diffusion_models').mkdir(parents=True)
    (ram / 'diffusion_models').mkdir(parents=True)
    (ram / 'diffusion_models/h3-ram-path-check.safetensors').touch()
    (base / 'models/diffusion_models/h3-workspace-path-check.safetensors').touch()
    yaml = root / 'h3_ram.yaml'
    yaml.write_text(f'h3ram:\n  base_path: {ram}\n  is_default: true\n  diffusion_models: diffusion_models\n')
    log = root / 'server.log'
    with log.open('w') as output:
        process = subprocess.Popen([
            sys.executable, '/opt/comfyui-baked/main.py',
            '--cpu', '--listen', '127.0.0.1', '--port', '18188',
            '--base-directory', str(base),
            '--extra-model-paths-config', str(yaml),
            '--disable-all-custom-nodes', '--offline',
            '--disable-auto-launch',
        ], cwd='/opt/comfyui-baked', stdout=output, stderr=subprocess.STDOUT)
        try:
            deadline = time.monotonic() + 180
            while True:
                if process.poll() is not None:
                    raise RuntimeError(f'ComfyUI exited with {process.returncode}')
                try:
                    with urllib.request.urlopen('http://127.0.0.1:18188/object_info', timeout=5) as response:
                        nodes = json.load(response)
                    break
                except (urllib.error.URLError, TimeoutError):
                    if time.monotonic() >= deadline:
                        raise TimeoutError('ComfyUI did not become ready within 180 seconds')
                    time.sleep(1)
            assert not (required_nodes - nodes.keys()), sorted(required_nodes - nodes.keys())
            names = nodes['UNETLoader']['input']['required']['unet_name'][0]
            assert 'h3-ram-path-check.safetensors' in names, names
            assert 'h3-workspace-path-check.safetensors' in names, names
            with urllib.request.urlopen('http://127.0.0.1:18188/system_stats', timeout=5) as response:
                stats = json.load(response)
            assert stats['system']['comfyui_version'] == '0.43.0', stats
            print('PASS: ComfyUI 0.43.0 CPU server, H3 nodes, baked base-directory and RAM/workspace model discovery; CUDA stack and startup script unchanged.', flush=True)
        except BaseException:
            output.flush()
            print(log.read_text(), flush=True)
            raise
        finally:
            process.terminate()
            try:
                process.wait(timeout=15)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
