{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/firewall.nix
    ./modules/graphics.nix
    ./modules/hyprland.nix
    ./modules/power.nix
    ./modules/audio-bluetooth.nix
    ./modules/containers.nix
    ./modules/virtualization.nix
    ./modules/firmware.nix
    ./modules/snapshots.nix
  ];

  # Boot configuration
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    
    # Use latest kernel (>= 6.11)
    kernelPackages = pkgs.linuxPackages_latest;
    
    # AMD P-State for better power management
    kernelParams = [ "amd_pstate=active" ];
    
    # Enable resume from encrypted swap for hibernation
    resumeDevice = "/dev/mapper/pool-swap";

    # Allow TRIM through LUKS (nice-to-have on NVMe)
    initrd.luks.devices.cryptroot.allowDiscards = true;
  };

  # Filesystem support
  services.fstrim.enable = true;

  # Networking
  networking = {
    hostName = "um790";
    networkmanager.enable = true;
    networkmanager.wifi.powersave = true;
  };

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

  # User configuration
  users.users.dom = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "libvirtd" "kvm" "video" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      # Add your SSH public keys here
    ];
  };

  # Enable sudo for wheel group
  security.sudo.wheelNeedsPassword = true;

  # Nix configuration
  hardware.enableRedistributableFirmware = true;

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    
    # Weekly garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Essential system packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    htop
  ];

  # Enable programs
  programs = {
    zsh.enable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "24.11";
}