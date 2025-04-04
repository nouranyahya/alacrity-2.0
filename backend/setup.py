import os
import sys
import dotenv

def ensure_required_directories():
    """Ensure all required directories exist."""
    # Create the data directory if it doesn't exist
    os.makedirs('data', exist_ok=True)
    
    # Create captures directory but with a .gitignore inside to prevent commits
    captures_dir = os.path.join('data', 'captures')
    os.makedirs(captures_dir, exist_ok=True)
    
    # Create a .gitignore in the captures directory
    gitignore_path = os.path.join(captures_dir, '.gitignore')
    if not os.path.exists(gitignore_path):
        with open(gitignore_path, 'w') as f:
            f.write("# Ignore all files in this directory\n")
            f.write("*\n")
            f.write("# Except this file\n")
            f.write("!.gitignore\n")
        print("Created .gitignore in captures directory")
    
    # Clean up any existing captures to save disk space
    try:
        for filename in os.listdir(captures_dir):
            if filename != '.gitignore':
                filepath = os.path.join(captures_dir, filename)
                if os.path.isfile(filepath):
                    os.remove(filepath)
        print("Cleaned up existing capture files")
    except Exception as e:
        print(f"Warning: Could not clean up capture files: {e}")

def setup_environment():
    """Set up the environment file if it doesn't exist."""
    env_path = '.env'
    env_example_path = '.env.example'
    
    if not os.path.exists(env_path):
        # If example exists, use it as a template
        if os.path.exists(env_example_path):
            print(f"Found .env.example file. Using as template...")
            with open(env_example_path, 'r') as example_file:
                example_content = example_file.read()
            
            # Show the content to the user
            print("\nTemplate content:")
            print("----------------")
            print(example_content)
            print("----------------\n")
        
        openai_api_key = input("Enter your OpenAI API key (or leave blank to skip): ")
        google_api_key = input("Enter your Google API key (or leave blank to skip): ")
        
        with open(env_path, 'w') as f:
            f.write(f"OPENAI_API_KEY = \"{openai_api_key}\"\n")
            f.write(f"GOOGLE_API_KEY = \"{google_api_key}\"\n")
        
        print(f"Created .env file with API keys at {os.path.abspath(env_path)}")
        print("NOTE: Keep these API keys confidential and never commit them to version control.")
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