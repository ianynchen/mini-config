#!/usr/bin/env bash
# Fresh-machine setup. Idempotent — safe to re-run at any point.
#
#   git clone git@github.com:<you>/dotfiles.git ~/dotfiles
#   cd ~/dotfiles && ./bootstrap.sh
#
# Order: Xcode CLT -> Homebrew -> Brewfile -> oh-my-zsh -> symlinks ->
#        toolchains -> macOS defaults -> iTerm2 -> manual-steps checklist.
#
# Every step (down to individual cargo/npm/go/sdk installs) records ok/fail
# and the script keeps going; the summary at the end is your recovery list.
# Exit code is nonzero if anything failed.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

have() { command -v "$1" >/dev/null 2>&1; }

# ---- 1. Xcode Command Line Tools ------------------------------------------
if ! xcode-select -p >/dev/null 2>&1; then
  info "installing Xcode Command Line Tools (accept the GUI prompt)"
  xcode-select --install || true
  until xcode-select -p >/dev/null 2>&1; do sleep 10; done
fi
ok "Xcode Command Line Tools"

# ---- 2. Homebrew -----------------------------------------------------------
if ! have brew; then
  info "installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || true
fi
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
if have brew; then
  ok "Homebrew"
else
  fail "Homebrew — install failed; everything brew-based below will also fail"
fi

# ---- 3. Brewfile (formulae, casks, MAS apps, VS Code extensions) -----------
if [[ ! -f "$REPO_DIR/Brewfile" ]]; then
  fail "brew bundle — no Brewfile in repo; run ./backup.sh on your old machine first"
elif ! have brew; then
  fail "brew bundle — brew not available"
else
  info "brew bundle (this is the long step)"
  if brew bundle --file="$REPO_DIR/Brewfile"; then
    ok "brew bundle"
  else
    fail "brew bundle — scroll up for the failing entries, or rerun this script"
  fi
fi

# ---- 4. oh-my-zsh ----------------------------------------------------------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  info "installing oh-my-zsh"
  try "oh-my-zsh" env RUNZSH=no KEEP_ZSHRC=yes CHSH=no \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  ok "oh-my-zsh (already installed)"
fi

# Custom plugins/themes are re-cloned, not vendored (they're .gitignored).
# Cloned only if your .zshrc actually references them.
clone_if_used() {  # $1 pattern in zshrc, $2 repo url, $3 dest under omz-custom
  local zshrc="$REPO_DIR/zsh/zshrc" dest="$REPO_DIR/zsh/omz-custom/$3"
  [[ -f "$zshrc" ]] || return 0
  grep -q "$1" "$zshrc" || return 0
  [[ -d "$dest" ]] && return 0
  try "clone $3" git clone --depth=1 "$2" "$dest"
}
clone_if_used "zsh-autosuggestions"     "https://github.com/zsh-users/zsh-autosuggestions"     "plugins/zsh-autosuggestions"
clone_if_used "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting" "plugins/zsh-syntax-highlighting"
clone_if_used "powerlevel10k"           "https://github.com/romkatv/powerlevel10k"             "themes/powerlevel10k"

# ---- 5. Symlink configs into place ----------------------------------------
info "linking configs"
for_each_link link_one
fix_ssh_perms
enable_git_hooks

# ---- 6. Toolchains (each item recorded individually) -----------------------
if have rustup && [[ -f "$REPO_DIR/manifests/rustup-toolchains.txt" ]]; then
  info "rust toolchains"
  while read -r tc; do
    [[ -n "$tc" ]] || continue
    try "rustup toolchain $tc" rustup toolchain install "$tc"
  done < <(awk '{print $1}' "$REPO_DIR/manifests/rustup-toolchains.txt" | sed 's/-(default)//')
fi

if have cargo && [[ -s "$REPO_DIR/manifests/cargo-installs.txt" ]]; then
  info "cargo installs"
  while read -r tool; do
    [[ -n "$tool" ]] || continue
    try "cargo install $tool" cargo install "$tool"
  done < "$REPO_DIR/manifests/cargo-installs.txt"
fi

if have npm && [[ -s "$REPO_DIR/manifests/npm-globals.txt" ]]; then
  info "npm globals"
  while read -r pkg; do
    [[ -n "$pkg" ]] || continue
    [[ "$pkg" == npm@* ]] && continue
    try "npm install -g $pkg" npm install -g "$pkg"
  done < "$REPO_DIR/manifests/npm-globals.txt"
fi

if have go && [[ -s "$REPO_DIR/manifests/go-tools.txt" ]]; then
  info "go tools"
  while read -r mod; do
    [[ -n "$mod" ]] || continue
    try "go install $mod" go install "$mod"
  done < "$REPO_DIR/manifests/go-tools.txt"
fi

if [[ -s "$REPO_DIR/manifests/sdkman.txt" ]]; then
  if [[ ! -d "$HOME/.sdkman" ]]; then
    info "installing sdkman"
    try "install sdkman" bash -c 'curl -s "https://get.sdkman.io?rcupdate=false" | bash'
  fi
  if [[ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
    info "sdkman candidates"
    set +u; source "$HOME/.sdkman/bin/sdkman-init.sh"
    while read -r cand ver; do
      [[ -n "$cand" ]] || continue
      try "sdk install $cand $ver" sdk install "$cand" "$ver"
    done < "$REPO_DIR/manifests/sdkman.txt"
    set -u
  else
    fail "sdkman candidates — sdkman not installed"
  fi
fi

# ---- 7. macOS defaults -----------------------------------------------------
if [[ -x "$REPO_DIR/macos/defaults.generated.sh" ]]; then
  info "applying macOS defaults"
  try "macOS defaults" "$REPO_DIR/macos/defaults.sh" apply
fi

# ---- 8. iTerm2: load prefs from the repo ----------------------------------
point_iterm2_at_repo() {
  defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$REPO_DIR/iterm2" &&
  defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
}
if [[ -f "$REPO_DIR/iterm2/com.googlecode.iterm2.plist" ]]; then
  info "pointing iTerm2 at repo prefs"
  try "iTerm2 prefs" point_iterm2_at_repo
fi

# ---- 9. crontab ------------------------------------------------------------
if [[ -s "$REPO_DIR/manifests/crontab.txt" ]]; then
  info "restoring crontab"
  try "crontab" crontab "$REPO_DIR/manifests/crontab.txt"
fi

# ---- Done: what happened, then the parts that need a human -----------------
summary

cat <<'EOF'

============================================================
Bootstrap complete. Manual steps (login/state, not files):

  [ ] ssh keys      — restore from password manager, or ssh-keygen -t ed25519
                      and add the new pubkey to GitHub
  [ ] Tailscale     — open, sign in (device reauth is per-machine by design)
  [ ] OrbStack      — open, sign in / license
  [ ] Claude Code   — claude, then /login; MCP servers: see claude/mcp-servers.json
  [ ] Codex         — codex login
  [ ] gh            — gh auth login (hosts.yml is intentionally not backed up)
  [ ] JetBrains     — sign in, enable Settings Sync (IdeaVim config is already
                      linked via ~/.ideavimrc)
  [ ] iTerm2        — restart it so it picks up prefs from the repo folder
============================================================
EOF

[[ "$N_FAIL" -eq 0 ]]  # exit 1 if anything failed
