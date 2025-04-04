import os
import sys
import json
import openai
import base64
import google.generativeai as genai
from flask import Flask, request, jsonify
from flask_cors import CORS
import time
import threading
from dotenv import load_dotenv

# Add parent directory to sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

try:
    from common import config
    from backend.screen_capture import ScreenCapture
    from backend.ai_interaction import AIInteraction
except ImportError as e:
    print(f"Error importing modules: {e}")
    print("Make sure all dependencies are installed with: pip install -r backend/requirements.txt")
    sys.exit(1)

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

try:
    # Initialize components
    screen_capture = ScreenCapture()
    ai_interaction = AIInteraction()
except Exception as e:
    print(f"Error initializing components: {e}")
    print("Check your API keys in .env file")
    sys.exit(1)

# Flag to control background capture
capture_running = False
capture_thread = None

# Global conversation state
conversation_history = []
academic_mode = False

# Print configuration info
print(f"API Keys configured: OpenAI: {'Yes' if openai.api_key else 'No'}, Google: {'Yes' if google_api_key else 'No'}")

def background_capture_task():
    """Background task to periodically capture the screen"""
    global capture_running
    while capture_running:
        try:
            # Capture and save screen content
            screen_capture.capture_and_process()
            time.sleep(config.CAPTURE_INTERVAL)
        except Exception as e:
            print(f"Error in background capture: {e}")
            time.sleep(5)  # Wait before retrying

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

@app.route('/api/get_windows', methods=['GET'])
def get_windows():
    """Get list of available windows"""
    try:
        windows = screen_capture.get_window_list()
        return jsonify({'windows': windows})
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/toggle_background_capture', methods=['POST'])
def toggle_background_capture():
    """Toggle background screen capture"""
    global capture_running, capture_thread
    
    try:
        data = request.json
        enable_capture = data.get('enable', False)
        
        if enable_capture and not capture_running:
            # Start background capture
            capture_running = True
            capture_thread = threading.Thread(target=background_capture_task)
            capture_thread.daemon = True
            capture_thread.start()
            return jsonify({'status': 'started'})
        
        elif not enable_capture and capture_running:
            # Stop background capture
            capture_running = False
            if capture_thread:
                capture_thread.join(timeout=1.0)
            return jsonify({'status': 'stopped'})
        
        else:
            # No change needed
            status = 'running' if capture_running else 'stopped'
            return jsonify({'status': status})
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/health', methods=['GET'])
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
    print(f"Starting Alacrity backend server on {config.BACKEND_HOST}:{config.BACKEND_PORT}")
    print(f"API Keys configured: OpenAI: {'Yes' if openai.api_key else 'No'}, Google: {'Yes' if google_api_key else 'No'}")
    app.run(host=config.BACKEND_HOST, port=config.BACKEND_PORT, debug=True) 