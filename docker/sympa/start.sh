#!/bin/bash

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
until pg_isready -h postgres -p 5432 -U sympa; do
    echo "PostgreSQL is unavailable - sleeping"
    sleep 2
done
echo "PostgreSQL is ready!"

# Initialize Sympa database if not already done
if [ ! -f /var/lib/sympa/.db_initialized ]; then
    echo "Initializing Sympa database..."
    /usr/sbin/sympa.pl --config=/etc/sympa/sympa.conf --health_check || true
    /usr/sbin/sympa.pl --config=/etc/sympa/sympa.conf --upgrade || true
    touch /var/lib/sympa/.db_initialized
fi

# Create the postmaster user if it doesn't exist
echo "Creating postmaster user..."
/usr/sbin/sympa.pl --config=/etc/sympa/sympa.conf --add_list_admin=postmaster@localhost --create_list=testlist || true

# Start services
echo "Starting Postfix..."
service postfix start

echo "Starting Apache..."
service apache2 start

echo "Starting Sympa..."
# Start Sympa in the background
/usr/sbin/sympa.pl --config=/etc/sympa/sympa.conf --daemon &

# Start the task manager
echo "Starting Sympa task manager..."
/usr/sbin/task_manager.pl --config=/etc/sympa/sympa.conf --daemon &

# Start the bulk mailer
echo "Starting Sympa bulk mailer..."
/usr/sbin/bulk.pl --config=/etc/sympa/sympa.conf --daemon &

# Start the archived process
echo "Starting Sympa archived..."
/usr/sbin/archived.pl --config=/etc/sympa/sympa.conf --daemon &

# Keep the container running
echo "Sympa services started. Tailing logs..."
tail -f /var/log/sympa/sympa.log /var/log/apache2/sympa_error.log /var/log/apache2/sympa_access.log
