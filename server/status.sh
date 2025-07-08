#!/bin/bash
# Server Status Check Script

echo "🔍 Remote Command Server Status Check"
echo "====================================="

# Check if server is running
if pgrep -f "python3 app.py" > /dev/null; then
    echo "✅ Server is running"
    PID=$(pgrep -f "python3 app.py")
    echo "📊 Process ID: $PID"
else
    echo "❌ Server is not running"
fi

# Check if port 5000 is in use
if netstat -tlnp 2>/dev/null | grep -q ":5000"; then
    echo "✅ Port 5000 is in use"
    netstat -tlnp 2>/dev/null | grep ":5000"
else
    echo "❌ Port 5000 is not in use"
fi

# Test HTTP connection
echo "🌐 Testing HTTP connection..."
if curl -s http://localhost:5000/ > /dev/null; then
    echo "✅ HTTP connection successful"
else
    echo "❌ HTTP connection failed"
fi

# Check database
if [ -f "remote_commands.db" ]; then
    echo "✅ Database file exists"
    DB_SIZE=$(stat -c%s "remote_commands.db")
    echo "📊 Database size: $DB_SIZE bytes"
else
    echo "❌ Database file not found"
fi

# Check templates
if [ -f "templates/index.html" ]; then
    echo "✅ Web interface template exists"
    TEMPLATE_SIZE=$(stat -c%s "templates/index.html")
    echo "📊 Template size: $TEMPLATE_SIZE bytes"
else
    echo "❌ Web interface template not found"
fi

echo ""
echo "🚀 Quick Actions:"
echo "• Start server: ./start.sh"
echo "• Stop server: pkill -f 'python3 app.py'"
echo "• View logs: tail -f /var/log/syslog | grep python"
echo "• Web interface: http://localhost:5000"
