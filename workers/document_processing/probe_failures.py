"""Real runtime fault probe; synthetic inputs only, no patient content in output."""
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

root=Path(__file__).resolve().parents[2]
config_path=root/'.runtime/processing/local-config.json'
config=json.loads(config_path.read_text())
def start(file,mime,digest=None):
 p=subprocess.Popen([config['python'],config['workerScript'],'--config',str(config_path),'--file',str(file)],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
 p.stdin.write(json.dumps({'runtimeId':config['runtimeId'],'mime':mime,'size':file.stat().st_size,'sha256':digest or hashlib.sha256(file.read_bytes()).hexdigest()})+'\n');p.stdin.close()
 return p
with tempfile.TemporaryDirectory(prefix='analyses-runtime-faults-') as temp:
 file=Path(temp)/'synthetic.png';file.write_bytes((root/'.runtime/processing/fixtures/ru-numeric.png').read_bytes())
 for code,mime,digest in [('original_integrity','image/png','0'*64),('unsupported','text/plain',None)]:
  p=start(file,mime,digest);events=[json.loads(line) for line in p.stdout];p.wait(timeout=15)
  assert events[-1].get('error')==code,(code,events[-1]);print(code+': verified')
 bad=Path(temp)/'damaged.png';bad.write_bytes(b'\x89PNG\r\n\x1a\nsynthetic corruption')
 p=start(bad,'image/png');events=[json.loads(line) for line in p.stdout];p.wait(timeout=15)
 assert events[-1].get('error')=='ocr_failed';print('corrupt image: verified')
 p=start(file,'image/png');first=json.loads(p.stdout.readline());assert first['stage']=='ocr';p.terminate();p.wait(timeout=10)
 assert not list(Path(temp).glob('analyses-ocr-*')),'temporary OCR data remained'
 print('SIGTERM cancellation and OCR temporary cleanup: verified')
