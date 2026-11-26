"""Generate local-only credentials without printing them; never overwrite keys."""
import hashlib
import json
import os
from pathlib import Path
import secrets

root = Path(__file__).resolve().parent
os.umask(0o077)
if (root / '.env').exists() or (root / '.secrets').exists():
    raise SystemExit('Local configuration exists; leaving it unchanged.')
private = root / '.secrets'
private.mkdir()
password, access, secret, token = [secrets.token_hex(24) for _ in range(4)]
(root / '.env').write_text(f'POSTGRES_PASSWORD={password}\nS3_ACCESS_KEY={access}\nS3_SECRET_KEY={secret}\nDOCUMENTS_DEV_TOKEN={token}\nCLOUD_SERVICE_KEY={secrets.token_hex(32)}\nCLOUD_ADMIN_KEY={secrets.token_hex(32)}\n')
(private / 's3.json').write_text(json.dumps({'identities':[{'name':'documents-service','credentials':[{'accessKey':access,'secretKey':secret}],'actions':['Admin','Read','Write','List','Tagging']}]}))
(private / 'identities.json').write_text(json.dumps([{'ownerId':'dev-owner','profileId':'local-profile','tokenSha256':hashlib.sha256(token.encode()).hexdigest(),'quotaBytes':100*1024*1024}]))
(private / 'identities.json').chmod(0o644)
print('Local Documents configuration created; credentials are in ignored files.')
