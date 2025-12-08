{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "virtio_pci"
    "virtio_blk"
    "virtio_net"
    "virtio_gpu"
    "usbhid"
    "sr_mod"
  ];
  # Load virtio GPU early so greetd/Niri get a ready DRM device
  boot.initrd.kernelModules = [ "virtio_gpu" ];
  boot.kernelModules = [ "virtio_gpu" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  swapDevices = [
    { device = "/dev/disk/by-label/swap"; }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
