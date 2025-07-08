#!/bin/bash
# Universal Test Script - Works on any system

echo "🧪 Universal Remote Command System Test"
echo "========================================"

# Detect system information
OS=$(uname -s)
DISTRO=$(lsb_release -si 2>/dev/null || echo "Unknown")
USER=$(whoami)
HOME_DIR=$(eval echo ~$USER)
PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null || echo "Unknown")

echo "🔍 System Information:"
echo "   • OS: $OS"
echo "   • Distribution: $DISTRO"
echo "   • User: $USER"
echo "   • Home: $HOME_DIR"
echo "   • Python: $PYTHON_VERSION"
echo ""

# Test Python availability
echo "🐍 Python Environment Test:"
if command -v python3 &> /dev/null; then
    echo "   ✅ Python 3 is available"
    PYTHON_PATH=$(which python3)
    echo "   📍 Location: $PYTHON_PATH"
else
    echo "   ❌ Python 3 is not available"
    echo "   💡 Install with your package manager:"
    if command -v apt &> /dev/null; then
        echo "      sudo apt install python3 python3-pip"
    elif command -v yum &> /dev/null; then
        echo "      sudo yum install python3 python3-pip"
    elif command -v pacman &> /dev/null; then
        echo "      sudo pacman -S python python-pip"
    fi
fi

# Test pip availability
if command -v pip3 &> /dev/null; then
    echo "   ✅ pip3 is available"
else
    echo "   ❌ pip3 is not available"
fi

# Test virtual environment
echo ""
echo "📦 Virtual Environment Test:"
if python3 -m venv test_venv 2>/dev/null; then
    echo "   ✅ Virtual environment creation works"
    rm -rf test_venv
else
    echo "   ❌ Virtual environment creation failed"
    echo "   💡 Install venv module:"
    if command -v apt &> /dev/null; then
        echo "      sudo apt install python3-venv"
    fi
fi

# Test network connectivity
echo ""
echo "🌐 Network Test:"
if ping -c 1 google.com &> /dev/null; then
    echo "   ✅ Internet connectivity available"
else
    echo "   ❌ No internet connectivity"
    echo "   💡 Check your network connection"
fi

# Test server files
echo ""
echo "📁 Server Files Test:"
if [ -f "server/app.py" ]; then
    echo "   ✅ Server application found"
else
    echo "   ❌ Server application not found"
fi

if [ -f "server/templates/index.html" ]; then
    echo "   ✅ Web interface template found"
else
    echo "   ❌ Web interface template not found"
fi

if [ -f "server/start_universal.sh" ]; then
    echo "   ✅ Universal server startup script found"
    if [ -x "server/start_universal.sh" ]; then
        echo "   ✅ Script is executable"
    else
        echo "   ❌ Script is not executable"
        echo "   💡 Run: chmod +x server/start_universal.sh"
    fi
else
    echo "   ❌ Universal server startup script not found"
fi

# Test client files
echo ""
echo "🥷 Client Files Test:"
if [ -f "client/ssh_client.py" ]; then
    echo "   ✅ Client script found"
else
    echo "   ❌ Client script not found"
fi

if [ -f "client/install_universal.sh" ]; then
    echo "   ✅ Universal client installer found"
    if [ -x "client/install_universal.sh" ]; then
        echo "   ✅ Script is executable"
    else
        echo "   ❌ Script is not executable"
        echo "   💡 Run: chmod +x client/install_universal.sh"
    fi
else
    echo "   ❌ Universal client installer not found"
fi

# Test package manager
echo ""
echo "📦 Package Manager Test:"
if command -v apt &> /dev/null; then
    echo "   ✅ apt (Debian/Ubuntu) detected"
    PKG_MANAGER="apt"
elif command -v yum &> /dev/null; then
    echo "   ✅ yum (RHEL/CentOS) detected"
    PKG_MANAGER="yum"
elif command -v pacman &> /dev/null; then
    echo "   ✅ pacman (Arch Linux) detected"
    PKG_MANAGER="pacman"
elif command -v brew &> /dev/null; then
    echo "   ✅ brew (macOS) detected"
    PKG_MANAGER="brew"
else
    echo "   ❌ No supported package manager found"
    PKG_MANAGER="unknown"
fi

# Test permissions
echo ""
echo "🔒 Permissions Test:"
if [ -w "." ]; then
    echo "   ✅ Current directory is writable"
else
    echo "   ❌ Current directory is not writable"
fi

if [ "$USER" = "root" ]; then
    echo "   ⚠️  Running as root (not recommended for regular use)"
else
    echo "   ✅ Running as regular user"
fi

# Test ports
echo ""
echo "🔌 Port Test:"
if command -v netstat &> /dev/null; then
    if netstat -tlnp 2>/dev/null | grep -q ":5000"; then
        echo "   ⚠️  Port 5000 is already in use"
        netstat -tlnp 2>/dev/null | grep ":5000"
    else
        echo "   ✅ Port 5000 is available"
    fi
else
    echo "   ⚠️  netstat not available, cannot check port 5000"
fi

# Generate installation commands
echo ""
echo "🚀 Installation Commands:"
echo "=========================================="
echo "📍 Current directory: $(pwd)"
echo ""
echo "🖥️  Server (run this on your control machine):"
echo "   cd server && ./start_universal.sh"
echo ""
echo "🥷 Client (run this on target machines):"
echo "   cd client && sudo ./install_universal.sh"
echo "   # Or for user-only install:"
echo "   cd client && ./install_universal.sh"
echo ""
echo "🌐 Access web interface at:"
echo "   http://localhost:5000"
echo ""
echo "✅ Test completed!"
echo "💡 If any tests failed, fix the issues before proceeding."
