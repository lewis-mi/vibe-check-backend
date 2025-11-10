from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)

# Allow requests only from your frontend
CORS(app, resources={r"/*": {"origins": [
    "https://vibechecklab.app",
    "https://www.vibechecklab.app",
    "http://localhost:5173"  # Optional, for local dev
]}})

@app
