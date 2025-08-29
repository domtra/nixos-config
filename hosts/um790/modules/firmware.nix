{ config, lib, pkgs, ... }:

{
  # Enable firmware update daemon
  services.fwupd.enable = true;

  # Useful fwupd commands:
  # fwupdmgr get-devices          # List all devices that can be updated
  # fwupdmgr refresh              # Refresh metadata from LVFS
  # fwupdmgr get-updates          # Check for available updates
  # fwupdmgr update               # Update all devices
  # fwupdmgr update <device-id>   # Update specific device
  # fwupdmgr get-history          # Show update history

  # The Linux Vendor Firmware Service (LVFS) provides firmware updates
  # for various hardware components including:
  # - UEFI/BIOS updates
  # - SSD firmware
  # - USB device firmware
  # - Thunderbolt controllers
  # - And many other peripherals

  # Note: Always ensure adequate power supply during firmware updates
  # Firmware updates can brick devices if interrupted
}