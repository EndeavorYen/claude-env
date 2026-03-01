#!/bin/bash
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Claude Dev Environment Setup ==="

# 1. 註冊 umbrella marketplace
echo "[1/3] Registering marketplace..."
claude plugin marketplace add "$DIR"

# 2. 安裝自己的 plugins
echo "[2/3] Installing custom plugins..."
claude plugin install squad@my-env --scope user
claude plugin install misc@my-env --scope user

# 3. 還原設定（official plugins + MCP servers 全部回來）
echo "[3/3] Restoring settings..."
cp "$DIR/settings.json" ~/.claude/settings.json

echo ""
echo "=== Done! ==="
echo "Official plugins: restored from settings.json"
echo "Custom plugins:   installed from my-env marketplace"
echo "MCP servers:      restored from settings.json"
