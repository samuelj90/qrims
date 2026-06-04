#!/bin/bash

# Exit on any error
set -e

# Change directory to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "=================================================="
echo " Building Debug Mobile Apps (Android)             "
echo "=================================================="

# Check if Flutter is installed
if ! [ -x "$(command -v flutter)" ]; then
  echo "Error: Flutter SDK is not installed in the PATH." >&2
  exit 1
fi

echo "--> Syncing application configuration..."
node sync_config.js

cd apps/mobile

if [ ! -d "android" ] || [ ! -d "ios" ]; then
  echo "--> Platform directories missing. Generating android/ios templates..."
  flutter create --platforms=android,ios .
fi

echo "--> Fetching dependencies..."
flutter pub get

echo "--> Building Android Debug APK..."
flutter build apk --debug

echo "Check if build succeeded..."
if [ ! -f "build/app/outputs/flutter-apk/app-debug.apk" ]; then
  echo "Error: Mobile build failed!"
  exit 1
fi

echo "Check completed!"
echo ""
echo "=================================================="
echo " Mobile Debug Builds Complete!                     "
echo " Output: apps/mobile/build/app/outputs/flutter-apk/app-debug.apk"
echo "=================================================="
