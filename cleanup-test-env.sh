#!/bin/bash

# Cleanup script for Sympa test environment

echo "Stopping Sympa test environment..."

# Stop and remove containers
docker-compose -f docker-compose.simple.yml down

# Optional: Remove volumes (this will delete all data)
read -p "Do you want to remove all data volumes? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing volumes..."
    docker-compose -f docker-compose.simple.yml down -v
    docker volume prune -f
fi

# Optional: Remove images
read -p "Do you want to remove downloaded images? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing images..."
    docker image rm sympa/sympa:6.2.70 postgres:13 2>/dev/null || true
fi

echo "Cleanup complete!"
