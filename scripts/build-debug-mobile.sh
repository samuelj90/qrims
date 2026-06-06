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

# 1. Android Build
HAS_JAVA=false
if command -v java >/dev/null 2>&1 && java -version >/dev/null 2>&1; then
  HAS_JAVA=true
fi

BUILD_ANDROID_SUCCESS=false
if [ "$HAS_JAVA" = true ]; then
  echo ""
  echo "--> Building Android Debug APK..."
  if flutter build apk --debug; then
    BUILD_ANDROID_SUCCESS=true
  else
    echo "Error: Android build task failed."
  fi
else
  echo ""
  echo "⚠ Warning: Java Runtime (JDK) not found. Skipping Android debug build."
  echo "  To build for Android, please install JDK (e.g., from https://adoptium.net/)."
fi

# 2. iOS Build
BUILD_IOS_SUCCESS=false
IS_MAC=false
if [ "$(uname)" == "Darwin" ]; then
  IS_MAC=true

  # Check if Xcode CLI tools are installed
  if command -v xcodebuild >/dev/null 2>&1; then
    echo ""
    echo "--> Building iOS Debug App..."
    if flutter build ios --debug --no-codesign; then
      BUILD_IOS_SUCCESS=true
    else
      echo "Error: iOS build task failed."
    fi
  else
    echo ""
    echo "⚠ Warning: Xcode/xcodebuild not found. Skipping iOS debug build."
  fi
fi

# 3. Final Summary
echo ""
echo "=================================================="
echo " Mobile Debug Builds Summary                      "
echo "=================================================="

if [ "$BUILD_ANDROID_SUCCESS" = true ]; then
  echo " ✓ Android: SUCCESS"
  echo "   Output:  apps/mobile/build/app/outputs/flutter-apk/app-debug.apk"
else
  echo " ✗ Android: SKIPPED / FAILED"
fi

if [ "$IS_MAC" = true ]; then
  if [ "$BUILD_IOS_SUCCESS" = true ]; then
    echo " ✓ iOS:     SUCCESS"
    echo "   Output:  apps/mobile/build/ios/iphoneos/Runner.app"
  else
    echo " ✗ iOS:     SKIPPED / FAILED"
  fi
fi
echo "=================================================="

# Return error exit code if attempted builds failed
if [ "$HAS_JAVA" = true ] && [ "$BUILD_ANDROID_SUCCESS" = false ]; then
  exit 1
fi
if [ "$IS_MAC" = true ] && command -v xcodebuild >/dev/null 2>&1 && [ "$BUILD_IOS_SUCCESS" = false ]; then
  exit 1
fi
