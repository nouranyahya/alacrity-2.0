#!/bin/bash

set -e

echo "Alacrity - AI Assistant"
echo "======================="
echo ""

# Set project directory
PROJECT_DIR="$(dirname "$(realpath "$0")")"
cd "$PROJECT_DIR"

# Create required directories
mkdir -p data/captures 2>/dev/null || true

# Setup Python environment if needed
if [ ! -d "venv" ]; then
    echo "First-time setup: Creating Python virtual environment..."
    python3 -m venv venv || { echo "Error: Failed to create virtual environment. Please install Python 3.9+"; exit 1; }
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r backend/requirements.txt
    
    # Create .env if it doesn't exist
    if [ ! -f ".env" ]; then
        cp .env.example .env
        echo "Created .env file. Please edit it with your API keys."
        ${EDITOR:-vi} .env
    fi
else
    source venv/bin/activate
fi

# Start backend server in the background
echo "Starting backend server..."
python backend/server.py &
BACKEND_PID=$!

# Wait for backend to initialize
echo "Waiting for backend to initialize..."
sleep 2

# Build and run the frontend
echo "Building and starting Alacrity..."
cd app
swift build && swift run

# Clean up when the app is closed
echo "Shutting down backend server..."
kill $BACKEND_PID 2>/dev/null || true
echo "Alacrity closed. Thanks for using!" 