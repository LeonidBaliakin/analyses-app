SELECT 'CREATE DATABASE records'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'records')
\gexec
