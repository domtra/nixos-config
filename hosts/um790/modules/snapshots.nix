{ config, lib, pkgs, ... }:

{
  # Install btrbk for Btrfs snapshot management
  environment.systemPackages = with pkgs; [
    btrbk
    btrfs-progs
  ];

  # btrbk configuration for automated snapshots
  services.btrbk = {
    instances = {
      local = {
        onCalendar = "hourly";
        settings = {
          # Snapshot source subvolumes
          snapshot_dir = "/.snapshots";
          snapshot_preserve_min = "2d";
          snapshot_preserve = "48h 30d 12m";
          # Volume definitions (snapshot / and /home)
          volume."/" = {
            subvolume = {
              "/" = { snapshot_name = "root"; };
              "/home" = { snapshot_name = "home"; };
            };
          };
        };
      };
    };
  };

  # Pre/post nixos-rebuild hooks for system snapshots
  system.activationScripts.btrbk-pre-rebuild = {
    text = ''
      # Create pre-rebuild snapshot
      if ${pkgs.btrbk}/bin/btrbk list snapshots | grep -q "$(date +%Y%m%d)"; then
        echo "Pre-rebuild snapshot already exists for today"
      else
        echo "Creating pre-rebuild snapshot..."
        ${pkgs.btrbk}/bin/btrbk -c /etc/btrbk/btrbk.conf run || echo "Failed to create pre-rebuild snapshot"
      fi
    '';
    deps = [ ];
  };

  # Create a systemd service for post-rebuild snapshots
  systemd.services.btrbk-post-rebuild = {
    description = "Post-rebuild Btrfs snapshot";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.btrbk}/bin/btrbk -c /etc/btrbk/btrbk.conf run";
      User = "root";
    };
  };

  # Rollback procedure (documented in comments):
  #
  # Manual rollback process:
  # 1. Boot from NixOS ISO or emergency shell
  # 2. Decrypt and mount the LUKS volume:
  #    cryptsetup open /dev/nvme0n1p2 cryptroot
  #    mount /dev/mapper/pool-root /mnt
  # 3. List available snapshots:
  #    btrfs subvolume list /.snapshots
  # 4. Mount the snapshot you want to restore:
  #    mount -o subvol=.snapshots/root.YYYYMMDD /dev/mapper/pool-root /mnt2
  # 5. Create new @root from snapshot:
  #    btrfs subvolume delete /mnt/@root
  #    btrfs subvolume snapshot /mnt2 /mnt/@root
  # 6. Reboot and rebuild:
  #    nixos-rebuild switch --flake .#um790
  #
  # Alternative using btrfs send/receive:
  # 1. Send snapshot to temporary location
  # 2. Delete current @root
  # 3. Receive snapshot as new @root
  #
  # Quick snapshot commands:
  # btrbk list snapshots                    # List all snapshots
  # btrbk list latest                       # List latest snapshots
  # btrbk run                               # Create snapshots now
  # btrfs subvolume list /.snapshots        # List snapshots directly
}