{ config, lib, pkgs, ... }:

{
  # Enable power-profiles-daemon (not TLP)
  services.power-profiles-daemon.enable = true;

  # Ensure TLP is disabled (conflicts with power-profiles-daemon)
  services.tlp.enable = false;

  # AMD P-State driver is set in configuration.nix kernel params: amd_pstate=active

  # Set default power profile at boot
  systemd.services.set-default-power-profile = {
    description = "Set default power profile to balanced";
    wantedBy = [ "multi-user.target" ];
    after = [ "power-profiles-daemon.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.power-profiles-daemon}/bin/powerprofilesctl set balanced";
      RemainAfterExit = true;
    };
  };

  # Additional power management settings
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "schedutil"; # Good balance for AMD Zen4
  };

  # USB autosuspend tweaks (conservative for audio devices)
  services.udev.extraRules = ''
    # Disable autosuspend for Behringer UMC22 and similar USB audio devices
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1397", ATTR{power/autosuspend}="-1"
    
    # Disable autosuspend for Elgato Cam Link 4K
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0fd9", ATTR{idProduct}=="0066", ATTR{power/autosuspend}="-1"
  '';

  # Runtime power management for PCIe devices
  powerManagement.scsiLinkPolicy = "med_power_with_dipm";

  # BIOS Settings Recommendations (document in comments):
  # Enable these in BIOS/UEFI when available:
  # - PCIe ASPM (Active State Power Management)
  # - ErP Ready (Energy-related Products)
  # - Resizable BAR (for better GPU performance)
  # These settings help with idle power consumption and overall efficiency.
}