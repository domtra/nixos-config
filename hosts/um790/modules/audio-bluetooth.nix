{ config, lib, pkgs, ... }:

{
  # PipeWire audio system
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Real-time audio support
  security.rtkit.enable = true;

  # Bluetooth support
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true; # For better device compatibility
      };
    };
  };

  # Bluetooth manager GUI
  services.blueman.enable = true;

  # Add user to audio group
  users.users.dom.extraGroups = [ "audio" ];

  # Audio and video packages
  environment.systemPackages = with pkgs; [
    # Audio utilities
    pavucontrol
    alsa-utils
    pulseaudio # for pactl commands
    
    # Video utilities for Cam Link
    v4l-utils
    
    # Bluetooth utilities
    bluez
    bluez-tools
  ];

  # Hardware-specific notes and configurations:
  
  # Apple Magic Keyboard:
  # - Touch ID functionality is NOT supported on Linux
  # - Regular keyboard functions work normally
  # - Pair via Bluetooth settings or bluetoothctl
  
  # Apple Magic Trackpad:
  # - Works with basic functionality
  # - Newest USB-C model requires kernel >= 6.11 for full support
  # - Multi-touch gestures may require additional configuration
  
  # Behringer UMC22:
  # - USB Audio Class compliant, no drivers needed
  # - Appears as USB audio device
  # - USB autosuspend disabled (kept powered) in power.nix for stable operation
  
  # Elgato Cam Link 4K:
  # - UVC (USB Video Class) compatible
  # - Appears as /dev/video* device
  # - Use with OBS, ffmpeg, or other video capture software
  # - USB autosuspend disabled in power.nix for stable operation

  # Enable media keys and special function keys
  services.udev.extraRules = ''
    # Apple Magic Keyboard media keys
    KERNEL=="hidraw*", ATTRS{idVendor}=="05ac", MODE="0664", GROUP="input"
    
    # Apple Magic Trackpad
    KERNEL=="hidraw*", ATTRS{idVendor}=="05ac", ATTRS{idProduct}=="030e", MODE="0664", GROUP="input"
  '';
}