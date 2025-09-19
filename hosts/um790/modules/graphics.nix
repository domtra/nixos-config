{ config, lib, pkgs, ... }:

{
  # Modern graphics support for Radeon 780M (NixOS 24.11+)
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # For 32-bit applications and games
    
    # Mesa drivers for AMD graphics
    extraPackages = with pkgs; [
      mesa
      mesa.opencl # OpenCL via Rusticl
      # rocm-opencl-icd # (optional) Only if a specific app demands ROCm
      # rocm-opencl-runtime
    ];
    
    # 32-bit Mesa drivers
    extraPackages32 = with pkgs; [
      driversi686Linux.mesa
    ];
  };

  # VA-API hardware acceleration
  environment.systemPackages = with pkgs; [
    # Graphics diagnostics
    glxinfo
    vulkan-tools
    vulkan-loader
    vulkan-validation-layers
    
    # VA-API tools
    libva-utils
    
    # Mesa utilities
    mesa-demos
  ];

  # Steam disabled by default (uncomment if needed)
  # programs.steam = {
  #   enable = true;
  #   remotePlay.openFirewall = true;
  #   dedicatedServer.openFirewall = true;
  # };

  # Environment variables for optimal AMD graphics
  environment.sessionVariables = {
    # Enable VA-API acceleration
    LIBVA_DRIVER_NAME = "radeonsi";
    # Enable VDPAU acceleration  
    VDPAU_DRIVER = "radeonsi";
    RUSTICL_ENABLE = "radeonsi";
  };
}
