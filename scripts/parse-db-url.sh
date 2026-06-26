#!/bin/sh
# Parse DATABASE_URL into individual components for Temporal
# Usage: eval $(./scripts/parse-db-url.sh)

if [ -z "$TEMPORAL_DATABASE_URL" ] && [ -z "$DATABASE_URL" ]; then
    echo "ERROR: Neither TEMPORAL_DATABASE_URL nor DATABASE_URL is set" >&2
    exit 1
fi

# Use TEMPORAL_DATABASE_URL if set, otherwise fall back to DATABASE_URL
DB_URL="${TEMPORAL_DATABASE_URL:-$DATABASE_URL}"

# Parse postgresql://user:password@host:port/database
# Remove postgresql:// prefix
DB_URL_STRIPPED=$(echo "$DB_URL" | sed 's|postgresql://||')

# Extract user (before first :)
TEMPORAL_PG_USER=$(echo "$DB_URL_STRIPPED" | cut -d: -f1)

# Extract password (between first : and @)
TEMPORAL_PG_PASSWORD=$(echo "$DB_URL_STRIPPED" | cut -d: -f2 | cut -d@ -f1)

# Extract host (between @ and :)
TEMPORAL_PG_HOST=$(echo "$DB_URL_STRIPPED" | cut -d@ -f2 | cut -d: -f1)

# Extract port (between : and /)
TEMPORAL_PG_PORT=$(echo "$DB_URL_STRIPPED" | cut -d: -f3 | cut -d/ -f1)

# Extract database name (after last /)
TEMPORAL_PG_DB=$(echo "$DB_URL_STRIPPED" | rev | cut -d/ -f1 | rev)

echo "export TEMPORAL_PG_USER='$TEMPORAL_PG_USER'"
echo "export TEMPORAL_PG_PASSWORD='$TEMPORAL_PG_PASSWORD'"
echo "export TEMPORAL_PG_HOST='$TEMPORAL_PG_HOST'"
echo "export TEMPORAL_PG_PORT='${TEMPORAL_PG_PORT:-5432}'"
echo "export TEMPORAL_PG_DB='$TEMPORAL_PG_DB'"
