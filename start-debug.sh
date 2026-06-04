#!/bin/bash

# Exit on any error
set -e

echo "=========================================="
echo " Starting QRIMS Local Debug Ecosystem     "
echo "=========================================="

# Check if Docker is installed and running
if ! [ -x "$(command -v docker)" ]; then
  echo "Error: Docker is not installed. Please install Docker." >&2
  exit 1
fi

echo "--> Phase 1: Launching PostgreSQL and Redis dependencies..."
docker compose up -d postgres redis

echo "--> Waiting for PostgreSQL healthcheck to pass..."
until [ "$(docker inspect -f '{{.State.Health.Status}}' qrims-postgres)" == "healthy" ]; do
    sleep 1
done

echo "--> PostgreSQL is healthy and running!"

echo "--> Phase 2: Building Backend API and running DB migrations..."
cd apps/backend

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
  echo "--> Node modules not found. Running npm install..."
  npm install
fi

echo "--> Running Prisma migration dev..."
npx prisma migrate dev --name init

echo "--> Prisma generate clients..."
npx prisma generate

# Start NestJS in watch mode in the background
echo "--> Starting NestJS API Layer in Watch/Debug mode on port 3000..."
npm run start:dev &
BACKEND_PID=$!

cd ../..

echo "--> Phase 3: Launching Next.js Admin Console..."
cd apps/web

if [ ! -d "node_modules" ]; then
  echo "--> Node modules not found. Running npm install..."
  npm install
fi

# Start Next.js in development mode
echo "--> Starting Next.js Web Portal on port 3001..."
PORT=3001 npm run dev &
NEXTJS_PID=$!

cd ../..

echo "================================================="
echo " QRIMS Developer Debug Stack Initialized!        "
echo "                                                 "
echo " - NestJS API Service: http://localhost:3000/api/v1"
echo " - Swagger Documentation: http://localhost:3000/docs"
echo " - Next.js Admin Panel: http://localhost:3001     "
echo "                                                 "
echo " To launch the Flutter mobile client:            "
echo "   cd apps/mobile                                "
echo "   flutter pub get                               "
echo "   flutter run -d [device-id]                    "
echo "================================================="

# Trap exit signals to kill background tasks on terminate
cleanup() {
  echo "Stopping development servers..."
  kill $BACKEND_PID || true
  kill $NEXTJS_PID || true
  docker compose down
}

trap cleanup EXIT

# Keep script running to show logs
wait
