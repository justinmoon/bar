#!/bin/bash
set -ex

# Constants
APPIUM_PORT=4723
ANDROID_PACKAGE="com.rmp.bar"
APK_PATH="$(pwd)/android/app/build/outputs/apk/debug/app-debug.apk"

# Verify APK exists
if [ ! -f "$APK_PATH" ]; then
    echo "APK not found at $APK_PATH"
    echo "Make sure to build the Android app first"
    exit 1
fi

# Check if emulator is running
if ! adb devices | grep "emulator" | grep -q "device"; then
    echo "No emulator found. Please start an emulator first."
    exit 1
fi

# Check if bun is installed
if ! command -v bun &> /dev/null; then
    echo "Bun is not installed. Make sure to use Nix develop."
    exit 1
fi

# FIXME: check if it's installed first
echo "Installing UiAutomator2 driver for Appium..."
bunx --yes appium@latest driver install uiautomator2 || true

# Check if an Appium server is already running
if lsof -i :$APPIUM_PORT &> /dev/null; then
    echo "Appium server is already running on port $APPIUM_PORT"
else
    echo "Starting Appium server..."
    # Start Appium server in background using bunx
    bunx --yes appium@latest --address 127.0.0.1 --port $APPIUM_PORT &
    
    # Save the PID to kill it later
    APPIUM_PID=$!
    
    # Wait for Appium to start
    sleep 5
    echo "Appium server started."
fi

# Run the E2E tests
echo "Running E2E tests..."
cd ui-tests
APK_PATH="$APK_PATH" cargo run

# Capture the exit code
TEST_EXIT_CODE=$?

# Kill Appium if we started it
if [ ! -z "$APPIUM_PID" ]; then
    echo "Stopping Appium server..."
    kill $APPIUM_PID
fi

# Return the test exit code
exit $TEST_EXIT_CODE
