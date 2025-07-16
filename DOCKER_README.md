# Sympa Test Environment for mail-sympa Ruby Library

This directory contains Docker configuration to set up a Sympa mailing list server for testing the mail-sympa Ruby library.

## Quick Start

1. **Start the test environment:**
   ```bash
   cd docker
   ./setup-test-env.sh
   ```

2. **Create test configuration:**
   ```bash
   ./create-test-config.sh
   ```

3. **Access the web interface:**
   Open http://localhost:8080/sympa in your browser

4. **Set up admin user:**
   - Go to the web interface
   - Create a user `postmaster@localhost` with password `admin_password`
   - Grant this user listmaster privileges

5. **Run tests:**
   ```bash
   bundle exec rake test
   ```

## Configuration Details

### Services

- **Sympa Server**: Runs on port 8080 (HTTP) and 8025 (SMTP)
- **PostgreSQL**: Runs on port 5432
- **SOAP Endpoint**: Available at http://localhost:8080/sympasoap

### Test Configuration

The test suite expects a DBI configuration file (`~/.dbirc`) with this format:

```
[test_sympa]
user = postmaster@localhost
password = admin_password
driver = http://localhost:8080/sympasoap
```

### Docker Files

- `docker-compose.simple.yml`: Main docker-compose file using official Sympa image
- `docker-compose.yml`: Alternative setup with custom Debian-based image
- `docker/`: Configuration files and custom Docker setup

## Manual Setup

If you prefer to set up manually:

1. **Start services:**
   ```bash
   docker compose -f docker-compose.simple.yml up -d
   ```

2. **Check status:**
   ```bash
   docker compose -f docker-compose.simple.yml ps
   ```

3. **View logs:**
   ```bash
   docker compose -f docker-compose.simple.yml logs -f sympa
   ```

4. **Stop services:**
   ```bash
   docker compose -f docker-compose.simple.yml down
   ```

## Troubleshooting

### SOAP Endpoint Not Available

If the SOAP endpoint is not responding:

1. Check service status:
   ```bash
   docker compose -f docker-compose.simple.yml ps
   ```

2. Check Sympa logs:
   ```bash
   docker compose -f docker-compose.simple.yml logs sympa
   ```

3. Test SOAP endpoint:
   ```bash
   curl http://localhost:8080/sympasoap?wsdl
   ```

### Database Connection Issues

If there are database connectivity problems:

1. Check PostgreSQL logs:
   ```bash
   docker compose -f docker-compose.simple.yml logs postgres
   ```

2. Test database connection:
   ```bash
   docker compose -f docker-compose.simple.yml exec postgres psql -U sympa -d sympa -c "\dt"
   ```

### Test Failures

Common issues with tests:

1. **Authentication errors**: Ensure the postmaster user exists and has correct privileges
2. **SOAP endpoint not found**: Wait for services to fully start (can take 1-2 minutes)
3. **Database errors**: Check that PostgreSQL is running and accessible

## Environment Variables

You can customize the setup by modifying environment variables in the docker-compose file:

- `SYMPA_DOMAIN`: Domain name (default: localhost)
- `SYMPA_LISTMASTER`: Listmaster email (default: postmaster@localhost)
- `POSTGRES_PASSWORD`: Database password

## Notes

- The setup uses PostgreSQL as the database backend
- SOAP interface is enabled for the Ruby library integration
- The environment is designed for testing only, not production use
- Default credentials should be changed for any non-testing use
