{ config, lib, pkgs, ... }:

{
  # Enable strict firewall - workstation should not expose services
  networking.firewall = {
    enable = true;
    
    # No inbound ports open by default
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];
    
    # Disable ping responses for security
    allowPing = false;
    
    # Log refused connections for debugging
    logRefusedConnections = true;
    
    # IPv6 filtering (default behavior is fine)
    # The firewall automatically handles IPv6 with the same rules
  };

  # Documentation for temporarily opening ports:
  # To temporarily open a port (e.g., for SSH), add it to allowedTCPPorts:
  # networking.firewall.allowedTCPPorts = [ 22 ];
  # Then rebuild: sudo nixos-rebuild switch --flake .#um790
  #
  # Container and libvirt networking:
  # - Podman containers use user networking by default (no firewall interaction)
  # - For libvirt VMs, the default virbr0 bridge works through NAT
  # - If exposing VM services, consider port forwarding or specific firewall rules
}