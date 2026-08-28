#!/usr/bin/env bash
# Run ONCE on the machine you're backing up (i.e. your current Mac).
#
# Moves each existing config into the repo and symlinks it back, so the live
# files and the repo checkout become the same files. From then on you edit
# configs exactly where they've always been — git just sees the changes.
#
# Safe to re-run: symlinked entries and missing candidates are skipped.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

info "adopting existing configs into $REPO_DIR"
for_each_link adopt_one
fix_ssh_perms
enable_git_hooks

summary

info "next steps:"
echo "    1. ./backup.sh          # generate Brewfile + toolchain manifests"
echo "    2. git -C \"$REPO_DIR\" status   # review what got captured"
echo "    3. git add -A && git commit && git push"

[[ "$N_FAIL" -eq 0 ]]  # exit 1 if anything failed
