{
  lib,
  pkgs,
  config,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    niri
    xwayland-satellite
    swaylock
  ];
  home.file.".config/niri" = {
    source = config.lib.file.mkOutOfStoreSymlink "/nixos-config/dotfiles/niri";
    recursive = true;
  };

  programs.uwsm = {
    enable = true;
    waylandCompositors.niri = {
      prettyName = "NIRI";
      comment = "Niri compositor managed by UWSM";
      binPath = "/run/current-system/sw/bin/niri-session";
    };
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
    configPackages = [ pkgs.niri ];
    config.niri = {
      default = [
        "gnome"
        "gtk"
      ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      "org.freedesktop.impl.portal.Access" = [ "gtk" ];
      "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
    };
  };

  security.polkit.enable = true;
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  security.pam.services.swaylock = { };
  security.pam.services.hyprlock = { };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    OZONE_PLATFORM = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    QT_STYLE_OVERRIDE = "kvantum";
    SDL_VIDEODRIVER = "wayland";
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "niri";
    DESKTOP_SESSION = "niri";
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.niri}/bin/niri-session";
        user = "dom";
      };
    };
  };

  programs.ssh.startAgent = true;
  services.gnome.gcr-ssh-agent.enable = false;

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  services.dbus.enable = true;

  systemd.user.services.gnome-keyring.serviceConfig.ExecStart = lib.mkForce [
    ""
    "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --start --components=secrets,pkcs11"
  ];
}
