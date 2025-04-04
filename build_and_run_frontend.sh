#!/bin/bash

set -e

echo "Alacrity Frontend Build & Run"
echo "============================"

# Check if Swift is installed
if ! command -v swift &> /dev/null; then
    echo "Swift is not installed. Please install Swift from https://swift.org/download/"
    exit 1
fi

echo "Building Alacrity frontend..."
cd app

# Clean any previous build artifacts
echo "Cleaning previous build..."
swift package clean

# Build the package
echo "Building Swift package..."
swift build

if [ $? -eq 0 ]; then
    echo "Build successful!"
    
    # Run the application
    echo "Running Alacrity..."
    echo "NOTE: The backend server should be running in another terminal."
    echo "Press Ctrl+C to exit the application."
    echo ""
    swift run
else
    echo "Build failed."
    exit 1
fi 