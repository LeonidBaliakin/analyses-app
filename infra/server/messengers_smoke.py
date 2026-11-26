"""Exercise simulation queues through container HTTP; never contacts a provider."""
import json
from pathlib import Path
import subprocess
import sys
import time
import uuid

root = Path(sys.argv[1]).resolve()
if not (root / 'compose.yaml').is_file():
    raise SystemExit('Pass a deployed server directory')
base = ['docker', 'compose', '--project-directory', str(root), '--profile', 'messengers']


def request(operation, **payload):
    result = subprocess.run(
        base + ['exec', '-T', 'notifications', '/app/notifications', '--request'],
        input=json.dumps({'operation': operation, **payload}),
        text=True, capture_output=True, check=True, timeout=15,
    )
    return json.loads(result.stdout)


for service, binary in [('notifications', 'notifications')] + [
    (f'delivery-{channel}', 'delivery') for channel in ('telegram', 'vk', 'max')
]:
    subprocess.run(base + ['exec', '-T', service, f'/app/{binary}', '--health'],
                   capture_output=True, check=True, timeout=10)

prefix = 'smoke_' + uuid.uuid4().hex
intents = []
for channel in ('telegram', 'vk', 'max'):
    binding = prefix + '_' + channel
    request('binding', body={'schemaVersion': 1, 'bindingId': binding,
                            'ownerId': 'synthetic_messenger_smoke', 'channel': channel,
                            'enabled': True, 'simulationOnly': True})
    intent = {'schemaVersion': 1, 'notificationId': binding,
              'ownerId': 'synthetic_messenger_smoke', 'channel': channel,
              'bindingId': binding, 'template': 'activity_available', 'locale': 'ru'}
    for _ in range(2):
        assert request('enqueue', body=intent)['notificationId'] == binding
    intents.append(intent)

deadline = time.monotonic() + 30
while True:
    statuses = [request('status', notificationId=i['notificationId']) for i in intents]
    if all(s['state'] == 'simulated' and s['attempts'] == 1 for s in statuses):
        break
    if time.monotonic() > deadline:
        raise SystemExit('Expected one simulated attempt per channel; check dry_run modes')
    time.sleep(1)

for intent in intents:
    replay = request('enqueue', body=intent)
    assert replay['state'] == 'simulated' and replay['attempts'] == 1
    request('binding', body={'schemaVersion': 1, 'bindingId': intent['bindingId'],
                            'ownerId': 'synthetic_messenger_smoke', 'channel': intent['channel'],
                            'enabled': False, 'simulationOnly': True})
print(json.dumps({'simulationOnly': True, 'channels': ['telegram', 'vk', 'max'],
                  'simulated': 3, 'attemptsPerNotification': 1, 'replaysDeduplicated': True}))
