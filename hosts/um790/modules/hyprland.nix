{ config, lib, pkgs, ... }:

{
  # Enable Hyprland wayland compositor
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
  };

  # XDG Desktop Portal for Hyprland (only Hyprland portal, no wlr)
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
  };

  environment.variables = {
    XDG_CURRENT_DESKTOP = "Hyprland";
    QT_QPA_PLATFORMTHEME = "qt6ct";
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
  # NOTE: Avoid overriding plymouth-quit ordering here; doing so can deadlock
  # boot right after LUKS unlock (splash stays forever, no TTY switch). If you
  # need plymouth tweaks, do it in a dedicated module and test carefully.
  # If you simply want a cleaner auto-login experience, rely on greetd below.

  security.pam.services.hyprlock = {};

  # Session variables for Wayland
  environment.sessionVariables = {
    # Hint electron apps to use Wayland
    NIXOS_OZONE_WL = "1";
    # Qt Wayland support
    QT_QPA_PLATFORM = "wayland;xcb";
    # SDL Wayland support
    SDL_VIDEODRIVER = "wayland";
    # XDG desktop portal
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
  # Ensure tools see proper session with uwsm
  DESKTOP_SESSION = "Hyprland";
  GDK_BACKEND = "wayland,x11";
  GTK_USE_PORTAL = "1";
  # 1Password SSH agent
  SSH_AUTH_SOCK = "$HOME/.1password/agent.sock";
  };

  # Enable greetd display manager for Wayland login
  services.greetd = {
    enable = true;
    
    settings = {
      # Auto-login user 'dom' into Hyprland via UWSM every boot.
      # Use lowercase hyprland desktop entry; pass with -- to disambiguate.
      default_session = {
        command = "${pkgs.uwsm}/bin/uwsm start -- hyprland-uwsm.desktop";
        user = "dom";
      };
      # For a tui greeter instead, replace above with:
      # default_session = {
      #   command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd 'uwsm start -- hyprland-uwsm.desktop'";
      #   user = "greeter";
      # };
    };
  };

  # 1Password (GUI + SSH agent)
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "dom" ];
  };

  # Disable SSH agent to avoid conflict with 1Password
  programs.ssh.startAgent = false;

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  services.dbus.enable = true;

  # Force gnome-keyring to start WITHOUT SSH component
  systemd.user.services.gnome-keyring.serviceConfig.ExecStart = lib.mkForce [
    "" # Clear existing ExecStart
    "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --start --components=secrets,pkcs11"
  ];

  # Note: Wayland helpers (wl-clipboard, grim, slurp, swappy) are installed
  # via Home Manager to avoid duplication.
  # Hyprland configuration files are managed via GNU Stow in dotfiles/.
}
