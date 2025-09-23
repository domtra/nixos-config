# Hardware/filesystems template for Apple Silicon (Asahi) with LUKS + Btrfs
#
# After partitioning on the installer, replace the placeholders below with
# the actual identifiers, then build the system.

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Kernel/initrd basics (nvme + usb storage are sufficient here)
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # Encrypted root (dm-crypt LUKS2)
  # Replace with the LUKS UUID of the Linux root partition, e.g. from:
  #   blkid -s UUID -o value /dev/nvme0n1p5
  boot.initrd.luks.devices.cryptroot = {
    device = "/dev/disk/by-uuid/LUKS-UUID-REPLACE"; # <-- set me
    allowDiscards = true;
  };

  # Btrfs subvolumes on the opened mapper device
  # Replace with the Btrfs filesystem UUID from:
  #   blkid -s UUID -o value /dev/mapper/cryptroot
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/BTRFS-UUID-REPLACE"; # <-- set me
    fsType = "btrfs";
    options = [ "subvol=@root" "compress=zstd" "noatime" ];
  };
  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/BTRFS-UUID-REPLACE"; # <-- set me
    fsType = "btrfs";
    options = [ "subvol=@home" "compress=zstd" ];
  };
  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/BTRFS-UUID-REPLACE"; # <-- set me
    fsType = "btrfs";
    options = [ "subvol=@nix" "compress=zstd" "noatime" ];
  };
  fileSystems."/var/log" = {
    device = "/dev/disk/by-uuid/BTRFS-UUID-REPLACE"; # <-- set me
    fsType = "btrfs";
    options = [ "subvol=@log" "compress=zstd" ];
  };
  fileSystems."/.snapshots" = {
    device = "/dev/disk/by-uuid/BTRFS-UUID-REPLACE"; # <-- set me
    fsType = "btrfs";
    options = [ "subvol=@snapshots" "compress=zstd" ];
  };

  # Mount the Asahi-provisioned EFI System Partition at /boot.
  # Obtain PARTUUID via:
  #   cat /proc/device-tree/chosen/asahi,efi-system-partition
  fileSystems."/boot" = {
    device = "/dev/disk/by-partuuid/ASAHI-ESP-PARTUUID-REPLACE"; # <-- set me
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  # No swap partition; zramSwap is enabled in host config
  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}

