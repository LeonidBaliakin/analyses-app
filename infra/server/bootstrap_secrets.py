"""Create stable server credentials once; never print or implicitly rotate them."""
import json
import base64
import os
from pathlib import Path
import secrets
import sys

path = Path(sys.argv[1])
os.umask(0o077)
values = json.loads(path.read_text()) if path.exists() else {}
updated = False
for name in ('postgres_password', 's3_access_key', 's3_secret_key', 'client_token',
             'identity_service_key', 'identity_mail_key', 'cloud_service_key', 'cloud_admin_key', 'notifications_publisher_key', 'notifications_admin_key',
             'notifications_telegram_key', 'notifications_vk_key', 'notifications_max_key',
             'directory_admin_key', 'directory_invitro_key', 'directory_helix_key',
             'directory_smclinic_key', 'directory_scandinavia_key', 'directory_sova_key',
             'directory_medexpert_key', 'directory_csp_key'):
    if name not in values:
        values[name] = (base64.b64encode(secrets.token_bytes(32)).decode()
                        if name == 'identity_mail_key' else secrets.token_hex(32))
        updated = True
if updated:
    temporary = path.with_suffix('.tmp')
    with temporary.open('w') as output:
        output.write(json.dumps(values) + '\n')
    temporary.replace(path)
    print('updated')
