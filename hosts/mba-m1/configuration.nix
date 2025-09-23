{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    # Hardware + filesystems live in this host's hardware-configuration.nix
    ./hardware-configuration.nix
    # Reuse generic modules from UM790 where safe
    ../um790/modules/hyprland.nix
    ../um790/modules/audio-bluetooth.nix
    ../um790/modules/containers.nix
    ../um790/modules/firewall.nix
    ../um790/modules/power.nix
    ../um790/modules/firmware.nix
    ../um790/modules/snapshots.nix
    # Apple‑silicon graphics settings
    ./modules/graphics.nix
  ];

  # Boot on Apple Silicon via Asahi's UEFI environment
  boot = {
    loader = {
      systemd-boot.enable = true;
      # Do not touch EFI variables; Asahi's UEFI handles picker/entries
      efi.canTouchEfiVariables = false;
      systemd-boot.consoleMode = "max";
    };

    # Render unlock prompts nicely in initrd
    initrd.systemd.enable = true;
    # If root mount fails, allow an emergency shell without a password
    initrd.systemd.emergencyAccess = true;

    # Allow TRIM through LUKS (safe on NVMe and helps longevity)
    initrd.luks.devices.cryptroot.allowDiscards = true;
  };

  # Filesystem and swap policy
  services.fstrim.enable = true;
  zramSwap = {
    enable = true;
    memoryPercent = 50; # laptop-friendly; no hibernation on Asahi
  };

  # Networking: prefer iwd; NM uses it as backend
  networking = {
    hostName = "mba-m1";
    networkmanager.enable = true;
    networkmanager.wifi.backend = "iwd";
    networkmanager.wifi.powersave = true;
    wireless.iwd.enable = true;
  };
  # Avoid upstream iwd .link pinning
  systemd.network.links."80-iwd" = lib.mkForce { };

  # Time/locale (match your desktop)
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

  # Desktop bits kept minimal; reuse user-level GUI from dotfiles
  services.gvfs.enable = true;

  # User
  users.users.dom = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "input" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOmJYyS8GjE/Fx2eHPGX6SiezubYiY2xVZU3zAXeENRY dominik@bleech.de"
    ];
  };

  security.sudo.wheelNeedsPassword = true;

  # Asahi module handles kernel/boot glue. Firmware strategy:
  # - Initial: build with --impure so module can import firmware from the EFI
  #   system partition. Later you may copy firmware into ./hosts/mba-m1/firmware
  #   and set hardware.asahi.peripheralFirmwareDirectory in a host-local module
  #   to make builds pure.
  hardware.enableRedistributableFirmware = true;

  programs = {
    fish.enable = true;
    nix-ld.enable = true;
    nh.enable = true;
  };

  # 1Password GUI is x86_64-only; avoid on aarch64
  programs._1password.enable = lib.mkForce false;
  programs._1password-gui.enable = lib.mkForce false;

  # Nix settings and caches
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      substituters = [
        "https://cache.nixos.org/"
        "https://walker-git.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "walker-git.cachix.org-1:vmC0ocfPWh0S/vRAQGtChuiZBTAe4wiKDeyyXM0/7pM="
      ];
    };
    gc.automatic = true;
    gc.dates = "weekly";
    gc.options = "--delete-older-than 30d";
  };

  # Essentials; keep system-level minimal
  environment.systemPackages = with pkgs; [
    vim wget curl git htop usbutils imagemagick
  ];

  # Important for stable state evolution
  system.stateVersion = "24.11";
}
