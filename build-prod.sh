#!/bin/bash

# Exit on any error
set -e

echo "=================================================="
echo " Preparing Production Builds for QRIMS Ecosystem "
echo "=================================================="

# Check if Node is installed
if ! [ -x "$(command -v node)" ]; then
  echo "Error: Node.js is not installed." >&2
  exit 1
fi

# Step 1: NestJS Backend Production Build
echo ""
echo "--> Step 1: Building NestJS Backend..."
cd apps/backend
if [ ! -d "node_modules" ]; then
  npm ci
fi
npx prisma generate
npm run build
cd ../..
echo "✓ Backend built successfully! Output in apps/backend/dist/"

# Step 2: Next.js Web Portal Production Build
echo ""
echo "--> Step 2: Building Next.js Web Portal..."
cd apps/web
if [ ! -d "node_modules" ]; then
  npm ci
fi
npm run build
cd ../..
echo "✓ Next.js Web Portal built successfully! Output in apps/web/.next/"

# Step 3: Flutter Mobile Production App (Android Release APK)
echo ""
echo "--> Step 3: Building Flutter Android Release APK..."
if [ -x "$(command -v flutter)" ]; then
  cd apps/mobile
  flutter pub get
  echo "Building release APK..."
  flutter build apk --release
  cd ../..
  echo "✓ Flutter Android APK built successfully!"
  echo "  Output: apps/mobile/build/app/outputs/flutter-apk/app-release.apk"
else
  echo "⚠ Warning: Flutter SDK not found. Skipping Flutter mobile production build."
fi

# Step 4: Docker Container Production Images
echo ""
echo "--> Step 4: Building Production Docker Containers..."
if [ -x "$(command -v docker)" ]; then
  docker compose build
  echo "✓ Docker images built successfully!"
else
  echo "⚠ Warning: Docker not found. Skipping container builds."
fi

echo ""
echo "=================================================="
echo " QRIMS Production Build Complete!                 "
echo "=================================================="
