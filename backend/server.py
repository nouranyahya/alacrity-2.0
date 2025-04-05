import os
import sys
import json
import openai
import base64
import google.generativeai as genai
from flask import Flask, request, jsonify
from flask_cors import CORS
from config import (
    OPENAI_API_KEY, 
    GOOGLE_API_KEY, 
    ACADEMIC_MODEL, 
    GENERAL_MODEL,
    ACADEMIC_SYSTEM_PROMPT,
    GENERAL_SYSTEM_PROMPT,
    BACKEND_HOST,
    BACKEND_PORT
)

# Configure OpenAI client with the API key
client = openai.OpenAI(api_key=OPENAI_API_KEY)

# Configure Google Gemini API
if GOOGLE_API_KEY:
    genai.configure(api_key=GOOGLE_API_KEY)

# Initialize Flask app
app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Global conversation state
conversation_history = []
academic_mode = False

# Print configuration info
print(f"API Keys configured: OpenAI: {'Yes' if OPENAI_API_KEY else 'No'}, Google: {'Yes' if GOOGLE_API_KEY else 'No'}")

@app.route('/api/chat', methods=['POST'])
def chat():
    global conversation_history
    
    data = request.json
    user_message = data.get('message', '')
    context = data.get('context', '')
    use_screen_context = data.get('use_screen_context', False)
    
    # Extract text from context with Google Gemini if available
    context_for_openai = ""
    if context and GOOGLE_API_KEY and use_screen_context:
        try:
            model = genai.GenerativeModel('gemini-pro')
            screen_context = extract_text_with_gemini(context)
            context_for_openai = f"SCREEN CONTEXT:\n{screen_context}\n\nUSER QUERY: {user_message}"
        except Exception as e:
            print(f"Error processing context with Gemini: {e}")
            context_for_openai = f"USER QUERY: {user_message}"
    else:
        context_for_openai = user_message
    
    # Set system message based on mode
    system_message = ACADEMIC_SYSTEM_PROMPT if academic_mode else GENERAL_SYSTEM_PROMPT
    
    # Prepare messages with system prompt
    messages = [{"role": "system", "content": system_message}]
    messages.extend(conversation_history)
    messages.append({"role": "user", "content": context_for_openai})
    
    # Generate response using the appropriate model
    model_name = ACADEMIC_MODEL if academic_mode else GENERAL_MODEL
    
    try:
        # Updated OpenAI API call format
        response = client.chat.completions.create(
            model=model_name,
            messages=messages,
            temperature=0.7,
            max_tokens=1000
        )
        
        # Extract and add assistant response to history (updated format)
        assistant_response = response.choices[0].message.content
        conversation_history.append({"role": "user", "content": context_for_openai})
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

@app.route('/api/clear_history', methods=['POST'])
def clear_history():
    global conversation_history
    conversation_history = []
    return jsonify({"status": "success"})

@app.route('/api/set_mode', methods=['POST'])
def set_academic_mode():
    global academic_mode
    data = request.json
    academic_mode = data.get('academic_mode', False)
    return jsonify({"status": "success"})

@app.route('/api/set_windows', methods=['POST'])
def set_windows():
    # This is now handled by the frontend
    return jsonify({"status": "success"})

@app.route('/api/set_files', methods=['POST'])
def set_files():
    # This is now handled by the frontend
    return jsonify({"status": "success"})

@app.route('/api/toggle_background_capture', methods=['POST'])
def toggle_capture():
    # This is now handled by the frontend
    return jsonify({"status": "success"})

@app.route('/api/get_windows', methods=['GET'])
def get_windows():
    """Simplified window list getter"""
    # Return empty list as we now handle this in the frontend
    return jsonify({"windows": []})

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'ok',
        'version': '1.0.0',
        'api_keys': {
            'openai': bool(OPENAI_API_KEY),
            'google': bool(GOOGLE_API_KEY)
        }
    })

if __name__ == '__main__':
    print(f"Starting Alacrity backend server on {BACKEND_HOST}:{BACKEND_PORT}")
    print(f"API Keys configured: OpenAI: {'Yes' if OPENAI_API_KEY else 'No'}, Google: {'Yes' if GOOGLE_API_KEY else 'No'}")
    app.run(host=BACKEND_HOST, port=BACKEND_PORT, debug=True) 