#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${CYAN}${BOLD}"
echo "  ╔═══════════════════════════════════════╗"
echo "  ║   💥  SlapBook Installer  👋           ║"
echo "  ║   Slap your Mac. Watch it shatter.    ║"
echo "  ╚═══════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}▶ Checking requirements...${NC}"

if ! command -v swift &> /dev/null; then
    echo -e "${RED}✗ Swift not found. Install Xcode from the App Store and try again.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Swift found: $(swift --version | head -1)${NC}"

MACOS_VERSION=$(sw_vers -productVersion | cut -d. -f1)
if [ "$MACOS_VERSION" -lt 13 ]; then
    echo -e "${RED}✗ macOS 13 Ventura or later required.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ macOS $(sw_vers -productVersion)${NC}"

echo ""
echo -e "${YELLOW}▶ Building SlapBook...${NC}"

cd "$(dirname "$0")/SlapBook"
swift build -c release 2>&1 | tail -5

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Build failed. Check the output above.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Build successful${NC}"

echo ""
echo -e "${YELLOW}▶ Creating app bundle...${NC}"

APP_DIR="/Applications/SlapBook.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

rm -rf "$APP_DIR"
mkdir -p "$MACOS" "$RESOURCES"

cp .build/release/SlapBook "$MACOS/SlapBook"
cp Resources/Info.plist "$CONTENTS/Info.plist"

echo -e "${GREEN}✓ App bundle created at $APP_DIR${NC}"

echo ""
read -p "$(echo -e "${YELLOW}▶ Launch SlapBook automatically at login? [y/N]: ${NC}")" AUTOSTART

if [[ "$AUTOSTART" =~ ^[Yy]$ ]]; then
    PLIST_DIR="$HOME/Library/LaunchAgents"
    PLIST="$PLIST_DIR/com.slapbook.app.plist"
    mkdir -p "$PLIST_DIR"
    cat > "$PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.slapbook.app</string>
    <key>ProgramArguments</key>
    <array>
        <string>$MACOS/SlapBook</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
EOF
    launchctl load "$PLIST" 2>/dev/null || true
    echo -e "${GREEN}✓ Auto-start enabled${NC}"
fi

echo ""
echo -e "${GREEN}${BOLD}✓ SlapBook installed successfully!${NC}"
echo ""
echo -e "  ${CYAN}👋  Slap your MacBook to shatter the screen"
echo -e "  🎙️  Talking Tom voice reactions included"
echo -e "  🖥️  Menu bar icon: look for 👋 in your menu bar"
echo -e "  ⌨️  No accelerometer? Use  Shift+Ctrl+S  to test${NC}"
echo ""

read -p "$(echo -e "${YELLOW}▶ Launch SlapBook now? [Y/n]: ${NC}")" LAUNCH
if [[ ! "$LAUNCH" =~ ^[Nn]$ ]]; then
    open "$APP_DIR"
    echo -e "${GREEN}✓ SlapBook is running! Check your menu bar 👋${NC}"
fi

echo ""
echo -e "${CYAN}─────────────────────────────────────────────${NC}"
echo -e "${CYAN}  To uninstall: rm -rf /Applications/SlapBook.app${NC}"
echo -e "${CYAN}─────────────────────────────────────────────${NC}"
echo ""
