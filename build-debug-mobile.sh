#!/bin/bash

# Exit on any error
set -e

echo "=================================================="
echo " Building Debug Mobile Apps (Android & iOS)       "
echo "=================================================="

# Check if Flutter is installed
if ! [ -x "$(command -v flutter)" ]; then
  echo "Error: Flutter SDK is not installed." >&2
  exit 1
fi

cd apps/mobile

# Generate platform directories if they are missing
if [ ! -d "android" ] || [ ! -d "ios" ]; then
  echo "--> Platform directories missing. Generating android/ios templates..."
  flutter create --platforms=android,ios .
fi

echo "--> Fetching dependencies..."
flutter pub get

# Step 1: Build Android Debug APK
echo "--> Step 1: Building Android Debug APK..."
flutter build apk --debug
echo "✓ Android Debug APK built successfully!"
echo "  Output: apps/mobile/build/app/outputs/flutter-apk/app-debug.apk"

# Step 2: Build iOS Debug App (macOS only)
echo ""
echo "--> Step 2: Building iOS Debug App..."
if [[ "$OSTYPE" == "darwin"* ]]; then
  flutter build ios --debug --no-codesign
  echo "✓ iOS Debug App built successfully!"
  echo "  Output: apps/mobile/build/ios/iphoneos/Runner.app"
else
  echo "⚠ Warning: Non-macOS environment detected ($OSTYPE). Skipping iOS build."
fi

cd ../..
echo ""
echo "=================================================="
echo " Mobile Debug Builds Complete!                     "
echo "=================================================="
