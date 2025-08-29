# UM790 Pro NixOS Installation Guide

This guide covers the installation and setup of NixOS with Hyprland on the MINISFORUM UM790 Pro workstation.

## Hardware Specifications

- **CPU**: AMD Ryzen 9 7940HS
- **GPU**: Integrated AMD Radeon 780M
- **RAM**: 32GB
- **Storage**: 1TB NVMe SSD
- **Connectivity**: WiFi 6E, Bluetooth 5.3, USB-C/Thunderbolt

## Prerequisites

- NixOS ISO (unstable recommended)
- USB drive for installation media
- Wired or wireless internet connection
- Target disk path confirmed (usually `/dev/nvme0n1`)

## Installation Steps

### 1. Boot from NixOS ISO

1. Create NixOS installation media
2. Boot from USB drive
3. Ensure UEFI mode (check with `ls /sys/firmware/efi/efivars`)

### 2. Network Setup

For WiFi:
```bash
# Connect to WiFi
wpa_supplicant -B -i wlan0 -c <(wpa_passphrase 'SSID' 'password')
dhcpcd wlan0
```

For Ethernet: Should work automatically with DHCP.

### 3. Prepare Installation

```bash
# Install git to clone this repository
nix-shell -p git

# Clone the configuration repository
git clone <repository-url> /tmp/nixos-config
cd /tmp/nixos-config

# Adjust disk path in disko.nix if needed (default: /dev/nvme0n1)
# Edit hosts/um790/disko.nix if your disk path differs
```

### 4. Partition and Format

```bash
# Create LUKS password file
echo "your-encryption-password" > /tmp/secret.key

# Run disko to partition and format the disk
sudo nix run github:nix-community/disko -- --mode disko ./hosts/um790/disko.nix
```

This will:
- Create GPT partition table
- Set up 1GB EFI System Partition
- Create LUKS-encrypted container for the rest
- Set up LVM with swap and Btrfs root
- Create Btrfs subvolumes (@root, @home, @nix, @log, @snapshots)

### 5. Generate Hardware Configuration

```bash
# Generate hardware configuration
nixos-generate-config --root /mnt

# Replace our placeholder with the generated one
cp /mnt/etc/nixos/hardware-configuration.nix ./hosts/um790/hardware-configuration.nix
```

### 6. Install NixOS

```bash
# Install NixOS with our flake configuration
nixos-install --flake .#um790

# Set root password when prompted
# The user 'dom' will be created but needs to be configured post-install
```

### 7. First Boot Setup

Reboot and log in as `dom`:

```bash
# Switch to Home Manager configuration
home-manager switch --flake /path/to/repo#dom@um790

# Link dotfiles using Stow
cd /path/to/repo/dotfiles
stow -v -t ~ hypr alacritty git zsh wlogout

# Set user password
sudo passwd dom
```

## Post-Installation Configuration

### SSH Keys

Add your SSH public keys to the user configuration:

1. Edit `hosts/um790/configuration.nix`
2. Add keys to `users.users.dom.openssh.authorizedKeys.keys`
3. Rebuild: `sudo nixos-rebuild switch --flake .#um790`

### Remote Docker Swarm Setup

Configure Docker contexts for remote swarm management:

```bash
# Create context for remote Docker host
docker context create production --docker "host=ssh://user@remote-host.example.com"

# Deploy a stack to remote swarm
docker --context production stack deploy -c docker-compose.yml myapp

# List contexts
docker context ls
```

### Hibernate Test

Test hibernation functionality:

```bash
# Test hibernation (will suspend to disk)
systemctl hibernate

# System should resume with all sessions intact
```

### Graphics Validation

Verify graphics setup:

```bash
# Check OpenGL renderer
glxinfo | grep "OpenGL renderer"
# Should show: "AMD Radeon Graphics (gfx1103_r1, LLVM 17.0.6, DRM 3.54, 6.x.x)"

# Check Vulkan support
vulkaninfo | head -20
# Should show RADV driver information
```

### Audio/Bluetooth Setup

1. **PipeWire**: Should work automatically
   ```bash
   pactl info  # Should show PipeWire
   ```

2. **Bluetooth Pairing**:
   ```bash
   bluetoothctl
   [bluetooth]# scan on
   [bluetooth]# pair XX:XX:XX:XX:XX:XX
   [bluetooth]# connect XX:XX:XX:XX:XX:XX
   ```

3. **Apple Magic Keyboard**: Pairs normally, Touch ID not supported
4. **Apple Magic Trackpad**: Works with basic functionality
5. **Behringer UMC22**: Plug-and-play USB audio
6. **Cam Link 4K**: Appears as `/dev/video*`

## Troubleshooting

### Boot Issues

- **LUKS not unlocking**: Check password, may need to recreate keyfile
- **Mount failures**: Verify Btrfs subvolumes exist: `btrfs subvolume list /`

### Hyprland Issues

- **Black screen**: Check `journalctl --user -u hyprland`
- **No desktop portal**: Ensure `xdg-desktop-portal-hyprland` is running
- **Input not working**: Check Hyprland logs for input device detection

### Bluetooth Issues

- **Pairing fails**: Try `bluetoothctl remove XX:XX:XX:XX:XX:XX` then re-pair
- **Audio choppy**: Check PipeWire-Bluetooth modules are loaded

### Power Management

- **High idle power**: Verify `amd_pstate=active` in kernel params
- **Profile not applied**: Check `powerprofilesctl get`

### Snapshots

- **Snapshot creation fails**: Check disk space and Btrfs health
- **btrbk errors**: Verify configuration in `/etc/btrbk/btrbk.conf`

## System Maintenance

### Updates

```bash
# Update flake inputs
nix flake update

# Rebuild system
sudo nixos-rebuild switch --flake .#um790

# Update Home Manager
home-manager switch --flake .#dom@um790
```

### Cleanup

```bash
# Garbage collect old generations
sudo nix-collect-garbage -d

# Optimize store
nix store optimise
```

### Firmware Updates

```bash
# Check for firmware updates
fwupdmgr get-devices
fwupdmgr get-updates
fwupdmgr update
```

## Customization

### Adding Packages

- **System packages**: Add to `hosts/um790/configuration.nix`
- **User packages**: Add to `home/dom/home.nix`
- **Dotfiles**: Place in `dotfiles/` and link with Stow

### Power Profiles

Switch between power profiles:
```bash
powerprofilesctl set power-saver    # Battery saving
powerprofilesctl set balanced       # Default
powerprofilesctl set performance    # Maximum performance
```

## BIOS Recommendations

Enable these settings in BIOS for optimal operation:

- **PCIe ASPM**: Enabled (power saving)
- **ErP Ready**: Enabled (EU energy standards)
- **Resizable BAR**: Enabled (GPU performance)
- **Secure Boot**: Can be enabled after installation
- **TPM**: Enabled for VM experiments

## Backup and Recovery

### System Snapshots

Snapshots are created automatically before system rebuilds. Manual snapshot:
```bash
btrbk run
```

### Configuration Backup

Keep this repository backed up and synced. The entire system can be reproduced from these files.

### Rollback Procedure

If system becomes unbootable:

1. Boot from NixOS ISO
2. Decrypt and mount system: `cryptsetup open /dev/nvme0n1p2 cryptroot`
3. Mount root: `mount /dev/mapper/pool-root /mnt`
4. List snapshots: `btrfs subvolume list /.snapshots`
5. Restore from snapshot (see `hosts/um790/modules/snapshots.nix` for details)

---

For additional help, check:
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Hyprland Wiki](https://wiki.hyprland.org/)