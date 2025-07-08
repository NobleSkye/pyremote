#!/bin/bash
# Universal Server Startup Script - Works on any system

echo "🚀 Starting Remote Command Server..."
echo "====================================="

# Get current user and system info
CURRENT_USER=$(whoami)
CURRENT_HOME=$(eval echo ~$CURRENT_USER)
PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null || echo "3.10")

echo "👤 Running as: $CURRENT_USER"
echo "🏠 Home directory: $CURRENT_HOME"
echo "🐍 Python version: $PYTHON_VERSION"

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3 first."
    if command -v apt &> /dev/null; then
        echo "💡 Try: sudo apt update && sudo apt install python3 python3-pip"
    elif command -v yum &> /dev/null; then
        echo "💡 Try: sudo yum install python3 python3-pip"
    elif command -v brew &> /dev/null; then
        echo "💡 Try: brew install python3"
    fi
    exit 1
fi

# Kill any existing processes on port 5000
echo "🔍 Checking for existing processes on port 5000..."
if command -v lsof &> /dev/null; then
    EXISTING_PID=$(lsof -ti:5000 2>/dev/null)
    if [ ! -z "$EXISTING_PID" ]; then
        echo "⚠️  Found existing process on port 5000 (PID: $EXISTING_PID)"
        echo "🛑 Terminating existing process..."
        kill -9 $EXISTING_PID 2>/dev/null
        sleep 2
    fi
else
    echo "⚠️  lsof not available, skipping port check"
fi

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
    if [ $? -ne 0 ]; then
        echo "❌ Failed to create virtual environment"
        echo "💡 Trying without virtual environment..."
        USE_VENV=false
    else
        USE_VENV=true
    fi
else
    USE_VENV=true
fi

# Activate virtual environment if available
if [ "$USE_VENV" = true ]; then
    echo "⚡ Activating virtual environment..."
    source venv/bin/activate
    PYTHON_CMD="python"
    PIP_CMD="pip"
else
    echo "⚡ Using system Python..."
    PYTHON_CMD="python3"
    PIP_CMD="pip3"
fi

# Install dependencies
echo "📋 Installing dependencies..."
$PIP_CMD install flask flask-socketio eventlet requests --quiet --disable-pip-version-check

# Check if installation was successful
if ! $PYTHON_CMD -c "import flask" 2>/dev/null; then
    echo "❌ Failed to install Flask. Trying alternative methods..."
    
    # Try with --user flag
    echo "📦 Trying user installation..."
    $PIP_CMD install --user flask flask-socketio eventlet requests --quiet --disable-pip-version-check
    
    # Set Python path to include user packages
    USER_SITE=$($PYTHON_CMD -c "import site; print(site.USER_SITE)" 2>/dev/null)
    if [ ! -z "$USER_SITE" ]; then
        export PYTHONPATH="$USER_SITE:$PYTHONPATH"
        echo "🔧 Added user site packages to Python path: $USER_SITE"
    fi
    
    # Try one more time
    if ! $PYTHON_CMD -c "import flask" 2>/dev/null; then
        echo "❌ Still cannot import Flask. Please install manually:"
        echo "💡 Try: pip3 install --user flask flask-socketio eventlet requests"
        exit 1
    fi
fi

echo "✅ Dependencies installed successfully"

# Create necessary directories
mkdir -p templates static

# Check if templates exist
if [ ! -f "templates/index.html" ]; then
    echo "❌ Web interface template not found!"
    echo "💡 Make sure templates/index.html exists"
    exit 1
fi

# Detect system IP addresses
LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "127.0.0.1")
echo "🌐 Server will be accessible at:"
echo "   • Local: http://localhost:5000"
echo "   • Network: http://$LOCAL_IP:5000"

# Start the server
echo "🔧 Press Ctrl+C to stop the server"
echo "====================================="
exec $PYTHON_CMD app.py
