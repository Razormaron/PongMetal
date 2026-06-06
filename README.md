# PongMetal

A native Apple Silicon Pong game built with Metal and Swift through vibe coding. No game engine, no dependencies — just pure Metal rendering at 60 fps.

## Features

- Metal GPU rendering with a custom vertex/fragment shader pipeline
- Human-like AI that scales in difficulty as you score
- Color palette that cycles on every point scored
- 7-segment display scoreboard
- Sound effects (bring your own — see below)
- Native `arm64` macOS app

## Requirements

- macOS 13 or later
- Apple Silicon Mac (M1 or later)

## Download & Play (no setup needed)

1. Download **PongMetal.zip** from the [latest release](https://github.com/Razormaron/PongMetal/releases/latest)
2. Extract it — you'll get **Pong.app**
3. Move **Pong.app** to your Applications folder
4. Double-click it — macOS will say it's damaged. Click **Cancel**
5. Open **System Settings → Privacy & Security**, scroll down and click **Open Anyway**
6. Click **Open** in the confirmation dialog — done, and you won't see it again

> This is a one-time step because the app isn't signed with a paid Apple Developer certificate. It's safe — this is standard for open-source Mac apps.

## Install from source

```bash
git clone https://github.com/Razormaron/PongMetal.git
cd PongMetal
chmod +x install.sh
./install.sh
```

This builds the project and installs **Pong.app** into `/Applications` with the icon — ready to launch from Spotlight or the Dock.

## Build & Run without installing

```bash
git clone https://github.com/Razormaron/PongMetal.git
cd PongMetal
swift build -c release
.build/arm64-apple-macosx/release/PongMetal
```

## Sound Effects

The game supports three sound effects. Add your own `.mov` or `.mp3` files to:

```
Sources/PongMetal/Resources/Paddle.mov  (or Paddle.mp3)
Sources/PongMetal/Resources/Wall.mov    (or Wall.mp3)
Sources/PongMetal/Resources/Score.mov   (or Score.mp3)
```

Then rebuild. Without them the game runs silently.

## Controls

| Key | Action |
|-----|--------|
| `W` / `↑` | Move paddle up |
| `S` / `↓` | Move paddle down |
| `Space` | Start / restart |

First to **7 points** wins.

## License

MIT
