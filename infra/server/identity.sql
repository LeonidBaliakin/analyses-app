SELECT 'CREATE DATABASE identity'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'identity')
\gexec
