# VMware Fusion NixOS Dev VM (Apple Silicon)

Summary:
- Host: macOS (Apple Silicon) with VMware Fusion.
- Guest: aarch64 NixOS; NVMe disk `/dev/nvme0n1`; NAT networking (`enp2s0`).
- Desktop: Niri via greetd auto-login to `dom`.
- Clipboard/resolution: VMware guest tools.
- Shares: `.host:/Downloads` → `/host/Downloads`, `.host:/VMShare` → `/host/VMShare`.
- Firewall: disabled in VM (host firewall stays enabled on other machines).
- Sudo: passwordless for `wheel`.

Bootstrap (from mac host):
1. Create the VM in Fusion: aarch64 ISO, NVMe disk, UEFI, 3D accel on, remove sound/camera/printer.
2. Boot ISO, set root password to `root`, get VM IP (e.g., `ip a` → `enp2s0`).
3. Export env vars and run bootstrap0:
   ```
   export NIXADDR=192.168.x.y
   make vm/bootstrap0
   ```
4. After reboot, finalize:
   ```
   make vm/bootstrap
   ```
5. Clone the repo inside the VM (`/nix-config` is already synced), adjust `hardware-configuration.nix` if hardware changes, then `sudo nixos-rebuild switch --flake /nix-config#vm-fusion`.

Notes:
- Root login is enabled for bootstrap only; SSH is on. Consider tightening after setup if desired.
- 1Password GUI isn’t available on aarch64 Linux; use `ssh-agent` + synced keys or the CLI if/when it becomes available.
