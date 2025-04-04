#!/bin/bash

set -e

echo "Alacrity Backend Setup"
echo "======================"

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv || { echo "Failed to create virtual environment. Make sure python3 and venv are installed."; exit 1; }
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate || { echo "Failed to activate virtual environment."; exit 1; }

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip || echo "Warning: Could not upgrade pip, continuing anyway..."

# Install requirements
echo "Installing Python dependencies..."
pip install -r backend/requirements.txt || { echo "Failed to install dependencies. Check backend/requirements.txt."; exit 1; }

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "Creating .env file from example..."
    cp .env.example .env || { echo "Failed to create .env file."; exit 1; }
    echo ""
    echo "IMPORTANT: Please edit .env file to add your API keys before continuing"
    echo "OpenAI API key: Get from https://platform.openai.com/api-keys"
    echo "Google API key: Get from https://makersuite.google.com/app/apikey"
    echo ""
    read -p "Would you like to edit the .env file now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ${EDITOR:-vi} .env
    else
        echo "Please edit the .env file before running this script again."
        exit 0
    fi
fi

# Create data directory if it doesn't exist
echo "Creating data directories..."
mkdir -p data/captures

# Start the server
echo ""
echo "Starting Alacrity backend server..."
echo "Press Ctrl+C to stop the server"
echo ""
python backend/server.py 