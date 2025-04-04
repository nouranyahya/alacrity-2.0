import os
import sys
import json
import openai
import requests
from PIL import Image

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from common import config

class AIInteraction:
    def __init__(self):
        # Initialize OpenAI client
        self.client = openai.OpenAI(api_key=config.OPENAI_API_KEY)
        
        # Initialize conversation history
        self.conversation_history = []
        self.academic_mode = False  # Default to general mode
    
    def set_academic_mode(self, is_academic):
        """Toggle between academic and general mode"""
        self.academic_mode = is_academic
    
    def get_current_model(self):
        """Get the current model based on mode"""
        return config.ACADEMIC_MODEL if self.academic_mode else config.GENERAL_MODEL
    
    def get_system_prompt(self):
        """Get the appropriate system prompt based on current mode"""
        return config.ACADEMIC_SYSTEM_PROMPT if self.academic_mode else config.GENERAL_SYSTEM_PROMPT
    
    def extract_text_from_image_api(self, image_path):
        """Placeholder for image-to-text using API"""
        # In a real implementation, this would use Google Gemini or another API
        # For now, we'll just read the file if it's a text file
        if image_path.endswith('.txt'):
            with open(image_path, 'r') as f:
                return f.read()
        
        return "Simulated text extraction from image API."
    
    def prepare_context(self, screen_context, user_message):
        """Prepare context for AI by combining screen capture text, files, and history"""
        context = ""
        
        # Add screen text if available
        if screen_context and "screen_text" in screen_context:
            context += f"SCREEN CONTENT:\n{screen_context['screen_text']}\n\n"
        
        # Add file contents if available
        if screen_context and "files" in screen_context and screen_context["files"]:
            for file_data in screen_context["files"]:
                context += f"FILE ({file_data['path']}):\n{file_data['content'][:1000]}...\n\n"
        
        # Truncate context if too long
        if len(context) > config.MAX_CONTEXT_LENGTH:
            context = context[:config.MAX_CONTEXT_LENGTH] + "...(truncated)"
        
        return context
    
    def chat(self, user_message, screen_context=None):
        """Send message to OpenAI with context and handle response"""
        try:
            # Prepare context from screen capture and file contents
            context = self.prepare_context(screen_context, user_message)
            
            # Prepare messages for the chat
            messages = [
                {"role": "system", "content": self.get_system_prompt()},
            ]
            
            # Add conversation history (last few exchanges)
            for msg in self.conversation_history[-6:]:  # Include last 3 exchanges (6 messages)
                messages.append(msg)
            
            # Add context as assistant message if available
            if context:
                context_message = {
                    "role": "system", 
                    "content": f"The user's current screen and files show the following content. Use this as context for answering the next question:\n\n{context}"
                }
                messages.append(context_message)
            
            # Add the current user message
            messages.append({"role": "user", "content": user_message})
            
            # Call OpenAI API
            response = self.client.chat.completions.create(
                model=self.get_current_model(),
                messages=messages,
                temperature=0.5,
                max_tokens=1000
            )
            
            # Extract the response text
            assistant_message = response.choices[0].message.content
            
            # Update conversation history
            self.conversation_history.append({"role": "user", "content": user_message})
            self.conversation_history.append({"role": "assistant", "content": assistant_message})
            
            return assistant_message
            
        except Exception as e:
            print(f"Error in chat: {e}")
            return f"I'm sorry, I encountered an error: {str(e)}"
    
    def clear_history(self):
        """Clear conversation history"""
        self.conversation_history = []
        return "Conversation history cleared." 