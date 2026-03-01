#!/bin/bash
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Claude Dev Environment Setup ==="
echo ""

# 0. 確保 git 用 HTTPS 存取 GitHub（避免 SSH key 問題）
echo "[0/4] Configuring git for HTTPS..."
git config --global url."https://github.com/".insteadOf "git@github.com:"

# 1. 註冊 umbrella marketplace（用 GitHub URL，跨機器通用）
echo "[1/4] Registering marketplace..."
claude plugin marketplace add https://github.com/EndeavorYen/claude-env.git 2>/dev/null \
  || echo "  Marketplace already registered, updating..."
claude plugin marketplace update my-env 2>/dev/null || true

# 2. 安裝自己的 plugins
echo "[2/4] Installing custom plugins..."
claude plugin install squad@my-env --scope user
claude plugin install misc@my-env --scope user

# 3. 還原設定（official plugins + MCP servers 全部回來）
echo "[3/4] Restoring settings..."
cp "$DIR/settings.json" ~/.claude/settings.json

# 4. 安裝 official plugins（根據 settings.json 中的 enabledPlugins）
echo "[4/4] Syncing official plugins..."
claude plugin marketplace update claude-plugins-official 2>/dev/null || true

echo ""
echo "=== Done! ==="
echo ""
echo "  Official plugins : restored from settings.json"
echo "  Custom plugins   : squad, misc installed from my-env"
echo "  MCP servers      : restored from settings.json"
echo ""
echo "Start a new Claude Code session to verify."
