# Alacrity Usage Guide

Alacrity is a personal AI assistant for macOS that can analyze your screen content and provide context-aware responses using OpenAI and Google Gemini APIs.

## Setup Instructions

### Prerequisites

1. **Python 3.8+** for the backend server
2. **Xcode 14+** for building the macOS app
3. **API Keys:**
   - OpenAI API key (https://platform.openai.com/api-keys)
   - Google Gemini API key (https://makersuite.google.com/app/apikey)

### Backend Setup

1. Clone this repository to your local machine
2. Navigate to the project directory
3. Run the setup script:
   ```
   ./start_backend.sh
   ```
4. When prompted, edit the `.env` file to add your API keys:
   ```
   OPENAI_API_KEY=your_openai_api_key_here
   GOOGLE_API_KEY=your_google_api_key_here
   ```
5. Run the script again to start the backend server:
   ```
   ./start_backend.sh
   ```

### Frontend Setup

1. Open the Xcode project:
   ```
   open app/Alacrity.xcodeproj
   ```
2. Build and run the app in Xcode (⌘+R)

## Using Alacrity

### Chat Interface

- Type your message in the text field at the bottom of the chat view
- Press Enter or click the send button to send your message
- Alacrity will analyze your screen content (if enabled) and provide a relevant response

### Settings

1. **Mode Selection:**
   - Toggle between Academic Focus (uses GPT-3.5) and General Mode (uses GPT-4o Mini)
   - Academic mode is optimized for engineering, math, and computer science topics

2. **Screen Context:**
   - Enable/disable screen capturing
   - Choose between whole screen or specific windows
   - Select specific windows to include in the context

3. **File Context:**
   - Select specific files to include in the context
   - Clear file selections when no longer needed

## Troubleshooting

- **Backend Connection Issues:** Make sure the Python backend is running (check terminal)
- **API Key Issues:** Verify your API keys in the `.env` file
- **Screen Capture Issues:** Make sure you've granted the necessary permissions to the app

## Advanced Features

- **Window Selection:** Similar to MS Teams meeting screen share, you can select specific windows to include in context
- **File Selection:** Include specific files as context for more relevant responses

## Example Use Cases

1. **Academic Assistance:**
   - Open textbooks and lecture slides
   - Ask Alacrity to explain complex concepts or solve problems

2. **Programming Help:**
   - Have your code editor open
   - Ask Alacrity to explain or debug code visible on your screen

3. **Document Analysis:**
   - Open PDFs or documents
   - Ask Alacrity to summarize or extract key information 