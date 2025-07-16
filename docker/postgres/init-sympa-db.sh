#!/bin/bash
set -e

# Create additional users and databases if needed
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create extensions that Sympa might need
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

    -- Grant all privileges to sympa user
    GRANT ALL PRIVILEGES ON DATABASE sympa TO sympa;

    -- Create some basic tables that Sympa expects (these will be created by Sympa itself)
    -- This is just to ensure the database is ready
EOSQL

echo "PostgreSQL initialization completed for Sympa"
