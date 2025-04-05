# Alacrity - AI Assistant for macOS

A native macOS AI assistant that provides context-aware responses by analyzing your screen content and files.

## Features

- **Context-aware AI**: Analyzes your screen content or specific windows/applications
- **Dual AI modes**: Academic mode (optimized for engineering, math, CS) or general assistance
- **Native macOS UI**: Built with Swift and SwiftUI for a seamless experience
- **File context**: Include specific files as additional context for the AI
- **Privacy-focused**: All processing happens locally, with data sent only to AI APIs

## Quick Setup

### Prerequisites
- macOS 12.0+
- Python 3.8+
- OpenAI API key ([get one here](https://platform.openai.com/api-keys))
- Google API key ([get one here](https://makersuite.google.com/app/apikey))

### Installation & Setup

1. Clone this repository
2. Run the single setup script:
   ```
   ./run.sh
   ```
3. When prompted, add your API keys to the `.env` file:
   ```
   OPENAI_API_KEY=your_openai_api_key_here
   GOOGLE_API_KEY=your_google_api_key_here
   ```

## Usage

### Basic Chat
Type your question in the chat interface. Alacrity will analyze your screen context (if enabled) and provide relevant assistance.

### Settings
- **Screen Capture**: Enable/disable and choose between whole screen or specific windows
- **Academic Mode**: Toggle for responses optimized for academic content
- **Window Selection**: Choose which windows to include in the context
- **File Context**: Select specific files to include in your queries

## Example Use Cases

- **Programming**: Get help debugging code visible on your screen
- **Academic**: Ask questions about textbooks, research papers, or lecture slides
- **Document Analysis**: Summarize or extract key information from visible documents
- **General Assistance**: Ask any question with relevant context from your screen

## Architecture

- **Swift Frontend**: Native macOS UI built with SwiftUI
- **Python Backend**: Handles screen capture, text extraction, and AI communication
- **AI Integration**: Uses OpenAI for chat and Google Gemini for image analysis

## Project Structure

The project has been streamlined for improved maintainability:

- **app/**: Swift frontend application
- **backend/**: Python backend server including configuration and API handlers
- **data/captures/**: Storage for temporary screen captures
- **Alacrity.app**: Compiled macOS application bundle
- **run.sh**: Single unified script for setup and running the application

## Troubleshooting

- If the frontend doesn't connect to the backend, ensure the backend server is running
- Check permissions if screen capture isn't working
- Verify your API keys if you receive authentication errors
