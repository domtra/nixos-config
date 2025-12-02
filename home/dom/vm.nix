{
  config,
  pkgs,
  lib,
  ...
}:

let
  isLinux = pkgs.stdenv.isLinux;
in
{
  # Wayland/GUI helpers and desktop apps for the NixOS VM
  home.packages = lib.optionals isLinux (
    with pkgs; [
      wl-clipboard
      grim
      slurp
      swappy
      swaybg
      alacritty
      kitty
      nerd-fonts.hasklug
      nerd-fonts.caskaydia-mono
      mako
      wofi
      waybar
      evince
      imv
      mpv
      libreoffice
      pinta
      localsend
      nautilus
      sushi
      chromium
      bibata-cursors
      adwaita-icon-theme
      yaru-theme
      satty
    ]
  );

  home.sessionVariables = {
    TERMINAL = "alacritty";
    NIXOS_OZONE_WL = "1";
    NH_HOME_FLAKE = "/home/dom/nixos-config#dom@vm-fusion";
    NH_OS_FLAKE = "/home/dom/nixos-config#vm-fusion";
    SQLITE_CLIB_PATH = "${pkgs.sqlite.out}/lib/libsqlite3.so";
  };

  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Yaru-blue";
      package = pkgs.yaru-theme;
    };
  };

  dconf.enable = true;
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Adwaita-dark";
      icon-theme = "Yaru-blue";
    };
  };
}
