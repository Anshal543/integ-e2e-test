#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

export DATABASE_URL="${DATABASE_URL:-postgresql://postgres:mysecretpassword@localhost:5432/postgres}"

docker compose up -d
trap 'docker compose down' EXIT

echo '🟡 - Waiting for database to be ready...'
for attempt in {1..30}; do
	if docker compose exec -T db pg_isready -U postgres -d postgres >/dev/null 2>&1; then
		echo '🟢 - Database is ready!'
		break
	fi

	if [[ "$attempt" -eq 30 ]]; then
		echo '🔴 - Database did not become ready in time.' >&2
		exit 1
	fi

	sleep 1
done
npx prisma migrate dev --name init
npm run test -- --run