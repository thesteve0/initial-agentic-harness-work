#!/usr/bin/env bash
# Creates symlinks from each harness's default config location into this repo.
# Run once after cloning. Add new entries as config files are discovered.

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Goose — fill in paths after running step 2 of TODO.md
# ln -sf "$REPO_ROOT/configs/goose/<filename>" "<goose-config-path>"

# Hermes Agent — fill in after installing Hermes
# ln -sf "$REPO_ROOT/configs/hermes/config.yaml" "$HOME/.hermes/config.yaml"

# OpenCode
# ln -sf "$REPO_ROOT/configs/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"

echo "Symlinks created. Run 'ls -la' on each config location to verify."
