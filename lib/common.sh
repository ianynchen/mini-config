#!/usr/bin/env bash
# Shared helpers: the link map and the adopt/link logic.
# Sourced by adopt.sh, bootstrap.sh, backup.sh — not executed directly.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# "repo-relative path:$HOME-relative path"
# Every entry is a CANDIDATE. adopt skips entries that don't exist in $HOME;
# link skips entries that don't exist in the repo. So this list can be broad —
# only what's actually on the machine gets adopted/linked.
LINKS=(
  # zsh / oh-my-zsh (omz itself is cloned by bootstrap.sh, only custom/ is ours)
  "zsh/zshrc:.zshrc"
  "zsh/zprofile:.zprofile"
  "zsh/zshenv:.zshenv"
  "zsh/p10k.zsh:.p10k.zsh"
  "zsh/omz-custom:.oh-my-zsh/custom"

  # git — covers both layouts; whichever exists gets adopted
  "git/gitconfig:.gitconfig"
  "git/config:.config/git/config"
  "git/ignore:.config/git/ignore"

  # editors
  "nvim:.config/nvim"
  "ideavim/ideavimrc:.ideavimrc"

  # ssh — config only; keys never enter the repo (.gitignore enforces too)
  "ssh/config:.ssh/config"

  # claude — deliberately per-entry, NOT the whole ~/.claude
  # (skips skills/, projects/, todos/, shell-snapshots, credentials)
  "claude/CLAUDE.md:.claude/CLAUDE.md"
  "claude/settings.json:.claude/settings.json"
  "claude/agents:.claude/agents"
  "claude/commands:.claude/commands"

  # codex — config + instructions, never auth.json
  "codex/config.toml:.codex/config.toml"
  "codex/AGENTS.md:.codex/AGENTS.md"

  # terminal / misc ~/.config residents (candidates; adopted only if present)
  "config/starship.toml:.config/starship.toml"
  "config/tmux:.config/tmux"
  "tmux/tmux.conf:.tmux.conf"
  "config/ghostty:.config/ghostty"
  "config/lazygit:.config/lazygit"
  "config/karabiner:.config/karabiner"
  "config/bat:.config/bat"
  "config/mise:.config/mise"
  "config/direnv:.config/direnv"
  "config/gh/config.yml:.config/gh/config.yml"   # config only; hosts.yml holds the token
)

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*"; }

# ---- outcome tracking -------------------------------------------------------
# Steps record themselves ok/fail as they go; summary() prints the ledger at
# the end so a partial run tells you exactly what to recover. Counters are
# kept separately because ${#arr[@]} on an empty array trips `set -u` on the
# bash 3.2 that macOS ships.
STEPS_OK=()
STEPS_FAILED=()
N_OK=0
N_FAIL=0

ok()   { STEPS_OK+=("$*"); N_OK=$((N_OK + 1)); }
fail() { STEPS_FAILED+=("$*"); N_FAIL=$((N_FAIL + 1)); warn "FAILED: $*"; }

# Run a command as a named step: record ok/fail, keep the script going.
try() {  # try "label" cmd [args...]
  local label="$1"; shift
  if "$@"; then ok "$label"; else fail "$label"; fi
}

summary() {
  local s
  echo
  info "summary: $N_OK succeeded, $N_FAIL failed"
  for s in ${STEPS_OK[@]+"${STEPS_OK[@]}"}; do
    printf '    \033[1;32mok\033[0m  %s\n' "$s"
  done
  for s in ${STEPS_FAILED[@]+"${STEPS_FAILED[@]}"}; do
    printf '  \033[1;31mFAIL\033[0m  %s\n' "$s"
  done
  if [[ "$N_FAIL" -gt 0 ]]; then
    warn "fix the FAIL lines above and re-run — scripts are idempotent, finished work is skipped"
  fi
}

# Move an existing real file/dir from $HOME into the repo, symlink it back.
adopt_one() {
  local repo_rel="$1" home_rel="$2"
  local src="$HOME/$home_rel" dst="$REPO_DIR/$repo_rel"
  [[ -L "$src" ]] && return 0          # already a symlink — ours or user-managed
  [[ -e "$src" ]] || return 0          # nothing on this machine for this entry
  if [[ -e "$dst" ]]; then
    fail "adopt ~/$home_rel — $repo_rel already in repo, resolve manually"
    return 0
  fi
  if mkdir -p "$(dirname "$dst")" && mv "$src" "$dst" && ln -s "$dst" "$src"; then
    info "adopted ~/$home_rel -> $repo_rel"
    ok "adopted ~/$home_rel -> $repo_rel"
  else
    fail "adopt ~/$home_rel — may be half-moved, check $dst"
  fi
}

# Symlink a repo path into $HOME (fresh machine, or re-link after clone).
link_one() {
  local repo_rel="$1" home_rel="$2"
  local src="$REPO_DIR/$repo_rel" dst="$HOME/$home_rel"
  [[ -e "$src" ]] || return 0          # repo doesn't carry this entry
  if [[ -L "$dst" ]]; then
    [[ "$(readlink "$dst")" == "$src" ]] && return 0
    rm "$dst" || { fail "link ~/$home_rel — couldn't remove old symlink"; return 0; }
  elif [[ -e "$dst" ]]; then
    if mv "$dst" "$dst.pre-dotfiles"; then
      warn "existing ~/$home_rel moved to ~/$home_rel.pre-dotfiles"
    else
      fail "link ~/$home_rel — couldn't move aside existing file"
      return 0
    fi
  fi
  if mkdir -p "$(dirname "$dst")" && ln -s "$src" "$dst"; then
    info "linked ~/$home_rel -> $repo_rel"
    ok "linked ~/$home_rel -> $repo_rel"
  else
    fail "link ~/$home_rel"
  fi
}

for_each_link() {  # $1 = adopt_one | link_one
  local entry
  for entry in "${LINKS[@]}"; do
    "$1" "${entry%%:*}" "${entry#*:}"
  done
}

fix_ssh_perms() {
  [[ -d "$HOME/.ssh" ]] && chmod 700 "$HOME/.ssh" || true
}

# Point git at the versioned hooks dir (gitleaks secret scan on commit).
enable_git_hooks() {
  try "git hooks (gitleaks pre-commit)" git -C "$REPO_DIR" config core.hooksPath githooks
  command -v gitleaks >/dev/null 2>&1 || \
    warn "gitleaks not installed — pre-commit hook will refuse commits until: brew install gitleaks"
}
