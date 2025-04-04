# Getting Started with Alacrity

Welcome to Alacrity, your personal AI assistant for macOS! This guide will help you set up and start using Alacrity in just a few minutes.

## Quick Start

### Step 1: Get API Keys
Before you begin, you'll need to obtain two API keys:

1. **OpenAI API Key**
   - Go to https://platform.openai.com/api-keys
   - Sign up or log in to your OpenAI account
   - Create a new API key
   - Copy the key

2. **Google Gemini API Key**
   - Go to https://makersuite.google.com/app/apikey
   - Sign up or log in to your Google account
   - Create a new API key
   - Copy the key

### Step 2: Start the Backend Server

1. Open Terminal
2. Navigate to the Alacrity directory:
   ```
   cd /path/to/alacrity
   ```
3. Run the startup script:
   ```
   ./start_backend.sh
   ```
4. When prompted, create your `.env` file with your API keys:
   ```
   OPENAI_API_KEY=your_openai_api_key_here
   GOOGLE_API_KEY=your_google_api_key_here
   ```
5. Run the startup script again to start the server

### Step 3: Launch the Alacrity App

1. Open the Xcode project:
   ```
   open app/Alacrity.xcodeproj
   ```
2. Click the Run button (or press ⌘+R)
3. When prompted, grant necessary permissions for screen capture

## First Use

1. **Choose your Mode**
   - Click on Settings in the sidebar
   - Toggle Academic Mode on if you're using Alacrity for academic purposes
   
2. **Configure Screen Context**
   - Enable Screen Context to allow Alacrity to analyze your screen
   - Choose between whole screen or specific windows

3. **Add File Context**
   - Select Files to add specific files as context for Alacrity

4. **Start Chatting**
   - Click on Chat in the sidebar
   - Type your question or request in the text field
   - Alacrity will analyze your screen context and provide a relevant response

## Example Uses

- Open a PDF textbook and ask: "Can you explain the concept shown on my screen?"
- Open your code editor and ask: "What's wrong with this function?"
- Open lecture slides and ask: "Summarize the key points from these slides."

## Troubleshooting

- If the app doesn't connect to the backend, make sure the backend server is running
- If screen capture isn't working, check that you've granted the necessary permissions
- If responses seem unrelated to your screen, try enabling and disabling screen context

## Need Help?

Refer to the full documentation in `USAGE.md` for more detailed instructions and advanced features. 