import os
import sys
import json
from datetime import datetime
from PIL import Image
import base64
import io

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from common import config

class ScreenCapture:
    def __init__(self, save_dir="data/captures"):
        self.save_dir = save_dir
        os.makedirs(save_dir, exist_ok=True)
        self.active_windows = []  # Store active windows to capture
        self.active_files = []    # Store file paths to include in context
        self.is_whole_screen = True  # Default to capture whole screen

    def capture_screen(self):
        """
        Placeholder for screen capture functionality.
        In a real implementation, this would use platform-specific code to capture the screen.
        """
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{self.save_dir}/screen_{timestamp}.txt"
        
        # For demo purposes, create a placeholder text file
        with open(filename, 'w') as f:
            f.write(f"Simulated screen capture at {datetime.now().isoformat()}\n")
            f.write("This is a placeholder for actual screen content.\n")
            f.write("In a complete implementation, this would contain extracted text from the screen.\n")
        
        return filename

    def extract_text_from_image(self, image_path):
        """
        Placeholder for text extraction from image.
        In a real implementation, this would use OCR to extract text.
        """
        # For demo purposes, just read the file if it's a text file
        if image_path.endswith('.txt'):
            with open(image_path, 'r') as f:
                return f.read()
        
        return "Simulated text extraction from screen capture."

    def get_window_list(self):
        """
        Get list of open windows (placeholder)
        In a real implementation, this would use macOS-specific APIs to get window information
        """
        # This is a placeholder
        return [
            {"id": 1, "title": "Chrome - Academic Papers"},
            {"id": 2, "title": "PDF Viewer - Textbook"},
            {"id": 3, "title": "VS Code - Homework"},
        ]

    def set_active_windows(self, window_ids):
        """Set which specific windows to capture"""
        self.active_windows = window_ids
        self.is_whole_screen = False if window_ids else True

    def set_active_files(self, file_paths):
        """Set file paths to include in context"""
        self.active_files = file_paths

    def get_file_contents(self):
        """Get content of selected files"""
        file_contexts = []
        for file_path in self.active_files:
            try:
                with open(file_path, 'r') as f:
                    content = f.read()
                    file_contexts.append({
                        "path": file_path,
                        "content": content[:config.MAX_CONTEXT_LENGTH]  # Truncate if too long
                    })
            except Exception as e:
                print(f"Error reading file {file_path}: {e}")
        return file_contexts

    def capture_and_process(self):
        """Capture screen and extract text"""
        image_path = self.capture_screen()
        text = self.extract_text_from_image(image_path)
        
        # Get file contents if any files are selected
        file_contexts = self.get_file_contents()
        
        # Combine screen text with file contents
        context = {
            "screen_text": text,
            "files": file_contexts,
            "timestamp": datetime.now().isoformat()
        }
        
        return context 