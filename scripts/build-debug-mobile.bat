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

:: Check for Java
where java >nul 2>&1
if %errorlevel% equ 0 (
    java -version >nul 2>&1
    if %errorlevel% neq 0 (
        set HAS_JAVA=false
    ) else (
        set HAS_JAVA=true
    )
) else (
    set HAS_JAVA=false
)

if "%HAS_JAVA%"=="true" (
    echo --^> Building Android Debug APK...
    call flutter build apk --debug

    if not exist build\app\outputs\flutter-apk\app-debug.apk (
        echo Error: Mobile build failed!
        popd
        exit /b 1
    )

    echo.
    echo ==================================================
    echo  Mobile Debug Builds Complete!
    echo  Output: apps\mobile\build\app\outputs\flutter-apk\app-debug.apk
    echo ==================================================
) else (
    echo.
    echo ==================================================
    echo  Warning: Java Runtime (JDK) not found.
    echo  Android compilation requires a valid Java Runtime.
    echo  Please install the JDK (e.g. from https://adoptium.net/).
    echo ==================================================
)

popd
