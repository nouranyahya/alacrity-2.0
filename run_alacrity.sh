#!/bin/bash

set -e

echo "==========================="
echo "Alacrity Assistant Launcher"
echo "==========================="
echo ""

# First, make sure any existing instances are closed to avoid conflicts
osascript -e 'tell application "Alacrity" to quit' 2>/dev/null || true
sleep 1

# Start backend in background
echo "Starting backend server..."
if [ -f ".env" ]; then
    # If already set up, just start the server
    (source venv/bin/activate && python backend/server.py) &
    BACKEND_PID=$!
    echo "Backend running with PID: $BACKEND_PID"
else
    # If not set up, run the setup script
    echo "First-time setup needed for backend. Enter API keys when prompted."
    ./start_backend.sh &
    BACKEND_PID=$!
    echo "Backend running with PID: $BACKEND_PID"
fi

# Give the backend server time to start
echo "Waiting for backend to start..."
sleep 2

# Check if app bundle exists, if not create it
APP_PATH="$PWD/Alacrity.app"
if [ ! -d "$APP_PATH" ]; then
    echo "Creating Alacrity app bundle..."
    ./create_app_bundle.sh
else
    echo "Using existing Alacrity app bundle..."
    # Launch with stronger activation
    osascript -e "tell application \"$APP_PATH\" to activate" || open -a "$APP_PATH"
    
    # Additional step to ensure it comes to foreground using a dedicated script
    sleep 1
    osascript -e '
        tell application "Alacrity"
            activate
            set visible of every window to true
        end tell
        
        tell application "System Events"
            tell process "Alacrity"
                set frontmost to true
            end tell
        end tell
    ' || true
fi

echo ""
echo "Alacrity is now running!"
echo "Backend server (PID: $BACKEND_PID) and macOS app are active."
echo "To stop the backend server when done, run: kill $BACKEND_PID"
echo ""
echo "Press Ctrl+C to close this terminal window when you're finished."

# Keep the script running to maintain the backend server
wait $BACKEND_PID 