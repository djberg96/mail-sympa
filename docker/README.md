# Docker Setup for Sympa Testing

This Docker Compose setup provides a complete Sympa mailing list server environment for testing the mail-sympa Ruby library.

## Services Included

- **Sympa Server**: Main mailing list server with SOAP interface
- **PostgreSQL**: Database backend (port 5433 to avoid conflicts)
- **MailHog**: Email testing tool for capturing outbound emails

## Quick Start

1. **Start the environment**:
   ```bash
   cd /home/dberger/Dev/mail-sympa
   ./docker/setup.sh
   ```

   Or manually:
   ```bash
   docker-compose up -d
   ```

2. **Wait for initialization** (may take 2-5 minutes):
   ```bash
   docker-compose logs -f sympa
   ```

3. **Access the interfaces**:
   - Sympa Web: http://localhost:8080/sympa
   - SOAP Interface: http://localhost:8080/sympasoap
   - MailHog: http://localhost:8025

## Testing Your Library

### Configuration

1. **Set up database credentials** for testing by copying the example:
   ```bash
   cp docker/dbrc_example ~/.dbrc
   # Edit ~/.dbrc with your preferred credentials
   ```

2. **Use the SOAP endpoint** in your tests:
   ```ruby
   sympa = Mail::Sympa.new('http://localhost:8080/sympasoap')
   ```

### Initial Setup

1. **Access the web interface** at http://localhost:8080/sympa
2. **Create the initial admin account** (listmaster@localhost)
3. **Create test mailing lists** for your library testing
4. **Add test users** as needed

### Example Test Code

```ruby
require 'mail/sympa'
require 'dbi/dbrc'

# Using dbrc configuration
info = DBI::DBRC.new('sympa_docker')
sympa = Mail::Sympa.new(info.driver)
sympa.login(info.user, info.passwd)

# Test basic functionality
puts sympa.lists
```

## Ports Used

- **8080**: Sympa web interface and SOAP
- **5433**: PostgreSQL (to avoid conflict with local PostgreSQL on 5432)
- **8025**: MailHog web interface
- **1025**: MailHog SMTP server

## Database Access

If you need to access the PostgreSQL database directly:

```bash
# Connect to database
docker-compose exec postgres psql -U sympa -d sympa

# Or from host (requires psql client)
psql -h localhost -p 5433 -U sympa -d sympa
```

## Troubleshooting

### Services won't start
```bash
# Check service status
docker-compose ps

# View logs
docker-compose logs sympa
docker-compose logs postgres
```

### SOAP interface not responding
```bash
# Restart Sympa container
docker-compose restart sympa

# Check if Sympa finished initialization
docker-compose logs sympa | grep -i soap
```

### Reset everything
```bash
# Stop and remove all containers and volumes
docker-compose down -v

# Start fresh
./docker/setup.sh
```

## Configuration Files

- `docker-compose.yml`: Main Docker Compose configuration
- `docker/sympa/sympa.conf`: Main Sympa configuration
- `docker/sympa/wwsympa.conf`: Web interface configuration
- `docker/sympa/trusted_apps.conf`: SOAP authentication apps
- `docker/postgres/init-sympa-db.sh`: PostgreSQL initialization

## Security Notes

This setup is for **development and testing only**. The default passwords and configurations are not secure for production use.

Default credentials and settings:
- Database: sympa/sympa_password
- Trusted app: test_app/test_password
- All interfaces bound to localhost only
