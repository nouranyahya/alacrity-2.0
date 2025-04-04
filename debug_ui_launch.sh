#!/bin/bash

echo "Alacrity UI Debug Launch"
echo "======================="

cd app

# Make sure the app is built with the latest changes
echo "Building app..."
swift build

# Get the path to the built executable
EXEC_PATH=$(swift build --show-bin-path)/Alacrity

echo "Running app with GUI environment..."
# Launch with NSApplication environment variables set to ensure UI displays
env NSApplicationCrashOnExceptions=YES OBJC_DEBUG_MISSING_POOLS=YES "$EXEC_PATH" 