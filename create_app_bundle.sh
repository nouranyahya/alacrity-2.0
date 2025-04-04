#!/bin/bash

set -e

echo "Creating Alacrity.app Bundle"
echo "==========================="

# First build the command-line executable
cd app
swift build -c release

# Get the path to the executable
EXEC_PATH=$(swift build -c release --show-bin-path)/Alacrity

# Create app bundle directory structure
APP_DIR="$(pwd)/../Alacrity.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy executable to app bundle
cp "$EXEC_PATH" "$APP_DIR/Contents/MacOS/Alacrity"

# Create Info.plist with enhanced settings
cat > "$APP_DIR/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Alacrity</string>
    <key>CFBundleIdentifier</key>
    <string>com.alacrity.app</string>
    <key>CFBundleName</key>
    <string>Alacrity</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSBackgroundOnly</key>
    <false/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>LSUIElement</key>
    <false/>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
</dict>
</plist>
EOF

# Create a simple script to launch Alacrity and bring it to front
cat > "$APP_DIR/Contents/MacOS/LaunchHelper" << EOF
#!/bin/bash
# Launch the app
"$APP_DIR/Contents/MacOS/Alacrity" &
sleep 0.5

# Activate it using AppleScript
osascript -e '
    tell application "Alacrity"
        activate
        set visible of every window to true
    end tell
    
    tell application "System Events"
        tell process "Alacrity"
            set frontmost to true
        end tell
    end tell
'
EOF

# Make the launch helper executable
chmod +x "$APP_DIR/Contents/MacOS/LaunchHelper"

echo "App bundle created at $APP_DIR"
echo ""
echo "To run Alacrity, double-click on the app bundle or use:"
echo "open \"$APP_DIR\""
echo ""
echo "Running Alacrity.app now..."
open "$APP_DIR"

cd - 