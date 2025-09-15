#!/usr/bin/env python3
"""
Simple HTTP server to serve infrastructure documentation and configuration files.
This server provides a web interface to browse the shared infrastructure repository.
"""

import os
import http.server
import socketserver
from pathlib import Path

class InfraHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=".", **kwargs)
    
    def end_headers(self):
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

def main():
    PORT = 5000
    Handler = InfraHandler
    
    with socketserver.TCPServer(("0.0.0.0", PORT), Handler) as httpd:
        print(f"🚀 Infrastructure Documentation Server running at http://localhost:{PORT}")
        print("📁 Browse the shared infrastructure repository structure")
        print("📖 Access README.md and configuration files through the web interface")
        print("🔧 Use this server to explore the complete DevOps setup")
        httpd.serve_forever()

if __name__ == "__main__":
    main()