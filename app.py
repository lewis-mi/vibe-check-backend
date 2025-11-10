from flask import Flask
from flask_cors import CORS

app = Flask(__name__)

# Enable CORS for your frontend domains
CORS(app, resources={r"/*": {"origins": [
    "https://vibechecklab.app",
    "https://www.vibechecklab.app"
]}})

@app.get("/health")
def health():
    return {"ok": True}

# Your other routes (e.g., /analyze) go below here
@app.post("/analyze")
def analyze():
    # your logic here
    return {"status": "analyzed"}
