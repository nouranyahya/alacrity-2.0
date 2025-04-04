#!/bin/bash

set -e

echo "Alacrity Launcher"
echo "================="
echo ""

# Start backend in background
echo "Starting backend server..."
if [ -f ".env" ]; then
    # If already set up, just start the server
    (cd "$(dirname "$0")" && source venv/bin/activate && python backend/server.py) &
    BACKEND_PID=$!
    echo "Backend running with PID: $BACKEND_PID"
else
    # If not set up, run the setup script
    echo "First-time setup needed. Running setup script..."
    ./start_backend.sh &
    BACKEND_PID=$!
    echo "Backend running with PID: $BACKEND_PID"
fi

# Give the backend server time to start
echo "Waiting for backend to start..."
sleep 3

# Build and run the frontend
echo ""
echo "Starting frontend..."
cd "$(dirname "$0")/app"

# Build the package if needed
if [ ! -d ".build" ]; then
    echo "Building frontend for the first time..."
    swift build
fi

# Run the application
echo "Running Alacrity frontend..."
swift run

# Clean up
echo ""
echo "Shutting down backend server..."
kill $BACKEND_PID

echo "Alacrity has been stopped." 