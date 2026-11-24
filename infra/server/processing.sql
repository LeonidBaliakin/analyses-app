SELECT 'CREATE DATABASE processing'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'processing')
\gexec
