"""Fixed synthetic set through the real native worker and Documents/Processing stack."""
import hashlib
import json
from pathlib import Path
import subprocess
import threading
import time
import urllib.request
import uuid

root=Path(__file__).resolve().parents[2]
runtime=root/'.runtime/processing'
config=json.loads((runtime/'local-config.json').read_text())
env=dict(line.split('=',1) for line in (root/'infra/documents/.env').read_text().splitlines())
fixtures=json.loads((runtime/'fixtures/manifest.json').read_text())
base='http://127.0.0.1:18088/v1/profiles/local-profile/'
def request(method,path,body=None,binary=False):
 data=None if body is None else body if binary else json.dumps(body).encode()
 req=urllib.request.Request(base+path,method=method,data=data,headers={'authorization':'Bearer '+env['DOCUMENTS_DEV_TOKEN'],'content-type':'application/octet-stream' if binary else 'application/json'})
 with urllib.request.urlopen(req,timeout=60) as r:return json.load(r)
remote=request('GET','processing-capabilities')
if not remote.get('ready'):raise SystemExit('Processing runtime unavailable')
rows=[];rss=[];stop=threading.Event()
def sample():
 while not stop.is_set():
  p=subprocess.run(['pgrep','-f','llama-server --host 127.0.0.1 --port 18089'],capture_output=True,text=True)
  ids=p.stdout.strip().splitlines()
  if ids:
   r=subprocess.run(['ps','-o','rss=','-p',','.join(ids)],capture_output=True,text=True)
   rss.extend(int(v) for v in r.stdout.split() if v.isdigit())
  stop.wait(.1)
thread=threading.Thread(target=sample);thread.start()
try:
 for fixture in fixtures:
  file=Path(fixture['path']);data=file.read_bytes();mime='application/pdf' if file.suffix=='.pdf' else 'image/png'
  for mode in ['local','ownServer']:
   start=time.perf_counter();job_id='eval-'+uuid.uuid4().hex
   if mode=='local':
    p=subprocess.run([config['python'],config['workerScript'],'--config',str(runtime/'local-config.json'),'--file',str(file)],input=json.dumps({'runtimeId':config['runtimeId'],'size':len(data),'sha256':fixture['sha256'],'mime':mime})+'\n',text=True,capture_output=True,timeout=220)
    events=[json.loads(line) for line in p.stdout.splitlines()];ready=next((e['draft'] for e in events if e['stage']=='ready'),None);artifact=next((e for e in events if e['stage']=='extracting'),None);error=next((e['error'] for e in events if e['stage']=='failed'),None)
   else:
    original='eval-'+fixture['id']+'-'+fixture['sha256'][:12]
    meta={'originalId':original,'documentId':'doc-'+original,'fileName':file.name,'mime':mime,'size':len(data),'sha256':fixture['sha256'],'importSource':'files','importedAt':'2026-11-24T00:00:00.000Z'}
    request('POST','uploads',meta);request('PUT','uploads/'+original+'/content',data,True);request('POST','uploads/'+original+'/finalize')
    j=request('POST','processing-jobs',{'jobId':job_id,'originalId':original,'runtimeId':remote['runtimeId'],'terminologyReleaseId':'analyses-pilot-2026-11-24.1'})
    deadline=time.monotonic()+220
    while j['status'] not in ['ready','failed','cancelled']:
     if time.monotonic()>deadline:raise RuntimeError('Evaluation deadline')
     time.sleep(.15);j=request('GET','processing-jobs/'+job_id)
    ready=j.get('draft');artifact=j.get('artifact');error=j.get('error')
   rows.append({'fixture':fixture['id'],'mode':mode,'sha256':fixture['sha256'],'size':len(data),'mime':mime,'seconds':round(time.perf_counter()-start,3),'expected':fixture['expected'],'sourceText':fixture['text'],'draft':ready,'artifact':artifact,'error':error})
   print(f"{fixture['id']} {mode}: {rows[-1]['seconds']}s, "+(error or str(len(ready['rows']))+' rows'),flush=True)
finally:
 stop.set();thread.join()
result={'schemaVersion':1,'localRuntime':config['runtimeId'],'serverRuntime':remote['runtimeId'],'llamaRssPeakKiB':max(rss,default=0),'llamaRssSamplingMs':100,'cases':rows}
(runtime/'evaluation.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print('Saved synthetic results; shared Dart validation is the next evaluation step.')
