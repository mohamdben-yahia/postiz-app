#!/bin/sh
# Temporal startup wrapper that parses DATABASE_URL if individual vars aren't set
set -e

echo "=== Temporal Startup Wrapper ==="

# If individual vars are already set, use them
if [ -n "$TEMPORAL_PG_HOST" ] && [ -n "$TEMPORAL_PG_USER" ] && [ -n "$TEMPORAL_PG_PASSWORD" ]; then
    echo "✓ Using provided TEMPORAL_PG_* environment variables"
    export POSTGRES_SEEDS="$TEMPORAL_PG_HOST"
    export POSTGRES_USER="$TEMPORAL_PG_USER"
    export POSTGRES_PWD="$TEMPORAL_PG_PASSWORD"
else
    # Parse from TEMPORAL_DATABASE_URL or DATABASE_URL
    DB_URL="${TEMPORAL_DATABASE_URL:-$DATABASE_URL}"
    
    if [ -z "$DB_URL" ]; then
        echo "ERROR: No database configuration found!"
        echo "Please set either:"
        echo "  - TEMPORAL_PG_HOST, TEMPORAL_PG_USER, TEMPORAL_PG_PASSWORD"
        echo "  - TEMPORAL_DATABASE_URL"
        echo "  - DATABASE_URL (will be shared with main app)"
        exit 1
    fi
    
    echo "✓ Parsing database URL..."
    
    # Remove postgresql:// or postgres:// prefix
    DB_URL_STRIPPED=$(echo "$DB_URL" | sed -E 's|^postgres(ql)?://||')
    
    # Extract components
    # Format: user:password@host:port/database
    USER_PASS=$(echo "$DB_URL_STRIPPED" | cut -d@ -f1)
    HOST_PORT_DB=$(echo "$DB_URL_STRIPPED" | cut -d@ -f2)
    
    export POSTGRES_USER=$(echo "$USER_PASS" | cut -d: -f1)
    export POSTGRES_PWD=$(echo "$USER_PASS" | cut -d: -f2)
    export POSTGRES_SEEDS=$(echo "$HOST_PORT_DB" | cut -d: -f1)
    
    echo "  Database host: $POSTGRES_SEEDS"
    echo "  Database user: $POSTGRES_USER"
    echo "  Password: ****"
fi

# Test PostgreSQL connectivity before starting Temporal
echo "Testing PostgreSQL connectivity..."
if command -v nc >/dev/null 2>&1; then
    if ! nc -z -w5 "$POSTGRES_SEEDS" 5432 2>/dev/null; then
        echo "ERROR: Cannot connect to PostgreSQL at $POSTGRES_SEEDS:5432"
        echo "Please verify:"
        echo "  1. Database host is correct"
        echo "  2. Database is running"
        echo "  3. Network connectivity from container"
        exit 1
    fi
    echo "✓ PostgreSQL is reachable"
else
    echo "⚠ nc not available, skipping connectivity test"
fi

echo "Starting Temporal server..."
echo "================================"

# Start Temporal (original entrypoint)
exec /etc/temporal/entrypoint.sh
