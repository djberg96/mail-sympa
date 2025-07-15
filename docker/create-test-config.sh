#!/bin/bash

# Script to create test configuration for mail-sympa Ruby library
# This creates the .dbirc file that the tests expect

DBIRC_FILE="$HOME/.dbirc"
TEST_SECTION="test_sympa"

echo "Creating test configuration..."

# Check if .dbirc already exists and has test_sympa section
if [ -f "$DBIRC_FILE" ] && grep -q "^\[$TEST_SECTION\]" "$DBIRC_FILE"; then
    echo "Warning: $TEST_SECTION section already exists in $DBIRC_FILE"
    echo "You may want to update it manually."
    exit 1
fi

# Create or append to .dbirc file
cat >> "$DBIRC_FILE" << EOF

[$TEST_SECTION]
user = postmaster@localhost
password = admin_password
driver = http://localhost:8080/sympasoap
EOF

echo "✓ Test configuration added to $DBIRC_FILE"
echo ""
echo "Configuration details:"
echo "  Section: [$TEST_SECTION]"
echo "  User: postmaster@localhost"
echo "  Password: admin_password"
echo "  SOAP URL: http://localhost:8080/sympasoap"
echo ""
echo "Note: You may need to:"
echo "1. Access the web interface at http://localhost:8080/sympa"
echo "2. Create the postmaster@localhost user with password 'admin_password'"
echo "3. Grant admin privileges to this user"
echo ""
echo "After setup, you can run tests with:"
echo "  bundle exec rake test"
