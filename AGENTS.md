Agent Quick Reference (nixos-config repo)

1. Build / switch commands:
   - Full rebuild: nixos-rebuild switch --flake .#um790
   - Dry-run diff: nixos-rebuild build --flake .#um790 (then inspect ./result)
   - Home config only: home-manager switch --flake .#dom@um790
   - Update inputs: nix flake update ; rebuild afterward
2. Repro shell: nix develop (if a devShell is later added; none now)
3. Tests: No explicit test suite; validate by building system + confirming critical services start (future: add `nixos-rebuild test`). Single "test" = build targeted module then full switch.
4. Linting / formatting: Use nix fmt (nixpkgs-fmt) if available; otherwise keep attributes sorted, 2-space indent, trailing commas on lists/sets, lowercase option names.
5. Imports: Group: (a) flake inputs, (b) local modules, (c) inline option overrides. Keep flake.nix outputs minimal.
6. Naming: Use kebab-case for file/module names (e.g. audio-bluetooth.nix). Attribute names follow NixOS option hierarchy; avoid redundant prefixes.
7. Types: Prefer explicit lists ([]) and attribute sets { } with clear scoping; avoid deprecated pkgs.* aliases; qualify packages via pkgs.<name> inside environment.systemPackages.
8. Variables: Do not introduce let-binding unless reused >=2 times. Keep local bindings near usage.
9. Error handling: Build failures are primary feedback. After adding options run: nix flake check (add checks later). Ensure experimental-features stay consistent across flake & configuration.
10. Secrets: Do NOT commit secrets; use agenix/sops in future (currently none). Never embed private SSH keys.
11. Upgrades: After nix flake update, review flake.lock diff; rebuild; if kernel changes, reboot; verify essential hardware (audio, bluetooth, GPU) operates.
12. Modules: Each hosts/um790/modules/*.nix should stay single-responsibility; new modules go in same directory and be imported in configuration.nix.
13. Hyprland / dotfiles: GUI & user-level configs live under dotfiles/ managed via stow; keep system vs user separation.
14. Git: Default branch main; pull.rebase=false; do not force-push main. Commit messages: type(scope): summary (e.g. feat(audio): enable pipewire tweak).
15. Editor assumptions: Neovim; ensure EDITOR env stays nvim; avoid editor-specific modelines.
16. Performance: Prefer stable options; only use linuxPackages_latest intentionally; document rationale in comment when deviating.
17. Consistency: Keep home-manager settings minimal; push app-specific detail to dotfiles to avoid drift.
18. Future tests wishlist (not yet implemented): service enablement, container start, hibernate resume.
19. No Cursor/Copilot rule files detected (.cursor/rules, .cursorrules, .github/copilot-instructions.md absent) as of creation.
20. When uncertain: build first (nixos-rebuild build), then switch; never edit flake.lock manually.
