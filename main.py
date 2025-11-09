import os
import json
from flask import Flask, request, jsonify
from flask_cors import CORS, cross_origin
import google.generativeai as genai

# --- 1. Configuration ---

# Initialize Flask app
app = Flask(__name__)

# Enable CORS (Cross-Origin Resource Sharing)
CORS(app)

# Configure the Gemini API
try:
    genai.configure(api_key=os.environ.get("GEMINI_API_KEY"))
    model = genai.GenerativeModel('gemini-1.5-flash-latest') # Using Flash for speed
except AttributeError:
    print("ERROR: GEMINI_API_KEY environment variable not set.")
    exit()

# --- 2. The AI System Prompt ---

# This is our perfected AI Analyst Prompt
AI_SYSTEM_PROMPT = """
You are 'Vibe Check Lab,' an expert AI Conversation Analyst.
... (Your full prompt goes here) ...
```json
{
  "dashboardMetrics": {
... (Your full JSON schema goes here) ...
  }
}
"""

# --- 3. The "Analyze" Endpoint (The "Door") ---
# This MUST be defined *before* you run the app.

@app.route('/analyze', methods=['POST'])
@cross_origin() # This is a good extra layer for CORS
def analyze_transcript():
    
    # 1. Get the transcript from the frontend's request
    try:
        data = request.json
        transcript = data['transcript']
    except Exception as e:
        # Handle cases where the data is missing or malformed
        print(f"ERROR: Bad request: {e}")
        return jsonify({"error": "Invalid request. 'transcript' key missing."}), 400

    # 2. Build the final prompt for the AI
    full_prompt = f"""
{AI_SYSTEM_PROMPT}

Here is the transcript you must analyze:
---
{transcript}
---
"""

    # 3. Send to Gemini and get the JSON response
    try:
        response = model.generate_content(full_prompt)
        
        # This is a simple way to clean the AI's output
        # to ensure it's valid JSON
        json_text = response.text.strip().replace("```json", "").replace("```", "")
        
        # This is CRITICAL: We validate and send the AI's
        # JSON *directly* to our frontend.
        parsed_json = json.loads(json_text)
        return jsonify(parsed_json), 200

    except Exception as e:
        # Handle errors from the AI (e.g., safety blocks, API errors)
        print(f"ERROR: Gemini generation failed: {e}")
        return jsonify({"error": f"AI analysis failed. {e}"}), 500


# --- 4. Run the App (The "Engine") ---
# This MUST be the *very last* thing in your file.

if __name__ == '__main__':
    # This line gets the port from Cloud Run's $PORT variable.
    # It defaults to 8080 if $PORT isn't set (for local testing).
    port = int(os.environ.get("PORT", 8080))
    
    # This tells the server to listen on all public IPs (0.0.0.0)
    # and use the correct port. This is required for Cloud Run.
    app.run(debug=True, host='0.0.0.0', port=port)