#!/usr/bin/env bash
# Refresh everything that can't be a symlink: package + toolchain manifests,
# macOS defaults, iTerm2 prefs. Configs themselves need no backup step —
# they're symlinks into this repo (see adopt.sh), so git already sees edits.
#
#   ./backup.sh              # regenerate manifests, show git status
#   ./backup.sh --commit     # ...and commit
#   ./backup.sh --push       # ...and commit + push
#
# Each section records ok/fail; a summary at the end says what to recover.
# Exit code is nonzero if any section failed.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

MANIFESTS="$REPO_DIR/manifests"
mkdir -p "$MANIFESTS"

have() { command -v "$1" >/dev/null 2>&1; }

# ---- Homebrew: formulae, casks, taps, MAS apps (if mas), VS Code extensions
if have brew; then
  info "Brewfile"
  try "Brewfile" brew bundle dump --force --file="$REPO_DIR/Brewfile"
else
  fail "Brewfile — brew not found"
fi

# ---- Rust
if have rustup; then
  info "rust toolchains"
  if rustup toolchain list > "$MANIFESTS/rustup-toolchains.txt"; then
    ok "rust toolchains"
  else
    fail "rust toolchains"
  fi
fi
if have cargo; then
  info "cargo installs"
  if out="$(cargo install --list)"; then
    awk '/^[a-zA-Z0-9_-]+ v[0-9]/ {print $1}' <<<"$out" > "$MANIFESTS/cargo-installs.txt"
    ok "cargo installs"
  else
    fail "cargo installs"
  fi
fi

# ---- Node globals (name@version, one per line)
# npm ls can exit nonzero (peer-dep gripes) while still printing the tree,
# so judge success by output, not exit code.
if have npm; then
  info "npm globals"
  out="$(npm ls -g --depth=0 2>/dev/null || true)"
  if [[ -n "$out" ]]; then
    awk 'NR>1 && $2 {print $2}' <<<"$out" > "$MANIFESTS/npm-globals.txt"
    ok "npm globals"
  else
    fail "npm globals — npm ls -g produced no output"
  fi
fi

# ---- Go: module paths of everything in GOPATH/bin
capture_go_tools() {
  local gobin f
  gobin="$(go env GOPATH)/bin"
  [[ -d "$gobin" ]] || return 0
  : > "$MANIFESTS/go-tools.txt"
  for f in "$gobin"/*; do
    [[ -x "$f" ]] || continue
    go version -m "$f" 2>/dev/null | awk '$1=="path" {print $2"@latest"}' \
      >> "$MANIFESTS/go-tools.txt" || true   # non-Go binaries in GOPATH/bin are normal
  done
  sort -u -o "$MANIFESTS/go-tools.txt" "$MANIFESTS/go-tools.txt"
}
if have go; then
  info "go tools"
  try "go tools" capture_go_tools
fi

# ---- SDKMAN candidates (java, kotlin, gradle, ...)
capture_sdkman() {
  local cand ver name v
  : > "$MANIFESTS/sdkman.txt"
  for cand in "$HOME/.sdkman/candidates"/*/; do
    name="$(basename "$cand")"
    for ver in "$cand"*/; do
      v="$(basename "$ver")"
      [[ "$v" == "current" ]] && continue
      echo "$name $v" >> "$MANIFESTS/sdkman.txt"
    done
  done
}
if [[ -d "$HOME/.sdkman/candidates" ]]; then
  info "sdkman versions"
  try "sdkman versions" capture_sdkman
fi

# ---- mise (config is symlinked; this pins what's actually installed)
if have mise; then
  info "mise installs"
  if mise ls --installed > "$MANIFESTS/mise.txt" 2>/dev/null; then
    ok "mise installs"
  else
    fail "mise installs"
  fi
fi

# ---- Claude MCP servers (just the mcpServers block, never the whole
#      ~/.claude.json — it holds OAuth + session state)
if have jq && [[ -f "$HOME/.claude.json" ]]; then
  info "claude mcp servers"
  mkdir -p "$REPO_DIR/claude"
  if jq '{mcpServers: (.mcpServers // {})}' "$HOME/.claude.json" \
      > "$REPO_DIR/claude/mcp-servers.json"; then
    ok "claude mcp servers"
    if grep -Eqi 'token|secret|api[_-]?key' "$REPO_DIR/claude/mcp-servers.json"; then
      warn "claude/mcp-servers.json may contain credentials — review before committing"
    fi
  else
    fail "claude mcp servers"
  fi
fi

# ---- crontab, if any
if crontab -l >/dev/null 2>&1; then
  info "crontab"
  if crontab -l > "$MANIFESTS/crontab.txt"; then
    ok "crontab"
  else
    fail "crontab"
  fi
fi

# ---- macOS defaults + iTerm2 prefs
if [[ "$(uname)" == "Darwin" ]]; then
  info "macOS defaults"
  try "macOS defaults" "$REPO_DIR/macos/defaults.sh" capture
  info "iterm2 prefs"
  if defaults export com.googlecode.iterm2 \
      "$REPO_DIR/iterm2/com.googlecode.iterm2.plist" 2>/dev/null; then
    ok "iterm2 prefs"
  else
    fail "iterm2 prefs — none found (never ran iTerm2 on this machine?)"
  fi
fi

# ---- wrap up
cd "$REPO_DIR"
summary
echo
git status --short || true

case "${1:-}" in
  --commit|--push)
    if [[ "$N_FAIL" -gt 0 ]]; then
      warn "committing anyway, but $N_FAIL section(s) above did NOT refresh"
    fi
    git add -A
    if git diff --cached --quiet; then
      info "nothing to commit"
    else
      git commit -m "backup: $(hostname -s) $(date '+%Y-%m-%d')"
      [[ "${1:-}" == "--push" ]] && git push
    fi
    ;;
  *) echo; info "review above, then: git add -A && git commit  (or rerun with --commit / --push)" ;;
esac

[[ "$N_FAIL" -eq 0 ]]  # exit 1 if anything failed
