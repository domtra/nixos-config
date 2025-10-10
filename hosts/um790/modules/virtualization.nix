{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Enable libvirt virtualization
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = false;
      swtpm.enable = true; # TPM support for VMs
    };
  };

  # Enable virt-manager GUI
  programs.virt-manager.enable = true;

  # Add user to libvirtd group
  users.users.dom.extraGroups = [ "libvirtd" ];

  # Install virtualization packages
  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    spice
    spice-gtk
    spice-protocol
    win-virtio # Windows VirtIO drivers
    win-spice # Windows spice tools
    swtpm # Software TPM emulator
  ];

  # Enable spice-vdagentd for better VM integration
  services.spice-vdagentd.enable = true;

  # VM networking (default NAT setup)
  # The default libvirt network (virbr0) provides NAT connectivity
  # VMs can access the internet and host services
  # Host firewall rules in firewall.nix handle external access

  # UEFI/TPM VM Creation Notes:
  # 1. Create VM in virt-manager
  # 2. Before installation, go to VM details:
  #    - Overview → Firmware: UEFI x86_64 (OVMF)
  #    - Add Hardware → TPM (Type: Emulated, Version: 2.0)
  # 3. This enables modern features like Secure Boot and TPM for Windows 11

  # Useful virsh commands:
  # virsh list --all                    # List all VMs
  # virsh start <vm-name>               # Start VM
  # virsh shutdown <vm-name>            # Graceful shutdown
  # virsh destroy <vm-name>             # Force stop
  # virsh undefine <vm-name>            # Delete VM definition
  # virsh net-list                      # List networks
  # virsh vol-list default              # List storage volumes
}

