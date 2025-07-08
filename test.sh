#!/bin/bash
# Test Script for Remote Command System

echo "🚀 Testing Remote Command System"
echo "================================="

# Test server directory
echo "📁 Checking server files..."
if [ -f "server/app.py" ]; then
    echo "✅ Server application found"
else
    echo "❌ Server application not found"
fi

if [ -f "server/templates/index.html" ]; then
    echo "✅ Web interface found"
else
    echo "❌ Web interface not found"
fi

# Test client directory
echo "📁 Checking client files..."
if [ -f "client/ssh_client.py" ]; then
    echo "✅ Client script found"
else
    echo "❌ Client script not found"
fi

if [ -f "client/install.sh" ]; then
    echo "✅ Client installer found"
else
    echo "❌ Client installer not found"
fi

# Check permissions
echo "🔒 Checking permissions..."
if [ -x "server/start.sh" ]; then
    echo "✅ Server startup script is executable"
else
    echo "❌ Server startup script is not executable"
fi

if [ -x "client/install.sh" ]; then
    echo "✅ Client installer is executable"
else
    echo "❌ Client installer is not executable"
fi

# Test Python dependencies
echo "🐍 Checking Python dependencies..."
python3 -c "import flask" 2>/dev/null && echo "✅ Flask available" || echo "❌ Flask not available"
python3 -c "import requests" 2>/dev/null && echo "✅ Requests available" || echo "❌ Requests not available"

echo ""
echo "📋 Quick Start:"
echo "1. cd server && ./start.sh"
echo "2. Open http://localhost:5000 in browser"
echo "3. On target machine: cd client && sudo ./install.sh"
echo ""
echo "✅ System ready for deployment!"
