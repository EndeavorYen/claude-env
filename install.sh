#!/bin/bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"

# ─── Usage ───────────────────────────────────────────────────────────
usage() {
  cat <<'USAGE'
Usage: bash install.sh [setup|sync]

  setup   First-time installation on a new machine.
          - Configures git HTTPS rewrite (global)
          - Registers the umbrella marketplace
          - Restores settings.json (creates backup if exists)
          - Installs custom plugins
          - Deploys mcp.template.json to ~/.claude/mcp.template.json

  sync    Pull latest settings onto an existing machine.
          - Updates marketplace registry
          - Merges settings.json (array-union merge for allow/deny rules)
          - Re-installs custom plugins (idempotent)
          - Updates mcp.template.json

  (no argument defaults to interactive prompt, or 'setup' if non-interactive)
USAGE
}

# ─── Helpers ─────────────────────────────────────────────────────────
log()  { echo "[${STEP}/${TOTAL}] $1"; }
warn() { echo "  WARNING: $1" >&2; }
fail() { echo "  FAILED: $1" >&2; exit 1; }

backup_if_exists() {
  local target="$1"
  if [ -f "$target" ]; then
    local backup="${target}.backup.$(date +%Y%m%d%H%M%S)"
    cp "$target" "$backup"
    echo "  Backed up existing file to: $backup"
  fi
}

# Custom plugins installed from the marketplace (used in both setup and sync)
CUSTOM_PLUGINS=(squad misc battle chrome-cdp-ex)

install_custom_plugins() {
  for name in "${CUSTOM_PLUGINS[@]}"; do
    claude plugin install "${name}@my-env" --scope user || fail "Failed to install ${name}@my-env"
  done
}

MARKETPLACE_CLONE="$HOME/.claude/plugins/marketplaces/my-env"

is_interactive() {
  # True if stdin is a terminal (not piped, not CI, not SSH without TTY)
  [ -t 0 ]
}

# merge_settings: Array-union merge for settings.json
# - Scalar/object keys: local wins on conflict (jq * operator)
# - permissions.allow / permissions.deny: union of both arrays (repo rules never lost)
# - enabledPlugins: local wins on conflict (it's an object, not array — * handles correctly)
# Requires: jq
merge_settings() {
  local repo_file="$1"
  local local_file="$2"
  local output_file="$3"

  jq -s '
    # Start with object-level merge (repo wins on scalar conflicts)
    # This ensures settings like effortLevel and autoUpdatesChannel always
    # reflect the repo snapshot, while local additions are still preserved
    # via the explicit array unions for permissions below.
    (.[1] * .[0]) as $merged |

    # For permissions.allow and permissions.deny, compute the union of both arrays
    # so that neither repo nor local rules are silently dropped
    (.[0].permissions.allow // []) as $repo_allow |
    (.[1].permissions.allow // []) as $local_allow |
    (.[0].permissions.deny // []) as $repo_deny |
    (.[1].permissions.deny // []) as $local_deny |

    # Union = deduplicated combination of both arrays
    ($repo_allow + $local_allow | unique) as $merged_allow |
    ($repo_deny + $local_deny | unique) as $merged_deny |

    # Patch the merged result with unioned arrays
    $merged
    | .permissions.allow = $merged_allow
    | .permissions.deny = $merged_deny
  ' "$repo_file" "$local_file" > "$output_file"
}

# deploy_mcp_template: Copy mcp.template.json to ~/.claude/ for easy access
deploy_mcp_template() {
  local src="$DIR/mcp.template.json"
  local dst="$HOME/.claude/mcp.template.json"
  if [ -f "$src" ]; then
    cp "$src" "$dst"
    echo "  Deployed mcp.template.json to $dst"
    echo "  Usage: cp ~/.claude/mcp.template.json /path/to/project/.mcp.json"
  else
    warn "mcp.template.json not found in repo — skipping."
  fi
}

# ─── Mode Selection ──────────────────────────────────────────────────
MODE="${1:-}"

if [ -z "$MODE" ]; then
  if ! is_interactive; then
    # Non-interactive (piped, CI, SSH without TTY): default to setup
    if [ -f ~/.claude/settings.json ]; then
      MODE="sync"
      echo "Non-interactive context detected with existing settings. Defaulting to 'sync'."
    else
      MODE="setup"
      echo "Non-interactive context detected. Defaulting to 'setup'."
    fi
  elif [ -f ~/.claude/settings.json ]; then
    echo "Detected existing ~/.claude/settings.json"
    echo ""
    echo "  setup  — Full first-time install (backs up existing settings)"
    echo "  sync   — Merge latest settings (preserves local additions)"
    echo ""
    read -rp "Choose mode [setup/sync]: " MODE
    if [ -z "$MODE" ]; then
      fail "No mode selected. Usage: bash install.sh [setup|sync]"
    fi
  else
    MODE="setup"
    echo "No existing settings found. Running first-time setup."
  fi
fi

case "$MODE" in
  setup) ;;
  sync)  ;;
  -h|--help|help) usage; exit 0 ;;
  *) fail "Unknown mode: '$MODE'. Expected 'setup' or 'sync'. Run 'bash install.sh --help' for usage." ;;
esac

echo ""
echo "=== Claude Dev Environment — $(echo "$MODE" | tr '[:lower:]' '[:upper:]') ==="
echo ""

# ─── SETUP Mode ──────────────────────────────────────────────────────
if [ "$MODE" = "setup" ]; then
  TOTAL=5
  STEP=1

  # 1. Git HTTPS config
  log "Configuring git for HTTPS..."
  echo "  NOTE: Sets global git config to rewrite git@github.com: to HTTPS."
  echo "  Revert with: git config --global --unset url.\"https://github.com/\".insteadOf"
  git config --global url."https://github.com/".insteadOf "git@github.com:"

  # 2. Register marketplace (fail visibly)
  STEP=2
  log "Registering marketplace..."
  if ! claude plugin marketplace add https://github.com/EndeavorYen/claude-env.git 2>&1; then
    # Retry as update — "already registered" is the only acceptable failure
    if ! claude plugin marketplace update my-env 2>&1; then
      fail "Could not register or update marketplace 'my-env'. Check network and URL."
    fi
    echo "  Marketplace already registered, updated successfully."
  fi

  # 3. Install custom plugins
  # Must run BEFORE settings restore: claude plugin install rewrites settings.json
  # as a side-effect, which would overwrite the restored settings if run after.
  STEP=3
  log "Installing custom plugins..."
  install_custom_plugins

  # 4. Restore settings (with backup) — runs LAST to ensure its output is final
  STEP=4
  log "Restoring settings..."
  mkdir -p ~/.claude
  backup_if_exists ~/.claude/settings.json
  cp "$DIR/settings.json" ~/.claude/settings.json
  echo "  Restored settings.json from repo snapshot."

  # 5. Deploy MCP template
  STEP=5
  log "Deploying MCP template..."
  deploy_mcp_template

# ─── SYNC Mode ───────────────────────────────────────────────────────
elif [ "$MODE" = "sync" ]; then
  TOTAL=4
  STEP=1

  # 1. Update marketplace
  log "Updating marketplace registry..."
  if ! claude plugin marketplace update my-env 2>&1; then
    fail "Could not update marketplace 'my-env'. Is it registered? Run 'setup' first."
  fi

  # 2. Re-install custom plugins (idempotent)
  # Must run BEFORE settings merge: claude plugin install rewrites settings.json
  # as a side-effect, which would overwrite the merged settings if run after.
  STEP=2
  log "Syncing custom plugins..."
  install_custom_plugins

  # 3. Merge settings (non-destructive, array-union for permissions)
  # Runs LAST among steps that touch settings.json, so its output is final.
  STEP=3
  log "Merging settings..."
  if [ -f ~/.claude/settings.json ]; then
    if command -v jq &>/dev/null; then
      # Array-union merge: repo deny/allow rules are never silently dropped
      backup_if_exists ~/.claude/settings.json
      merge_settings "$DIR/settings.json" ~/.claude/settings.json ~/.claude/settings.json.tmp \
        && mv ~/.claude/settings.json.tmp ~/.claude/settings.json
      echo "  Merged settings with array-union strategy (repo + local rules both preserved)."
    else
      warn "jq not found — falling back to overwrite with backup."
      warn "Install jq for non-destructive array-union merge of permissions."
      backup_if_exists ~/.claude/settings.json
      cp "$DIR/settings.json" ~/.claude/settings.json
      echo "  Restored settings.json from repo snapshot (backup created)."
    fi
  else
    mkdir -p ~/.claude
    cp "$DIR/settings.json" ~/.claude/settings.json
    echo "  No local settings found. Restored from repo snapshot."
  fi

  # 4. Deploy MCP template
  STEP=4
  log "Updating MCP template..."
  deploy_mcp_template
fi

# ─── Sync official plugins (both modes) ──────────────────────────────
echo ""
echo "Syncing official plugins..."
if ! claude plugin marketplace update claude-plugins-official 2>&1; then
  warn "Could not update official plugins. They may already be up-to-date."
fi

# ─── Done ─────────────────────────────────────────────────────────────
echo ""
echo "=== Done! ==="
echo ""
echo "  Mode             : $MODE"
echo "  Official plugins : 26 enabled"
echo "  Custom plugins   : squad, misc, battle, chrome-cdp-ex (from my-env marketplace)"
echo "  Settings         : permissions, effortLevel, autoUpdatesChannel"
echo "  MCP template     : ~/.claude/mcp.template.json"
echo ""

# ─── Machine-specific plugins (manual install required) ──────────────
# These plugins need per-machine setup because they depend on local paths,
# OS-specific binaries, or external services. install.sh does NOT install
# them automatically — the user (or agent) should install after first setup.
echo "--- Machine-Specific Plugins (manual) ---"
echo ""
echo "  oh-my-claudecode  Status line HUD & theme customization"
echo "    Install:"
echo "      claude plugin marketplace add https://github.com/Yeachan-Heo/oh-my-claudecode.git"
echo "      claude plugin install oh-my-claudecode@omc --scope user"
echo "    Then configure statusLine in ~/.claude/settings.json (path is OS-dependent)."
echo "    Docs: https://github.com/Yeachan-Heo/oh-my-claudecode"
echo ""
echo "Start a new Claude Code session to verify."
