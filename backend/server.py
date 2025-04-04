import os
import sys
import json
import openai
import base64
import google.generativeai as genai
from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configure API keys
openai.api_key = os.getenv("OPENAI_API_KEY")
google_api_key = os.getenv("GOOGLE_API_KEY")

# Configure Google Gemini API
if google_api_key:
    genai.configure(api_key=google_api_key)

# Initialize Flask app
app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Global conversation state
conversation_history = []
academic_mode = False

# Print configuration info
print(f"API Keys configured: OpenAI: {'Yes' if openai.api_key else 'No'}, Google: {'Yes' if google_api_key else 'No'}")

@app.route('/chat', methods=['POST'])
def chat():
    global conversation_history
    
    data = request.json
    user_message = data.get('message', '')
    context = data.get('context', '')
    
    # Extract text from context with Google Gemini if available
    context_for_openai = ""
    if context and google_api_key:
        try:
            model = genai.GenerativeModel('gemini-pro')
            screen_context = extract_text_with_gemini(context)
            context_for_openai = f"SCREEN CONTEXT:\n{screen_context}\n\nUSER QUERY: {user_message}"
        except Exception as e:
            print(f"Error processing context with Gemini: {e}")
            context_for_openai = f"USER QUERY: {user_message}"
    else:
        context_for_openai = user_message
    
    # Add user message to history
    conversation_history.append({"role": "user", "content": context_for_openai})
    
    # Generate response using the appropriate model
    model_name = "gpt-3.5-turbo" if academic_mode else "gpt-4o-mini"
    
    try:
        response = openai.ChatCompletion.create(
            model=model_name,
            messages=conversation_history,
            temperature=0.7,
            max_tokens=1000
        )
        
        # Extract and add assistant response to history
        assistant_response = response.choices[0].message.content
        conversation_history.append({"role": "assistant", "content": assistant_response})
        
        # Keep conversation history limited to last 10 exchanges
        if len(conversation_history) > 20:
            conversation_history = conversation_history[-20:]
        
        return jsonify({
            "response": assistant_response,
            "model": model_name,
            "academic_mode": academic_mode
        })
    
    except Exception as e:
        print(f"Error calling OpenAI API: {e}")
        return jsonify({"error": str(e)}), 500

def extract_text_with_gemini(context_text):
    """Extract text from screen context using Google Gemini."""
    try:
        model = genai.GenerativeModel('gemini-pro')
        prompt = f"""
        Extract and summarize the key information from this screen context:
        
        {context_text}
        
        Focus on extracting the main content, ignoring UI elements, and providing a concise summary.
        """
        
        response = model.generate_content(prompt)
        return response.text
    except Exception as e:
        print(f"Error extracting text with Gemini: {e}")
        return context_text

@app.route('/clear', methods=['POST'])
def clear_history():
    global conversation_history
    conversation_history = []
    return jsonify({"status": "success"})

@app.route('/set_academic_mode', methods=['POST'])
def set_academic_mode():
    global academic_mode
    data = request.json
    academic_mode = data.get('academic_mode', False)
    return jsonify({"status": "success"})

@app.route('/set_windows', methods=['POST'])
def set_windows():
    # This is now handled by the frontend
    return jsonify({"status": "success"})

@app.route('/set_files', methods=['POST'])
def set_files():
    # This is now handled by the frontend
    return jsonify({"status": "success"})

@app.route('/toggle_capture', methods=['POST'])
def toggle_capture():
    # This is now handled by the frontend
    return jsonify({"status": "success"})

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'ok',
        'version': '1.0.0',
        'api_keys': {
            'openai': bool(openai.api_key),
            'google': bool(google_api_key)
        }
    })

if __name__ == '__main__':
    host = '127.0.0.1'
    port = 5005
    print(f"Starting Alacrity backend server on {host}:{port}")
    print(f"API Keys configured: OpenAI: {'Yes' if openai.api_key else 'No'}, Google: {'Yes' if google_api_key else 'No'}")
    app.run(host=host, port=port, debug=True) 