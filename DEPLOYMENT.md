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
