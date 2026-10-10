#!/usr/bin/env bash
set -e
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p build/web
echo "Exporting Godot web build..."
godot --headless --export-release "Web" build/web/index.html

echo "Starting server on http://localhost:8000..."
if command -v python3 &>/dev/null; then
    python3 tools/serve.py 8000
elif command -v python &>/dev/null; then
    python tools/serve.py 8000
else
    node tools/serve.js 8000
fi
