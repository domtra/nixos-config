{ pkgs, lib, ... }:
{
  # Point nh to this host's flake outputs
  home.sessionVariables = {
    NH_HOME_FLAKE = "/home/dom/nixos-config#dom@mba-m1";
    NH_OS_FLAKE   = "/home/dom/nixos-config#mba-m1";
  };

  # Replace the big package set with an aarch64‑safe subset
  home.packages = lib.mkForce (with pkgs; [
    # Core CLI/dev
    git stow gcc tree-sitter nixfmt nixd statix deadnix
    ripgrep fd tree wget curl unzip jq yq glow
    htop btop zoxide fzf bat eza tldr dust fastfetch whois xmlstarlet plocate gum

    # Wayland helpers and terminal
    wl-clipboard grim slurp swappy swaybg alacritty waybar mako wofi

    # Desktop apps (safe on aarch64)
    evince imv mpv libreoffice localsend nautilus sushi

    # Fonts/themes
    nerd-fonts.hasklug nerd-fonts.caskaydia-mono adwaita-icon-theme yaru-theme

    # Media/tools
    imagemagick ffmpegthumbnailer pamixer playerctl

    # Dev tools
    gh lazygit lazydocker nodejs

    # Misc
    seahorse libsecret killall
    ghostty
    home-assistant-cli
  ]);
}
