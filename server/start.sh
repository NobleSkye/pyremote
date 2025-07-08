#!/bin/bash
# Server Startup Script

echo "Starting Remote Command Server..."

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install dependencies
echo "Installing dependencies..."
pip install -r requirements.txt

# Create necessary directories
mkdir -p templates static

# Start the server
echo "Starting server on http://localhost:5000"
python3 app.py
