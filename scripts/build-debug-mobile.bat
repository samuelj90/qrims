@echo off
setlocal
pushd "%~dp0.."

echo ==================================================
echo  Building Debug Mobile Apps (Android)
echo ==================================================

where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Flutter SDK is not installed in the PATH.
    popd
    exit /b 1
)

echo --^> Syncing application configuration...
node sync_config.js

cd apps\mobile

if not exist android (
    echo --^> Platform directories missing. Generating android/ios templates...
    call flutter create --platforms=android,ios .
)

if not exist ios (
    echo --^> Platform directories missing. Generating android/ios templates...
    call flutter create --platforms=android,ios .
)

echo --^> Fetching dependencies...
call flutter pub get

echo --^> Building Android Debug APK...
call flutter build apk --debug

echo Check if build succeeded...
if not exist build\app\outputs\flutter-apk\app-debug.apk (
    echo Error: Mobile build failed!
    popd
    exit /b 1
)

echo Check completed!
echo.
echo ==================================================
echo  Mobile Debug Builds Complete!
echo  Output: apps\mobile\build\app\outputs\flutter-apk\app-debug.apk
echo ==================================================

popd
