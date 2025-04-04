#!/bin/bash

set -e

echo "==========================="
echo "Alacrity Assistant Launcher"
echo "==========================="
echo ""

# First, make sure any existing instances are closed to avoid conflicts
osascript -e 'tell application "Alacrity" to quit' 2>/dev/null || true
sleep 1

# Kill any existing Python backend processes
echo "Checking for existing backend processes..."
pkill -f "python.*backend/server.py" || true

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
source venv/bin/activate || source ~/.virtualenvs/alacrity/bin/activate || echo "No virtual environment found, using system Python"
python backend/server.py &
BACKEND_PID=$!

# Wait a moment for backend to start
sleep 1

# Start frontend app
echo "Starting Alacrity app..."
open "$(pwd)/Alacrity.app"

# Bring app to foreground with AppleScript
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