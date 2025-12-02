# macOS Host (MacBook Pro M4 Pro)

Managed with nix-darwin + Home Manager.

- Homebrew casks: 1Password, Chrome, Chrome Canary, Firefox, Raycast.
- CLIs via Nix: devbox, nh, git/ripgrep/fd/direnv/gh, etc. (from `home/dom/common.nix` + `home/dom/host.nix`).
- Touch ID for sudo enabled.
- Primary user: `dom` with fish shell.

Bootstrap:
1. Install Nix (Determinate installer recommended) with flakes enabled.
2. Clone repo to `~/config/nixos-config`.
3. Run:
   ```
   nix build .#darwinConfigurations.macbook-pro-m4.system
   ./result/sw/bin/darwin-rebuild switch --flake .#macbook-pro-m4
   ```

Afterwards:
- `home-manager switch --flake .#dom@macbook-pro-m4` if you need to rebuild only HM.
