{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/niri.nix
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      systemd-boot.consoleMode = "0";
    };

    # Allow running x86_64 binaries inside the aarch64 VM
    binfmt.emulatedSystems = [ "x86_64-linux" ];

    kernelPackages = pkgs.linuxPackages_latest;
  };

  services.fstrim.enable = true;

  networking = {
    hostName = "vm-fusion";
    useDHCP = false;
    interfaces.enp2s0.useDHCP = true;
    firewall.enable = false;
  };

  services.resolved = {
    enable = true;
    fallbackDns = [
      "1.1.1.1"
      "9.9.9.9"
    ];
  };

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

  users.users.dom = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "input"
      "podman"
      "uinput"
    ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOmJYyS8GjE/Fx2eHPGX6SiezubYiY2xVZU3zAXeENRY dominik@bleech.de"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "yes";
    };
  };

  programs.fish.enable = true;
  programs.nix-ld.enable = true;
  programs.nh.enable = true;

  # Guest integration for VMware (clipboard, resolution, time sync)
  # virtualisation.vmware.guest.enable = true;

  # systemd.user.services.vmware-user = {
  #   description = "VMware user agent";
  #   serviceConfig.ExecStart = "${pkgs.open-vm-tools}/bin/vmware-user-suid-wrapper";
  #   wantedBy = [ "graphical-session.target" ];
  # };
  # # services.vmware-vmblock-fuse.enable = true; # provides /proc/fs/vmblock/dev

  # hardware.uinput.enable = true; # creates /dev/uinput and group

  hardware.graphics.enable = true;

  # Podman + Docker compat for dev work
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      substituters = [
        "https://cache.nixos.org/"
        "https://walker-git.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "walker-git.cachix.org-1:vmC0ocfPWh0S/vRAQGtChuiZBTAe4wiKDeyyXM0/7pM="
      ];
      trusted-users = [
        "root"
        "dom"
      ];
    };
    gc.automatic = true;
    gc.dates = "weekly";
    gc.options = "--delete-older-than 30d";
  };

  # Mount host shares provided by VMware
  fileSystems."/host/Downloads" = {
    device = ".host:/Downloads";
    fsType = "fuse./run/current-system/sw/bin/vmhgfs-fuse";
    options = [
      "umask=22"
      "uid=1000"
      "gid=1000"
      "allow_other"
      "auto_unmount"
      "defaults"
    ];
  };

  fileSystems."/host/VMShare" = {
    device = ".host:/VMShare";
    fsType = "fuse./run/current-system/sw/bin/vmhgfs-fuse";
    options = [
      "umask=22"
      "uid=1000"
      "gid=1000"
      "allow_other"
      "auto_unmount"
      "defaults"
    ];
  };

  # Ensure mountpoints exist
  systemd.tmpfiles.rules = [
    "d /host 0755 root root -"
    "d /host/Downloads 0755 dom users -"
    "d /host/VMShare 0755 dom users -"
  ];

  # Power management suitable for VMs
  powerManagement.enable = true;

  services.gvfs.enable = true;

  system.stateVersion = "24.11";
}
