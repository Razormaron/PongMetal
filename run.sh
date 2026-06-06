#!/bin/bash
# Build and run Pong (release build for best performance on Apple Silicon)
set -e
cd "$(dirname "$0")"
swift run -c release
