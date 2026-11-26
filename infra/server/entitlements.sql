SELECT 'CREATE DATABASE entitlements'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'entitlements')
\gexec
