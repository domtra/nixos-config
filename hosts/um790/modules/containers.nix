{ config, lib, pkgs, ... }:

{
  # Enable rootless Podman
  virtualisation.podman = {
    enable = true;
    # Docker compatibility layer (provides 'docker' command that uses Podman)
    dockerCompat = true;
    # Required for containers to communicate with each other
    defaultNetwork.settings.dns_enabled = true;
  };

  # Add user to podman group
  users.users.dom.extraGroups = [ "podman" ];

  # Install container tools
  environment.systemPackages = with pkgs; [
    distrobox      # Easy container management
    docker-client  # For remote Docker contexts only (no local dockerd)
    podman-compose # Docker Compose alternative for Podman
    dive          # Docker image analysis tool
  ];

  # Documentation: Remote Docker Swarm Usage
  
  # Create a Docker SSH context to connect to remote Docker Swarm:
  # docker context create remote-swarm --docker "host=ssh://user@your-swarm-manager.example.com"
  #
  # Deploy a stack to the remote swarm:
  # docker --context remote-swarm stack deploy -c docker-compose.yml mystack
  #
  # List remote contexts:
  # docker context ls
  #
  # Switch to remote context (makes it default):
  # docker context use remote-swarm
  #
  # View remote stack services:
  # docker --context remote-swarm stack services mystack
  #
  # Remove remote stack:
  # docker --context remote-swarm stack rm mystack

  # Note: This configuration provides Docker CLI for remote usage only.
  # No local Docker daemon is running. All container operations use Podman.
  # The 'docker' command is shimmed to use Podman for local operations.
  
  # Distrobox examples:
  # Create a Fedora container:
  # distrobox create -n fedora-dev --image fedora:latest
  #
  # Enter the container:
  # distrobox enter fedora-dev
  #
  # List containers:
  # distrobox list
  #
  # Remove container:
  # distrobox rm fedora-dev
}