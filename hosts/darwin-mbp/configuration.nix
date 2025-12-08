{ pkgs, ... }:

{
  nix = {
    # Determinate Systems manages the daemon; keep nix-darwin hands-off.
    enable = false;
  };
  nixpkgs.config.allowUnfree = true;

  users.users.dom = {
    home = "/Users/dom";
    shell = pkgs.fish;
  };

  system.primaryUser = "dom";

  # Shells
  programs.fish.enable = true;
  programs.zsh.enable = true;

  environment.shells = with pkgs; [
    bashInteractive
    zsh
    fish
  ];

  # Homebrew GUI apps for the host
  homebrew = {
    enable = true;
    casks = [
      "1password"
      "google-chrome"
      "google-chrome@canary"
      "firefox"
      "raycast"
      "ghostty"
      "moonlight"
      "nikitabobko/tap/aerospace"
      "hammerspoon"
      "utm"
      # "logi-options+"
      "mac-mouse-fix"
      "lm-studio"
      "macwhisper"
    ];
    onActivation.cleanup = "uninstall";
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  system.stateVersion = 5;
}
