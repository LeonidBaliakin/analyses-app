"""Install the pinned development model and OCR language data outside Git."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import tarfile
import urllib.request
import platform

ROOT = Path(__file__).resolve().parents[2]
RUNTIME = ROOT / '.runtime' / 'processing'
MODEL_REVISION = '91cad51170dc346986eccefdc2dd33a9da36ead9'
MODEL_SHA = '6a1a2eb6d15622bf3c96857206351ba97e1af16c30d7a74ee38970e434e9407e'
TESS_REVISION = '87416418657359cb625c412a48b6e1d6d41c29bd'

def download(url, path, expected=None):
    path = Path(path)
    if not path.exists():
        temporary = path.with_suffix(path.suffix + '.partial')
        with urllib.request.urlopen(url, timeout=60) as response, temporary.open('wb') as output:
            shutil.copyfileobj(response, output, 1024 * 1024)
        temporary.replace(path)
    digest = hashlib.file_digest(path.open('rb'), 'sha256').hexdigest()
    if expected and digest != expected:
        raise RuntimeError('Downloaded artifact SHA-256 mismatch')
    return digest

def main():
    if platform.system()!='Darwin' or platform.machine()!='arm64':
        raise SystemExit('This installer targets development macOS ARM64 only.')
    RUNTIME.mkdir(parents=True, exist_ok=True)
    archive=RUNTIME/'llama-b12359-bin-macos-arm64.tar.gz'
    download('https://github.com/ggml-org/llama.cpp/releases/download/b12359/'+archive.name,archive,'82b00abc740160e1b9980e6cc79c117345fa34af058c80e6c0a69aa8ddccde75')
    binary_dir=RUNTIME/'llama-b12359'
    if not binary_dir.exists():
        binary_dir.mkdir()
        with tarfile.open(archive) as tar:
            tar.extractall(binary_dir,filter='data')
    model = RUNTIME / 'qwen2.5-1.5b-instruct-q4_k_m.gguf'
    download(f'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/{MODEL_REVISION}/{model.name}', model, MODEL_SHA)
    languages = RUNTIME / 'tessdata'
    languages.mkdir(exist_ok=True)
    hashes = {}
    for lang in ('rus', 'eng'):
        hashes[lang] = download(f'https://raw.githubusercontent.com/tesseract-ocr/tessdata_fast/{TESS_REVISION}/{lang}.traineddata', languages / f'{lang}.traineddata', {'rus':'e16e5e036cce1d9ec2b00063cf8b54472625b9e14d893a169e2b0dedeb4df225','eng':'7d4322bd2a7749724879683fc3912cb542f19906c83bcc1a52132556427170b2'}[lang])
    manifest = {'modelRevision': MODEL_REVISION, 'modelSha256': MODEL_SHA, 'modelFile': str(model),
                'modelId': 'qwen2.5-1.5b-q4_k_m-' + MODEL_SHA[:12], 'llamaRevision':'b12359',
                'llamaArchiveSha256':'82b00abc740160e1b9980e6cc79c117345fa34af058c80e6c0a69aa8ddccde75', 'tessdataRevision': TESS_REVISION, 'tessdataSha256': hashes}
    (RUNTIME / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print('Verified Qwen model and RU/EN OCR data installed in ignored .runtime/processing.')

if __name__ == '__main__':
    main()
