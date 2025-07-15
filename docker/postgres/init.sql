-- Initialize Sympa database tables
-- This script will be run when the PostgreSQL container starts

-- Grant all privileges to sympa user
GRANT ALL PRIVILEGES ON DATABASE sympa TO sympa;

-- The actual table creation will be handled by Sympa itself
-- when it starts up for the first time
