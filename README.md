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

## Build & Run

```bash
git clone https://github.com/marwan/PongMetal.git
cd PongMetal
swift build -c release
.build/release/PongMetal
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
