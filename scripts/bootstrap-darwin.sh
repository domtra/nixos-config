#!/usr/bin/env bash
set -euo pipefail

# Minimal bootstrap for macOS host.
# 1) Install Nix (Determinate Systems or Flox installer) to get flakes.
# 2) Clone this repo under ~/config if not already present.

REPO_DIR="${HOME}/config/nixos-config"

if [ ! -d "${REPO_DIR}" ]; then
  mkdir -p "$(dirname "${REPO_DIR}")"
  git clone https://github.com/your/repo.git "${REPO_DIR}"
fi

cd "${REPO_DIR}"

# Build and switch the nix-darwin configuration
nix build ".#darwinConfigurations.macbook-pro-m4.system"
./result/sw/bin/darwin-rebuild switch --flake ".#macbook-pro-m4"
