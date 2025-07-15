#!/bin/bash

# Setup script for Sympa test environment
# This script helps configure the test environment for the mail-sympa Ruby library

echo "Setting up Sympa test environment..."

# Check which compose file to use
COMPOSE_FILE="../docker-compose.simple.yml"
if [ "$1" = "mock" ]; then
    COMPOSE_FILE="../docker-compose.mock.yml"
    echo "Using mock Sympa server..."
elif [ "$1" = "mysql" ]; then
    COMPOSE_FILE="../docker-compose.mysql.yml"
    echo "Using MySQL-based Sympa server..."
else
    echo "Using PostgreSQL-based Sympa server..."
fi

# Check if Docker and docker compose are available
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed or not in PATH"
    exit 1
fi

if ! docker compose version &> /dev/null; then
    echo "Error: Docker Compose is not available"
    exit 1
fi

# Start the services
echo "Starting Sympa services..."
docker compose -f "$COMPOSE_FILE" up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 30

# Check if services are running
echo "Checking service status..."
docker compose -f "$COMPOSE_FILE" ps

# Check if SOAP endpoint is accessible
echo "Testing SOAP endpoint..."
if curl -f http://localhost:8080/sympasoap?wsdl > /dev/null 2>&1; then
    echo "✓ SOAP endpoint is accessible at http://localhost:8080/sympasoap"
else
    echo "⚠ SOAP endpoint may not be ready yet. You may need to wait a bit longer."
fi

echo ""
echo "Sympa test environment setup complete!"
echo ""
echo "Configuration for your tests:"
echo "  SOAP URL: http://localhost:8080/sympasoap"
echo "  Test user: postmaster@localhost"
echo "  Password: (you'll need to set this up via the web interface)"
echo "  Web interface: http://localhost:8080/sympa"
echo ""
echo "To create a .dbirc file for tests, run:"
echo "  ./create-test-config.sh"
echo ""
echo "To stop the services:"
echo "  docker compose -f $COMPOSE_FILE down"
