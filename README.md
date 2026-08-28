# dotfiles

Machine config backup + rebuild for my Mac. The model is simple: live configs
are **symlinks into this repo**, so editing `~/.config/nvim/...` edits the repo
checkout directly and `git status` shows drift. Anything that can't be a
symlink (installed packages, toolchains, macOS defaults) is captured as a
generated manifest by `backup.sh`.

## First-time setup (on the machine being backed up)

```sh
git clone git@github.com:<you>/dotfiles.git ~/dotfiles
cd ~/dotfiles
./adopt.sh        # move existing configs into the repo, symlink them back
./backup.sh       # generate Brewfile, toolchain manifests, macOS defaults
git add -A && git status   # REVIEW — especially ssh/config and claude/
git commit -m "initial import" && git push
```

Then in iTerm2: Settings → General → Preferences → check **Load preferences
from a custom folder**, point it at `~/dotfiles/iterm2`, and choose
**Save changes: Automatically**.

## Rebuilding a fresh machine

```sh
git clone git@github.com:<you>/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./bootstrap.sh
```

Installs Xcode CLT → Homebrew → everything in `Brewfile` → oh-my-zsh (+ custom
plugins referenced by `.zshrc`) → symlinks all configs → rust/cargo/npm/go/
sdkman toolchains → macOS defaults → iTerm2 prefs. Ends with a checklist of
the login-based steps it can't do for you (ssh keys, Tailscale, OrbStack,
Claude/Codex/gh auth, JetBrains Settings Sync).

## Ongoing use

- Edit configs where they live (`~/.zshrc`, `~/.config/nvim`, ...) — they're
  already the repo. Commit when it suits you.
- After installing/removing brew packages or global tools, rerun
  `./backup.sh --push` to refresh the manifests and push in one go.
- Added a config for a new tool? Add a line to `LINKS` in `lib/common.sh` and
  rerun `./adopt.sh`.

## What's where

| Path | Contents |
|---|---|
| `Brewfile` | generated: formulae, casks, taps, MAS apps, VS Code extensions |
| `zsh/` | `.zshrc`, `.zprofile`, `.p10k.zsh`, oh-my-zsh `custom/` (plugin clones excluded) |
| `nvim/` | the whole `~/.config/nvim` |
| `git/` | `~/.gitconfig` and/or `~/.config/git/{config,ignore}` |
| `ssh/config` | host aliases only — keys never enter this repo |
| `claude/` | `CLAUDE.md`, `settings.json`, `agents/`, `commands/`, extracted `mcp-servers.json`. **Not** skills or session state |
| `codex/` | `config.toml`, `AGENTS.md`. **Not** `auth.json` |
| `config/` | starship, tmux, lazygit, karabiner, bat, mise, direnv, gh (`config.yml` only) — whatever exists |
| `ideavim/` | `.ideavimrc` (IntelliJ proper syncs via JetBrains account) |
| `iterm2/` | iTerm2 prefs plist, loaded directly by iTerm |
| `macos/` | curated `defaults` capture/apply (`defaults.sh {capture|apply}`) |
| `manifests/` | generated: rustup, cargo, npm -g, go tools, sdkman, mise, crontab |
| `githooks/` | versioned git hooks — pre-commit runs gitleaks on staged changes |

## Deliberately excluded

Secrets of any kind (ssh keys, `gh` tokens, `auth.json`, `~/.claude.json`
OAuth state), shell history, Claude skills, Tailscale/OrbStack state (both are
login-based — the cask + a sign-in is the whole restore), plugin/package
caches. This repo is private, but the rule is: nothing in it should matter if
it leaked.

As a backstop, `adopt.sh`/`bootstrap.sh` set `core.hooksPath` to `githooks/`,
whose pre-commit hook runs [gitleaks](https://github.com/gitleaks/gitleaks)
over staged changes and refuses the commit (fails closed if gitleaks isn't
installed: `brew install gitleaks`). Bypass deliberately with
`git commit --no-verify`.
