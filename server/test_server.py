#!/usr/bin/env python3
"""
Simple test server to verify Flask is working
"""

try:
    from flask import Flask
    print("✅ Flask imported successfully")
    
    app = Flask(__name__)
    
    @app.route('/')
    def hello():
        return '<h1>🚀 Remote Command Server Test</h1><p>Flask is working!</p>'
    
    if __name__ == '__main__':
        print("🌐 Starting test server on http://localhost:5000")
        app.run(host='0.0.0.0', port=5000, debug=False)
        
except ImportError as e:
    print(f"❌ Import error: {e}")
except Exception as e:
    print(f"❌ Error: {e}")
