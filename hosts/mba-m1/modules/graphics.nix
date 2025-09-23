{ pkgs, ... }:
{
  # Enable modern graphics stack; Asahi overlay supplies AGX driver via Mesa
  hardware.graphics = {
    enable = true;
    # 32-bit not relevant on aarch64
  };

  environment.systemPackages = with pkgs; [
    mesa-demos
    vulkan-tools
  ];
}

