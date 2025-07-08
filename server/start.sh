#!/bin/bash
# Server Startup Script

echo "🚀 Starting Remote Command Server..."
echo "====================================="

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3 first."
    exit 1
fi

# Kill any existing processes on port 5000
echo "🔍 Checking for existing processes on port 5000..."
EXISTING_PID=$(lsof -ti:5000 2>/dev/null)
if [ ! -z "$EXISTING_PID" ]; then
    echo "⚠️  Found existing process on port 5000 (PID: $EXISTING_PID)"
    echo "🛑 Terminating existing process..."
    kill -9 $EXISTING_PID 2>/dev/null
    sleep 2
fi

# Install dependencies if not present
echo "� Checking dependencies..."
python3 -c "import flask" 2>/dev/null || {
    echo "� Installing Flask..."
    pip3 install flask flask-socketio eventlet requests
}

# Create necessary directories
mkdir -p templates static

# Check if templates exist
if [ ! -f "templates/index.html" ]; then
    echo "❌ Web interface template not found!"
    echo "💡 Make sure templates/index.html exists"
    exit 1
fi

# Set Python path to include user packages
export PYTHONPATH=/home/skye/.local/lib/python3.10/site-packages:$PYTHONPATH

# Start the server
echo "🌐 Starting server on http://localhost:5000"
echo "🔧 Press Ctrl+C to stop the server"
echo "====================================="
python3 app.py
