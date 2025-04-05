#!/bin/bash

set -e

echo "==========================="
echo "Alacrity Assistant Launcher"
echo "==========================="
echo ""

# First, make sure any existing instances are closed to avoid conflicts
echo "Stopping existing Alacrity instances..."
osascript -e 'tell application "Alacrity" to quit' 2>/dev/null || true
sleep 1

# Kill any existing Python backend processes
echo "Stopping existing backend processes..."
pkill -f "python.*backend/server.py" || true
pkill -f ".*127.0.0.1:5005.*" || true
lsof -ti:5005 | xargs kill -9 2>/dev/null || true
sleep 1

# Clean up captures directory
echo "Cleaning up capture files..."
if [ -d "data/captures" ]; then
    rm -rf data/captures/*
    echo "Capture files removed."
else
    mkdir -p data/captures
    echo "Created captures directory."
fi

# Start backend server in background
echo "Starting backend server..."
cd "$(dirname "$0")"

# Ensure we activate the virtual environment
if [ -d "venv" ]; then
    source venv/bin/activate
elif [ -d "$HOME/.virtualenvs/alacrity" ]; then
    source "$HOME/.virtualenvs/alacrity/bin/activate"
else
    echo "Warning: No virtual environment found, using system Python"
fi

# Start the backend server
python backend/server.py &
BACKEND_PID=$!

# Wait a moment for backend to start
echo "Waiting for backend to initialize..."
sleep 2

# Check if the backend server is running
if ! ps -p $BACKEND_PID > /dev/null; then
    echo "Error: Backend server failed to start. Check for errors above."
    exit 1
fi

# Start frontend app
echo "Starting Alacrity app..."
if [ -d "$(pwd)/Alacrity.app" ]; then
    open "$(pwd)/Alacrity.app"
else
    echo "Error: Alacrity.app not found. Run ./create_app_bundle.sh first."
    exit 1
fi

# Bring app to foreground with AppleScript
echo "Bringing app to foreground..."
sleep 1
osascript -e '
tell application "Alacrity"
    activate
end tell
'

echo "Alacrity is running!"
echo "Backend PID: $BACKEND_PID"

echo ""
echo "Press Ctrl+C to close this terminal window when you're finished."

# Keep the script running to maintain the backend server
wait $BACKEND_PID 