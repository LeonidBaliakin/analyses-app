"""Enable accounts on the local test stack, preserving all existing credentials."""
import base64
import os
from pathlib import Path
import secrets

os.umask(0o077)
path = Path(__file__).resolve().parent / '.env'
if not path.exists():
    raise SystemExit('Run init_dev.py first.')
lines = path.read_text().splitlines()
keys = {line.partition('=')[0] for line in lines}
values = {
    'CLOUD_SERVICE_KEY': secrets.token_hex(32),
    'CLOUD_ADMIN_KEY': secrets.token_hex(32),
    'IDENTITY_ENDPOINT': 'http://identity:8083/',
    'IDENTITY_SERVICE_KEY': secrets.token_hex(32),
    'IDENTITY_MAIL_KEY': base64.b64encode(secrets.token_bytes(32)).decode(),
}
for key, value in values.items():
    if key not in keys:
        lines.append(f'{key}={value}')
temporary = path.with_suffix('.tmp')
temporary.write_text('\n'.join(lines) + '\n')
temporary.replace(path)
print('Local accounts configured. SMTP stays inside Mailpit; no external mail is sent.')
