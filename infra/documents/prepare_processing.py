"""Create only the two dedicated development databases, without deleting data."""
from pathlib import Path
import subprocess

sql=r"""SELECT 'CREATE DATABASE processing' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname='processing')
\gexec
SELECT 'CREATE DATABASE processing_tests' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname='processing_tests')
\gexec
"""
subprocess.run(['docker','compose','exec','-T','postgres','psql','-v','ON_ERROR_STOP=1','-U','documents','-d','postgres'],input=sql,text=True,cwd=Path(__file__).resolve().parent,check=True)
