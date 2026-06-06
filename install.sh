#!/bin/bash
# Builds PongMetal and installs it as Pong.app in /Applications.
set -e
cd "$(dirname "$0")"

echo "Building..."
swift build -c release

APP="/Applications/Pong.app"
BINARY=".build/arm64-apple-macosx/release/PongMetal"

# Create app bundle
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp "$BINARY" "$APP/Contents/MacOS/Pong"
cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

# Copy sound effects if present
for f in Paddle Wall Score; do
    src="Sources/PongMetal/Resources/$f.mov"
    [ -f "$src" ] && cp "$src" "$APP/Contents/Resources/"
done

# Copy bundled resources (needed for Bundle.module to find sounds)
BUNDLE=".build/arm64-apple-macosx/release/PongMetal_PongMetal.bundle/Resources"
[ -d "$BUNDLE" ] && cp -r "$BUNDLE/." "$APP/Contents/Resources/"

cat > "$APP/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Pong</string>
    <key>CFBundleDisplayName</key><string>Pong</string>
    <key>CFBundleIdentifier</key><string>com.local.pong</string>
    <key>CFBundleVersion</key><string>1.0</string>
    <key>CFBundleExecutable</key><string>Pong</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST

touch "$APP"
killall Dock 2>/dev/null || true

echo "Done — Pong.app installed in /Applications."
echo "You can also drag it to your Dock from there."
