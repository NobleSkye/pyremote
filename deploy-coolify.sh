#!/bin/bash
# Coolify Deployment Script

echo "🚀 Preparing Remote Command Server for Coolify Deployment"
echo "=========================================================="

# Check if we're in the right directory
if [[ ! -f "docker-compose.yml" || ! -f "Dockerfile" ]]; then
    echo "❌ Error: Must be run from the remote commands directory"
    echo "💡 Make sure docker-compose.yml and Dockerfile exist"
    exit 1
fi

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p data logs server/static

# Set permissions
echo "🔧 Setting permissions..."
chmod 755 data logs server/static

# Create .env file for local development
echo "⚙️  Creating .env file..."
cat > .env << EOF
FLASK_ENV=production
FLASK_DEBUG=false
FLASK_HOST=0.0.0.0
FLASK_PORT=5000
DB_PATH=/app/data/remote_commands.db
LOG_FILE=/app/logs/app.log
EOF

# Create docker-compose.override.yml for local development
echo "🔧 Creating docker-compose.override.yml..."
cat > docker-compose.override.yml << EOF
version: '3.8'

services:
  remote-command-server:
    environment:
      - FLASK_ENV=development
      - FLASK_DEBUG=true
    ports:
      - "5000:5000"
    volumes:
      - ./data:/app/data
      - ./logs:/app/logs
EOF

# Create .dockerignore
echo "📝 Creating .dockerignore..."
cat > .dockerignore << EOF
.git
.gitignore
*.md
*.log
data/
logs/
venv/
__pycache__/
*.pyc
*.pyo
*.pyd
.env
.venv
node_modules/
.DS_Store
Thumbs.db
*.tmp
*.temp
client/
test_*
demo.sh
setup.sh
EOF

# Create a health check endpoint
echo "🏥 Adding health check..."
cat >> server/app.py << 'EOF'

@app.route('/health')
def health_check():
    """Health check endpoint for Docker/Coolify"""
    try:
        # Check database connection
        conn = sqlite3.connect(DB_PATH)
        conn.execute('SELECT 1')
        conn.close()
        
        return jsonify({
            'status': 'healthy',
            'timestamp': datetime.datetime.now().isoformat(),
            'database': 'connected'
        }), 200
    except Exception as e:
        return jsonify({
            'status': 'unhealthy',
            'error': str(e),
            'timestamp': datetime.datetime.now().isoformat()
        }), 500
EOF

# Test Docker build
echo "🔨 Testing Docker build..."
if command -v docker &> /dev/null; then
    if docker build -t remote-command-server-test . > /dev/null 2>&1; then
        echo "✅ Docker build successful"
        docker rmi remote-command-server-test > /dev/null 2>&1
    else
        echo "❌ Docker build failed"
        echo "💡 Check Dockerfile and requirements"
        exit 1
    fi
else
    echo "⚠️  Docker not installed, skipping build test"
    echo "💡 Install Docker to test build locally"
fi

# Create deployment instructions
echo "📋 Creating deployment instructions..."
cat > DEPLOYMENT.md << 'EOF'
# Coolify Deployment Instructions

## Quick Deploy to Coolify

1. **Push to Git Repository**
   ```bash
   git add .
   git commit -m "Add Coolify deployment"
   git push origin main
   ```

2. **In Coolify Dashboard**
   - Create new application
   - Choose "Docker Compose" type
   - Connect your Git repository
   - Set domain name (e.g., `remote-command.yourdomain.com`)
   - Deploy

3. **Environment Variables (Optional)**
   ```
   FLASK_ENV=production
   FLASK_DEBUG=false
   FLASK_HOST=0.0.0.0
   FLASK_PORT=5000
   DB_PATH=/app/data/remote_commands.db
   LOG_FILE=/app/logs/app.log
   ```

## Local Development

1. **Run with Docker Compose**
   ```bash
   docker-compose up -d
   ```

2. **Access locally**
   - http://localhost:5000

3. **View logs**
   ```bash
   docker-compose logs -f
   ```

## Production Configuration

- Database persists in `/app/data/`
- Logs stored in `/app/logs/`
- Health check available at `/health`
- SSL/TLS handled by Coolify's Traefik

## Scaling

The application can be scaled horizontally by running multiple instances behind a load balancer. Make sure to use a shared database solution for production scaling.
EOF

echo ""
echo "✅ Coolify deployment preparation complete!"
echo "=========================================="
echo ""
echo "📋 Next steps:"
echo "1. Update domain in docker-compose.yml (line 22)"
echo "2. Push to Git repository"
echo "3. Deploy in Coolify dashboard"
echo "4. Access your deployment at your configured domain"
echo ""
echo "🔧 Files created:"
echo "   • docker-compose.yml"
echo "   • Dockerfile"
echo "   • coolify.json"
echo "   • .env"
echo "   • .dockerignore"
echo "   • DEPLOYMENT.md"
echo ""
echo "🌐 Local testing: docker-compose up -d"
echo "📊 Health check: http://localhost:5000/health"
