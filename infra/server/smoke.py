"""Real container-only deployment smoke test. Uses a clearly synthetic fixture."""
import hashlib
import json
from pathlib import Path
import sys
import time
import urllib.error
import urllib.request

root = Path(sys.argv[1]).resolve()
env = dict(line.split('=', 1) for line in (root / '.env').read_text().splitlines())
credentials = json.loads((root / '.secrets/bootstrap.json').read_text())
identity = json.loads((root / '.secrets/identities.json').read_text())[0]
base = f"http://127.0.0.1:{env['API_PORT']}/v1/profiles/{identity['profileId']}/"

def request(method, path, body=None, binary=False, token=True):
    data = None if body is None else body if binary else json.dumps(body).encode()
    headers = {'content-type': 'application/octet-stream' if binary else 'application/json'}
    if token:
        headers['authorization'] = 'Bearer ' + credentials['client_token']
    req = urllib.request.Request(base + path, method=method, data=data, headers=headers)
    with urllib.request.urlopen(req, timeout=60) as response:
        raw = response.read()
        return raw if binary and method == 'GET' else json.loads(raw)

fixture = Path(__file__).resolve().parent / 'fixtures/synthetic-lab.png'
data = fixture.read_bytes()
sha = hashlib.sha256(data).hexdigest()
original = 'server-smoke-' + sha[:16]
meta = {'originalId': original, 'documentId': 'doc-' + original,
        'fileName': 'synthetic-lab.png', 'mime': 'image/png', 'size': len(data),
        'sha256': sha, 'importedAt': '2026-11-24T00:00:00.000Z', 'importSource': 'files'}
capability = request('GET', 'processing-capabilities')
assert capability['ready'], 'container runtime unavailable'
for _ in range(2):
    request('POST', 'uploads', meta)
    request('PUT', 'uploads/' + original + '/content', data, binary=True)
    request('POST', 'uploads/' + original + '/finalize')
assert hashlib.sha256(request('GET', 'originals/' + original + '/content', binary=True)).hexdigest() == sha
try:
    request('GET', 'originals/' + original + '/content', binary=True, token=False)
    raise AssertionError('Original readable without authorization')
except urllib.error.HTTPError as exc:
    assert exc.code == 401
job = {'jobId': 'smoke-' + sha[:16] + '-' + capability['runtimeId'][:16], 'originalId': original,
       'runtimeId': capability['runtimeId'], 'terminologyReleaseId': 'analyses-pilot-2026-11-24.1'}
first = request('POST', 'processing-jobs', job)
replay = request('POST', 'processing-jobs', job)
assert first['jobId'] == replay['jobId']
deadline = time.monotonic() + 240
while replay['status'] not in ('ready', 'failed', 'cancelled'):
    assert time.monotonic() < deadline, 'processing deadline'
    time.sleep(.5)
    replay = request('GET', 'processing-jobs/' + job['jobId'])
assert replay['status'] == 'ready', replay.get('error')
draft = replay['draft']
assert draft['schemaVersion'] == 1 and draft['runtimeId'] == capability['runtimeId']
assert draft['pages'] and draft['rows'], 'missing OCR/LLM output'
for row in draft['rows']:
    page = next(p for p in draft['pages'] if p['number'] == row['page'])
    assert row['evidence'] in page['text'], 'unbacked evidence'
assert 'sha256:' in draft['versions']['llama'], 'inference image digest missing from provenance'
print('Container-only smoke passed: private original, SHA-256, upload/job replay, real OCR/LLM draft.')
print('Recognized rows:', len(draft['rows']), '(unconfirmed; no medical records created)')
