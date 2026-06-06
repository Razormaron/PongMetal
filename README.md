# PongMetal

A native Apple Silicon Pong game built with Metal and Swift. No game engine, no dependencies — just pure Metal rendering at 60 fps.

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
3. Move it to your Applications folder
4. Right-click → Open (first launch only, to bypass the unverified developer warning)

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

The game supports three sound effects. Add your own `.mov` audio files to:

```
Sources/PongMetal/Resources/Paddle.mov   # ball hits a paddle
Sources/PongMetal/Resources/Wall.mov     # ball hits top/bottom wall
Sources/PongMetal/Resources/Score.mov    # a point is scored
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
