#!/bin/bash

# Setup script for Sympa Docker testing environment

echo "Setting up Sympa Docker environment for mail-sympa library testing..."

# Check if Docker and Docker Compose are available
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed or not in PATH"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "Error: Docker Compose is not installed or not in PATH"
    exit 1
fi

# Start the services
echo "Starting Docker services..."
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 30

# Check if PostgreSQL is ready
echo "Checking PostgreSQL connection..."
docker-compose exec postgres pg_isready -U sympa -d sympa

# Check if Sympa web interface is accessible
echo "Checking Sympa web interface..."
curl -f http://localhost:8080/sympa || echo "Web interface not yet ready, may need more time..."

# Check if SOAP interface is accessible
echo "Checking SOAP interface..."
curl -f http://localhost:8080/sympasoap || echo "SOAP interface not yet ready, may need more time..."

echo ""
echo "Setup complete! Services should be running on:"
echo "  - Sympa Web Interface: http://localhost:8080/sympa"
echo "  - Sympa SOAP Interface: http://localhost:8080/sympasoap"
echo "  - PostgreSQL: localhost:5433"
echo "  - MailHog (email testing): http://localhost:8025"
echo ""
echo "To test your library, use the SOAP URL: http://localhost:8080/sympasoap"
echo ""
echo "Default admin credentials:"
echo "  Username: listmaster@localhost"
echo "  Password: (will be set during first setup)"
echo ""
echo "You may need to wait a few more minutes for Sympa to fully initialize."
echo "Check the logs with: docker-compose logs -f sympa"
