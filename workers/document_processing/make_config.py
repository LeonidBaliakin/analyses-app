import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

manifest=json.loads(Path(sys.argv[1]).read_text())
root=Path(sys.argv[1]).resolve().parent
config={**manifest,'python':sys.executable,'workerScript':str(Path(__file__).resolve().parent/'worker.py'),'llmUrl':os.environ.get('PROCESSING_LLM_URL','http://127.0.0.1:18089'),
        'tesseract':shutil.which('tesseract'),'pdftoppm':shutil.which('pdftoppm'),
        'tessdata':os.environ.get('PROCESSING_TESSDATA',str(root/'tessdata'))}
config['ocrVersion']=subprocess.check_output([config['tesseract'],'--version'],text=True).splitlines()[0]+':'+manifest['tessdataRevision']
config['workerSha256']=hashlib.sha256(Path(config['workerScript']).read_bytes()).hexdigest()
config['runtimeId']=hashlib.sha256(json.dumps({k:config[k] for k in ['modelSha256','modelId','tessdataSha256','ocrVersion','workerSha256','llamaRevision']},sort_keys=True).encode()).hexdigest()
Path(sys.argv[2]).write_text(json.dumps(config,indent=2)+'\n')
print('Processing runtime configuration written.')
