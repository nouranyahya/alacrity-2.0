import os
import sys
import dotenv

def ensure_required_directories():
    """Ensure all required directories exist."""
    # Create the data directory if it doesn't exist
    os.makedirs('data', exist_ok=True)
    
    # No longer need the captures directory since we're using in-memory captures
    # Clean up any existing captures to save disk space
    if os.path.exists('data/captures'):
        try:
            for filename in os.listdir('data/captures'):
                filepath = os.path.join('data/captures', filename)
                if os.path.isfile(filepath):
                    os.remove(filepath)
            print("Cleaned up existing capture files")
        except Exception as e:
            print(f"Warning: Could not clean up capture files: {e}")

def setup_environment():
    """Set up the environment file if it doesn't exist."""
    env_path = '.env'
    
    if not os.path.exists(env_path):
        openai_api_key = input("Enter your OpenAI API key (or leave blank to skip): ")
        google_api_key = input("Enter your Google API key (or leave blank to skip): ")
        
        with open(env_path, 'w') as f:
            f.write(f"OPENAI_API_KEY = \"{openai_api_key}\"\n")
            f.write(f"GOOGLE_API_KEY=\"{google_api_key}\"\n")
        
        print("Created .env file with API keys")
    else:
        print("Environment file already exists")

def main():
    print("Setting up Alacrity...")
    
    # Ensure we have the required directories
    ensure_required_directories()
    
    # Set up the environment file
    setup_environment()
    
    print("Setup complete!")
    return 0

if __name__ == "__main__":
    sys.exit(main()) 