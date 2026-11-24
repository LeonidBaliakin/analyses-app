"""Create stable server credentials once; never print or implicitly rotate them."""
import json
import os
from pathlib import Path
import secrets
import sys

path = Path(sys.argv[1])
os.umask(0o077)
values = {name: secrets.token_hex(32) for name in (
    'postgres_password', 's3_access_key', 's3_secret_key', 'client_token')}
try:
    with path.open('x') as output:
        output.write(json.dumps(values) + '\n')
except FileExistsError:
    pass
