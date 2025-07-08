# Remote Command System Configuration

# Server Configuration
SERVER_HOST = "0.0.0.0"  # Listen on all interfaces
SERVER_PORT = 5000
SERVER_URL = "http://YOUR_SERVER_IP:5000"  # Change this to your server's IP

# Database Configuration
DATABASE_PATH = "remote_commands.db"

# Security Configuration
SECRET_KEY = "your-secret-key-here"  # Change this in production
ALLOWED_ORIGINS = ["*"]  # Restrict in production

# Client Configuration
HEARTBEAT_INTERVAL = 30  # seconds
COMMAND_CHECK_INTERVAL = 5  # seconds

# SSH Disguise Configuration
SSH_BANNER_ENABLED = True
FAKE_SSH_VERSION = "OpenSSH_8.9p1 Ubuntu-3ubuntu0.1"

# Logging Configuration
LOG_LEVEL = "INFO"
LOG_FILE = "remote_commands.log"
