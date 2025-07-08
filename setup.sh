#!/bin/bash
# One-Click Setup Script - Complete Remote Command System

echo "🚀 One-Click Remote Command System Setup"
echo "=========================================="

# Detect system
USER=$(whoami)
OS=$(uname -s)
CURRENT_DIR=$(pwd)

echo "👤 User: $USER"
echo "🖥️  OS: $OS"
echo "📁 Directory: $CURRENT_DIR"
echo ""

# Check if we're in the right directory
if [[ ! -f "server/app.py" || ! -f "client/ssh_client.py" ]]; then
    echo "❌ Error: Must be run from the remote commands directory"
    echo "💡 Make sure you're in the directory containing server/ and client/ folders"
    exit 1
fi

echo "🔧 Setting up permissions..."
chmod +x server/start_universal.sh
chmod +x client/install_universal.sh
chmod +x test_universal.sh

echo "🧪 Running compatibility test..."
echo "=================================="
./test_universal.sh

echo ""
echo "🎯 Setup Options:"
echo "=================="
echo "1. Start server only (for control machine)"
echo "2. Install client only (for target machine)"
echo "3. Start server and show client install instructions"
echo "4. Exit"
echo ""

read -p "Choose option (1-4): " choice

case $choice in
    1)
        echo "🖥️  Starting server..."
        cd server && ./start_universal.sh
        ;;
    2)
        echo "🥷 Installing client..."
        cd client
        
        echo "⚙️  Do you want to install system-wide (requires sudo) or user-only?"
        read -p "Install system-wide? (y/n): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo ./install_universal.sh
        else
            ./install_universal.sh
        fi
        ;;
    3)
        echo "🖥️  Starting server..."
        cd server
        
        # Start server in background
        nohup ./start_universal.sh > server.log 2>&1 &
        SERVER_PID=$!
        
        echo "⏳ Waiting for server to start..."
        sleep 5
        
        # Check if server is running
        if ps -p $SERVER_PID > /dev/null; then
            echo "✅ Server started successfully (PID: $SERVER_PID)"
            echo "📝 Server logs: server/server.log"
            echo ""
        else
            echo "❌ Server failed to start. Check server/server.log for errors."
            exit 1
        fi
        
        # Get server IP
        LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "YOUR_SERVER_IP")
        
        echo "🌐 Server is running at:"
        echo "   • Local: http://localhost:5000"
        echo "   • Network: http://$LOCAL_IP:5000"
        echo ""
        
        echo "🥷 To install client on target machines:"
        echo "=========================================="
        echo "1. Copy client files to target machine:"
        echo "   scp -r client/ user@target-machine:/tmp/"
        echo ""
        echo "2. On target machine, run:"
        echo "   cd /tmp/client/"
        echo "   sudo ./install_universal.sh"
        echo ""
        echo "3. Update server URL in config:"
        echo "   sudo nano /usr/share/ssh-client/config.py"
        echo "   # Change SERVER_URL to: http://$LOCAL_IP:5000"
        echo ""
        echo "4. Restart client service:"
        echo "   sudo systemctl restart ssh-client.service"
        echo ""
        echo "✅ Setup complete! Press Ctrl+C to stop server when done."
        
        # Keep script running
        wait $SERVER_PID
        ;;
    4)
        echo "👋 Exiting..."
        exit 0
        ;;
    *)
        echo "❌ Invalid option"
        exit 1
        ;;
esac
