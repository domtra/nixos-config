{
  lib,
  pkgs,
  ...
}:

{
  # Install Niri compositor
  environment.systemPackages = with pkgs; [
    niri
    # For X11 apps under Wayland; Niri integrates with it on-demand
    xwayland-satellite
  ];

  programs.uwsm = {
    enable = true;
    waylandCompositors.niri = {
      prettyName = "NIRI";
      comment = "Hyprland compositor managed by UWSM";
      binPath = "/run/current-system/sw/bin/niri-session";
    };
  };

  # XDG Desktop Portal for Niri
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    # For Niri, prefer GNOME portal for Screencast (window/fullscreen)
    # and GTK portal for FileChooser to avoid pulling in Nautilus.
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
    configPackages = [ pkgs.niri ]; # installs niri’s DE-specific portals.conf
    # xdg-desktop-portal >= 1.17 warns when multiple backends are present
    # without a declared default. Set a compositor-specific config so
    # Chromium/Firefox see proper window/fullscreen share options.
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

  # Polkit authentication agent
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

  # Session variables for Wayland
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    OZONE_PLATFORM = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    # QT_QPA_PLATFORM = "wayland;xcb";
    QT_STYLE_OVERRIDE = "kvantum";
    SDL_VIDEODRIVER = "wayland";
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "niri";
    DESKTOP_SESSION = "niri";
    # GDK_BACKEND = "wayland,x11";
    # 1Password SSH agent
    SSH_AUTH_SOCK = "$HOME/.1password/agent.sock";
  };

  # Use greetd to start a Niri session
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        # Use UWSM to launch the compositor via its desktop entry if available
        # command = "${pkgs.niri}/bin/niri-session";
        # command = "${pkgs.uwsm}/bin/uwsm start -S -- niri-session";
        command = "${pkgs.uwsm}/bin/uwsm start -- niri-uwsm.desktop";
        user = "dom";
      };
      # To use a TUI greeter instead, replace with:
      # default_session = {
      #   command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd 'uwsm start -- niri.desktop'";
      #   user = "greeter";
      # };
    };
  };

  # environment.sessionVariables.NIRI_DISABLE_SYSTEM_MANAGER_NOTIFY = "1";

  # 1Password (GUI + SSH agent)
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "dom" ];
  };

  # Disable OpenSSH agent to avoid conflict with 1Password
  programs.ssh.startAgent = false;

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  services.dbus.enable = true;

  # Force gnome-keyring to start WITHOUT SSH component
  systemd.user.services.gnome-keyring.serviceConfig.ExecStart = lib.mkForce [
    ""
    "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --start --components=secrets,pkcs11"
  ];
}
