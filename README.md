# Alacrity - Personal AI Assistant

Alacrity is a macOS-native AI assistant designed for academic and general use, providing context-aware responses by analyzing screen content.

## Features

- **Context-aware AI assistance**: Captures screen content to provide relevant responses
- **Academic focus mode**: Optimized for university-level engineering, math, and computer science
- **Selective screen capture**: Choose specific windows/tabs for context analysis
- **Native macOS UI**: Built with Swift and SwiftUI for a seamless experience
- **Dual AI mode**: Choose between academic focus (GPT-3.5) or general assistance (GPT-4)

## Setup

1. Clone this repository
2. Install required dependencies:
   - For backend: `pip install -r backend/requirements.txt`
   - For macOS app: Open in Xcode and install required packages
3. Add your API keys to `common/config.py`
4. Run the backend server: `python backend/server.py`
5. Build and run the macOS app in Xcode

## Architecture

- **Swift front-end**: Native macOS UI built with SwiftUI
- **Python backend**: Handles screen capture, text extraction, and AI model interactions
- **API integrations**: OpenAI for chat, Gemini for image-to-text capabilities

## Development Timeline

- Week 1: Setup and basic UI implementation
- Week 2: Screen capture and text extraction
- Week 3: AI model integration and context handling
- Week 4: Final polish and refinements # alacrity-2.0
