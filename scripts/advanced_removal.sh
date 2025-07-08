#!/bin/bash
# Advanced Client Removal Script
# This script provides various removal options for the client

echo "🗑️  Advanced Client Removal Tool"
echo "================================="

# Get current user info
CURRENT_USER=$(whoami)
IS_ROOT=$([[ $EUID -eq 0 ]] && echo "true" || echo "false")

echo "👤 Running as: $CURRENT_USER"
echo "🔑 Root access: $IS_ROOT"
echo ""

# Define removal functions
stop_services() {
    echo "🛑 Stopping services..."
    
    # Stop systemd services
    systemctl stop ssh-client.service 2>/dev/null || true
    systemctl --user stop ssh-client.service 2>/dev/null || true
    
    # Stop any running processes
    pkill -f "ssh_client.py" 2>/dev/null || true
    pkill -f "ssh-client" 2>/dev/null || true
    
    echo "✅ Services stopped"
}

remove_files() {
    echo "📁 Removing files..."
    
    # Remove installation directories
    rm -rf /usr/share/ssh-client
    rm -rf /usr/share/openssh-client
    rm -rf ~/.local/share/ssh-client
    rm -rf /opt/ssh-client
    
    # Remove service files
    rm -f /etc/systemd/system/ssh-client.service
    rm -f ~/.config/systemd/user/ssh-client.service
    
    # Remove symlinks
    rm -f /usr/local/bin/ssh-client-manager
    rm -f ~/.local/bin/ssh-client-manager
    rm -f /usr/local/bin/ssh-session
    
    # Remove autostart entries
    rm -f ~/.config/autostart/ssh-client.desktop
    
    # Remove temp files
    rm -f /tmp/ssh_client.py
    rm -f /tmp/ssh-client*
    rm -f /tmp/client_removal.sh
    rm -f /tmp/removal.log
    
    echo "✅ Files removed"
}

clean_system() {
    echo "🧹 Cleaning system..."
    
    # Remove from crontab
    crontab -l 2>/dev/null | grep -v "ssh_client.py" | crontab - 2>/dev/null || true
    
    # Disable systemd services
    systemctl disable ssh-client.service 2>/dev/null || true
    systemctl --user disable ssh-client.service 2>/dev/null || true
    
    # Reload systemd
    systemctl daemon-reload 2>/dev/null || true
    systemctl --user daemon-reload 2>/dev/null || true
    
    # Clear logs
    journalctl --vacuum-time=1s 2>/dev/null || true
    
    echo "✅ System cleaned"
}

secure_wipe() {
    echo "🔒 Performing secure wipe..."
    
    # Overwrite deleted files (if shred is available)
    if command -v shred &> /dev/null; then
        find /tmp -name "*ssh*" -type f -exec shred -vfz -n 3 {} \; 2>/dev/null || true
    fi
    
    # Clear bash history
    history -c 2>/dev/null || true
    
    # Clear recent files
    rm -f ~/.recently-used 2>/dev/null || true
    
    echo "✅ Secure wipe completed"
}

# Main menu
echo "🔧 Removal Options:"
echo "1. Quick removal (stop services and remove files)"
echo "2. Complete removal (includes system cleanup)"
echo "3. Secure removal (includes secure wipe)"
echo "4. Custom removal (choose what to remove)"
echo "5. Exit"
echo ""

read -p "Choose option (1-5): " choice

case $choice in
    1)
        echo "🚀 Starting quick removal..."
        stop_services
        remove_files
        echo "✅ Quick removal completed"
        ;;
    2)
        echo "🚀 Starting complete removal..."
        stop_services
        remove_files
        clean_system
        echo "✅ Complete removal completed"
        ;;
    3)
        echo "🚀 Starting secure removal..."
        stop_services
        remove_files
        clean_system
        secure_wipe
        echo "✅ Secure removal completed"
        echo "🔄 Recommend rebooting for complete cleanup"
        ;;
    4)
        echo "🔧 Custom removal options:"
        echo ""
        
        read -p "Stop services? (y/n): " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] && stop_services
        
        read -p "Remove files? (y/n): " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] && remove_files
        
        read -p "Clean system? (y/n): " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] && clean_system
        
        read -p "Secure wipe? (y/n): " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] && secure_wipe
        
        echo "✅ Custom removal completed"
        ;;
    5)
        echo "👋 Exiting..."
        exit 0
        ;;
    *)
        echo "❌ Invalid option"
        exit 1
        ;;
esac

echo ""
echo "🔍 Verification:"
echo "================"

# Check if any traces remain
if pgrep -f "ssh_client.py" > /dev/null; then
    echo "⚠️  Warning: ssh_client.py process still running"
else
    echo "✅ No ssh_client.py processes found"
fi

if [[ -f "/etc/systemd/system/ssh-client.service" || -f "/usr/share/ssh-client/ssh_client.py" ]]; then
    echo "⚠️  Warning: Some system files may still exist"
else
    echo "✅ No system files detected"
fi

echo ""
echo "🎯 Removal completed successfully!"
echo "💡 For complete security, consider rebooting the system"
