import os
import socket
from flask import Flask, jsonify

app = Flask(__name__)

@app.get("/")
def index():
    version = os.getenv("VERSION", "blue")
    if os.getenv("BROKEN_ROOT", "false").lower() == "true":
        return jsonify({"error": "root endpoint intentionally broken"}), 500
    return jsonify({"service": "aks-practice-app", "version": version, "hostname": socket.gethostname()})

@app.get("/healthz")
def healthz():
    return jsonify({"status": "ok"}), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
