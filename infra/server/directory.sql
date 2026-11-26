SELECT 'CREATE DATABASE provider_directory'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'provider_directory')\gexec
