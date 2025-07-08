#!/usr/bin/env python3
"""
Remote Command Server - Web interface for managing remote commands
"""

from flask import Flask, render_template, request, jsonify, send_file
from flask_socketio import SocketIO, emit, join_room
import sqlite3
import hashlib
import secrets
import json
import os
import datetime
from pathlib import Path
import base64

app = Flask(__name__)
app.config['SECRET_KEY'] = secrets.token_hex(16)
socketio = SocketIO(app, cors_allowed_origins="*")

# Database setup
DB_PATH = 'remote_commands.db'

def init_db():
    """Initialize the database with required tables"""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Commands table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS commands (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            command TEXT NOT NULL,
            description TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            executed_count INTEGER DEFAULT 0
        )
    ''')
    
    # Scripts table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS scripts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            content TEXT NOT NULL,
            language TEXT DEFAULT 'bash',
            description TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # Files table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS files (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            path TEXT NOT NULL,
            content BLOB,
            size INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # Clients table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS clients (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            client_id TEXT UNIQUE NOT NULL,
            hostname TEXT,
            os_info TEXT,
            last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            status TEXT DEFAULT 'offline'
        )
    ''')
    
    # Command queue table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS command_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            client_id TEXT NOT NULL,
            command TEXT NOT NULL,
            status TEXT DEFAULT 'pending',
            result TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            executed_at TIMESTAMP
        )
    ''')
    
    # Command history table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS command_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            client_id TEXT NOT NULL,
            command TEXT NOT NULL,
            result TEXT,
            exit_code INTEGER,
            executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    conn.commit()
    conn.close()

@app.route('/')
def index():
    """Main dashboard"""
    return render_template('index.html')

@app.route('/api/commands', methods=['GET', 'POST'])
def manage_commands():
    """Manage saved commands"""
    if request.method == 'POST':
        data = request.get_json()
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        cursor.execute('''
            INSERT INTO commands (name, command, description)
            VALUES (?, ?, ?)
        ''', (data['name'], data['command'], data.get('description', '')))
        
        conn.commit()
        conn.close()
        return jsonify({'success': True})
    
    else:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        cursor.execute('SELECT * FROM commands ORDER BY created_at DESC')
        commands = cursor.fetchall()
        conn.close()
        
        return jsonify([{
            'id': cmd[0],
            'name': cmd[1],
            'command': cmd[2],
            'description': cmd[3],
            'created_at': cmd[4],
            'executed_count': cmd[5]
        } for cmd in commands])

@app.route('/api/scripts', methods=['GET', 'POST'])
def manage_scripts():
    """Manage saved scripts"""
    if request.method == 'POST':
        data = request.get_json()
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        cursor.execute('''
            INSERT INTO scripts (name, content, language, description)
            VALUES (?, ?, ?, ?)
        ''', (data['name'], data['content'], data.get('language', 'bash'), data.get('description', '')))
        
        conn.commit()
        conn.close()
        return jsonify({'success': True})
    
    else:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        cursor.execute('SELECT * FROM scripts ORDER BY created_at DESC')
        scripts = cursor.fetchall()
        conn.close()
        
        return jsonify([{
            'id': script[0],
            'name': script[1],
            'content': script[2],
            'language': script[3],
            'description': script[4],
            'created_at': script[5]
        } for script in scripts])

@app.route('/api/clients')
def get_clients():
    """Get all connected clients"""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM clients ORDER BY last_seen DESC')
    clients = cursor.fetchall()
    conn.close()
    
    return jsonify([{
        'id': client[0],
        'client_id': client[1],
        'hostname': client[2],
        'os_info': client[3],
        'last_seen': client[4],
        'status': client[5]
    } for client in clients])

@app.route('/api/execute', methods=['POST'])
def execute_command():
    """Queue a command for execution on a client"""
    data = request.get_json()
    client_id = data['client_id']
    command = data['command']
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute('''
        INSERT INTO command_queue (client_id, command)
        VALUES (?, ?)
    ''', (client_id, command))
    
    command_id = cursor.lastrowid
    conn.commit()
    conn.close()
    
    # Emit to specific client via WebSocket
    socketio.emit('execute_command', {
        'command': command,
        'id': command_id
    }, room=client_id)
    
    return jsonify({'success': True})

@app.route('/api/client/register', methods=['POST'])
def register_client():
    """Register a new client"""
    data = request.get_json()
    client_id = data['client_id']
    hostname = data.get('hostname', 'unknown')
    os_info = data.get('os_info', 'unknown')
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute('''
        INSERT OR REPLACE INTO clients (client_id, hostname, os_info, last_seen, status)
        VALUES (?, ?, ?, CURRENT_TIMESTAMP, 'online')
    ''', (client_id, hostname, os_info))
    
    conn.commit()
    conn.close()
    
    return jsonify({'success': True})

@app.route('/api/client/heartbeat', methods=['POST'])
def client_heartbeat():
    """Update client last seen time"""
    data = request.get_json()
    client_id = data['client_id']
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute('''
        UPDATE clients SET last_seen = CURRENT_TIMESTAMP, status = 'online'
        WHERE client_id = ?
    ''', (client_id,))
    
    conn.commit()
    conn.close()
    
    return jsonify({'success': True})

@app.route('/api/client/commands/<client_id>')
def get_client_commands(client_id):
    """Get pending commands for a specific client"""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute('''
        SELECT id, command FROM command_queue
        WHERE client_id = ? AND status = 'pending'
        ORDER BY created_at ASC
    ''', (client_id,))
    
    commands = cursor.fetchall()
    conn.close()
    
    return jsonify([{
        'id': cmd[0],
        'command': cmd[1]
    } for cmd in commands])

@app.route('/api/client/result', methods=['POST'])
def submit_command_result():
    """Submit command execution result"""
    data = request.get_json()
    command_id = data['command_id']
    result = data['result']
    exit_code = data.get('exit_code', 0)
    client_id = data['client_id']
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Update command queue
    cursor.execute('''
        UPDATE command_queue SET status = 'completed', result = ?, executed_at = CURRENT_TIMESTAMP
        WHERE id = ?
    ''', (result, command_id))
    
    # Add to history
    cursor.execute('''
        SELECT command FROM command_queue WHERE id = ?
    ''', (command_id,))
    
    command = cursor.fetchone()[0]
    
    cursor.execute('''
        INSERT INTO command_history (client_id, command, result, exit_code)
        VALUES (?, ?, ?, ?)
    ''', (client_id, command, result, exit_code))
    
    conn.commit()
    conn.close()
    
    # Emit result to web interface
    socketio.emit('command_result', {
        'client_id': client_id,
        'command': command,
        'result': result,
        'exit_code': exit_code
    })
    
    return jsonify({'success': True})

@app.route('/api/upload', methods=['POST'])
def upload_file():
    """Upload a file to be transferred to clients"""
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400
    
    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No file selected'}), 400
    
    content = file.read()
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute('''
        INSERT INTO files (name, path, content, size)
        VALUES (?, ?, ?, ?)
    ''', (file.filename, file.filename, content, len(content)))
    
    file_id = cursor.lastrowid
    conn.commit()
    conn.close()
    
    return jsonify({'success': True, 'file_id': file_id})

@app.route('/api/files')
def get_files():
    """Get all uploaded files"""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('SELECT id, name, path, size, created_at FROM files ORDER BY created_at DESC')
    files = cursor.fetchall()
    conn.close()
    
    return jsonify([{
        'id': file[0],
        'name': file[1],
        'path': file[2],
        'size': file[3],
        'created_at': file[4]
    } for file in files])

@app.route('/api/files/<int:file_id>')
def download_file(file_id):
    """Download a specific file"""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('SELECT name, content FROM files WHERE id = ?', (file_id,))
    file_data = cursor.fetchone()
    conn.close()
    
    if not file_data:
        return jsonify({'error': 'File not found'}), 404
    
    filename, content = file_data
    
    # Create temporary file
    temp_path = f'/tmp/{filename}'
    with open(temp_path, 'wb') as f:
        f.write(content)
    
    return send_file(temp_path, as_attachment=True, download_name=filename)

@socketio.on('connect')
def handle_connect():
    """Handle client connection"""
    print(f"Client connected: {request.sid}")

@socketio.on('disconnect')
def handle_disconnect():
    """Handle client disconnection"""
    print(f"Client disconnected: {request.sid}")

@socketio.on('join_room')
def handle_join_room(data):
    """Handle client joining a room"""
    client_id = data['client_id']
    join_room(client_id)
    print(f"Client {client_id} joined room")

if __name__ == '__main__':
    init_db()
    print("🚀 Starting Remote Command Server...")
    print("📡 Server will be available at: http://localhost:5000")
    print("🔧 Press Ctrl+C to stop the server")
    print("-" * 50)
    try:
        socketio.run(app, host='0.0.0.0', port=5000, debug=False, use_reloader=False)
    except KeyboardInterrupt:
        print("\n🛑 Server stopped by user")
    except Exception as e:
        print(f"❌ Server error: {e}")
        print("💡 Try: sudo netstat -tlnp | grep :5000  # Check if port is in use")
        print("💡 Try: sudo lsof -i :5000  # Check what's using the port")
