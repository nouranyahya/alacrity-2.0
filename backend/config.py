import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# API Keys
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY", "")

# Model configurations
ACADEMIC_MODEL = "gpt-3.5-turbo"  # Use GPT-3.5 for academic focus (lower cost, specialized)
GENERAL_MODEL = "gpt-4o-mini"     # Use GPT-4o-mini for general requests (more capable)

# System prompts
ACADEMIC_SYSTEM_PROMPT = """You are Alacrity, a specialized academic assistant focused on university-level 
engineering, mathematics, and computer science. Provide clear, concise, and 
accurate responses to academic questions using the provided context.
Focus on educational explanations, technical accuracy, and academic rigor."""

GENERAL_SYSTEM_PROMPT = """You are Alacrity, a personal AI assistant. Provide helpful, accurate responses 
based on the provided context. Be conversational, friendly, and concise."""

# Screen capture settings
CAPTURE_INTERVAL = 5  # seconds between automated captures
MAX_CONTEXT_LENGTH = 4000  # maximum tokens to include from screen captures

# Server settings
BACKEND_PORT = 5006  # Changed from 5005 to avoid conflict
BACKEND_HOST = "127.0.0.1"  # localhost 