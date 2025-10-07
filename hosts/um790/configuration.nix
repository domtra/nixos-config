{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/firewall.nix
    ./modules/graphics.nix
    ./modules/niri.nix
    ./modules/power.nix
    ./modules/audio-bluetooth.nix
    ./modules/containers.nix
    ./modules/virtualization.nix
    ./modules/firmware.nix
    ./modules/snapshots.nix
    ../../modules/common/system-packages.nix
  ];

  # Boot configuration
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      systemd-boot.consoleMode = "max";
    };

    plymouth.enable = true;
    # Choose a theme (built-ins: spinner, bgrt, fade-in, tribar, details, text)
    # plymouth.theme = "bgrt"; # shows firmware logo if available; falls back gracefully

    plymouth.themePackages = [ pkgs.catppuccin-plymouth ];
    plymouth.theme = "catppuccin-macchiato";
    # Disable vendor logo overlay by pointing to a 1x1 transparent PNG
    # (Plymouth expects an absolute path; using a derivation ensures a valid
    # store path while effectively hiding the logo.)
    plymouth.logo =
      pkgs.runCommand "transparent-plymouth-logo.png"
        {
          nativeBuildInputs = [ pkgs.imagemagick ];
        }
        ''
          convert -size 1x1 xc:none png:$out
        '';

    # Use latest kernel (>= 6.11)
    kernelPackages = pkgs.linuxPackages_latest;
    consoleLogLevel = 3;
    # AMD P-State for better power management
    kernelParams = [
      "amd_pstate=active"
      "quiet"
      "splash"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
      "vt.global_cursor_default=0"
      "plymouth.use-simpledrm"
    ];
    # kernelParams = [ "amd_pstate=active" "quiet" "splash" "loglevel=3" "udev.log_priority=3" ];
    extraModprobeConfig = ''
      options hid_apple fnmode=2
    '';

    # Enable initrd with systemd so Plymouth renders the LUKS prompt
    initrd.systemd.enable = true;

    # Enable resume from encrypted swap for hibernation
    #    resumeDevice = "/dev/mapper/pool-swap";

    # Allow TRIM through LUKS (nice-to-have on NVMe)
    initrd.luks.devices.cryptroot.allowDiscards = true;
  };

  # Filesystem support
  services.fstrim.enable = true;

  # Enable GVFS for better file management
  services.gvfs.enable = true;

  services.printing = {
    enable = true;
    drivers = with pkgs; [
      cups-filters
      cups-browsed
    ];
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Enable thunderbolt support
  # services.hardware.bolt.enable = true;

  # services.openssh = {
  #   enable = true;
  #   settings = {
  #     PasswordAuthentication = false;
  #     PermitRootLogin = "no";
  #   };
  #   openFirewall = true;
  # };

  # Networking
  networking = {
    hostName = "um790";
    networkmanager.enable = true;
    networkmanager.wifi.powersave = true;
    networkmanager.wifi.backend = "iwd";
    wireless.iwd.enable = true;
    # usePredictableInterfaceNames = true;
  };
  # disable the upstream 80-iwd.link that pins kernel names
  systemd.network.links."80-iwd" = lib.mkForce { };

  # services.udev.extraRules = ''
  #   # Allow WebHID (VIA) to access NuPhy keyboards over hidraw
  #   KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="19f5", MODE="0660", GROUP="input", TAG+="uaccess", TAG+="udev-acl"
  # '';

  # Locale and timezone
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = [
      pkgs.fcitx5-gtk
      pkgs.kdePackages.fcitx5-qt
      pkgs.libsForQt5.fcitx5-qt
    ];
  };

  # User configuration
  users.users.dom = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "libvirtd"
      "kvm"
      "video"
      "input"
    ];
    shell = pkgs.fish; # default login shell
    openssh.authorizedKeys.keys = [
      # Add your SSH public keys here
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOmJYyS8GjE/Fx2eHPGX6SiezubYiY2xVZU3zAXeENRY dominik@bleech.de"
    ];
  };

  # Enable sudo for wheel group
  security.sudo.wheelNeedsPassword = true;

  # Nix configuration
  hardware.enableRedistributableFirmware = true;

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;

      # Binary caches
      substituters = [
        "https://cache.nixos.org/"
        "https://walker-git.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "walker-git.cachix.org-1:vmC0ocfPWh0S/vRAQGtChuiZBTAe4wiKDeyyXM0/7pM="
      ];
    };

    # Weekly garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # System packages shared via common module (see ../../modules/common/system-packages.nix)

  # Enable programs
  programs = {
    fish.enable = true;
    nix-ld.enable = true;
    # keep zsh disabled; remove if no longer needed
    nh = {
      enable = true;
    };
  };

  # system (one option)
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-emoji
    noto-fonts-cjk-sans
    noto-fonts-extra
    font-awesome
  ];

  programs.kdeconnect.enable = true;
  programs.localsend.enable = true;

  # Location services for apps like darkman (Home Manager)
  # Required when `services.darkman.settings.usegeoclue = true;` is set.
  services.geoclue2.enable = true;
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "24.11";
}
