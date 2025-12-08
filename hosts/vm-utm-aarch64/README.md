# UTM (Apple Virtualization) NixOS Dev VM

Summary:
- Host: macOS (Apple Silicon) with UTM using Apple's Virtualization framework (no shared folders).
- Guest: aarch64 NixOS; virtio disk `/dev/vda`; NIC `enp0s1`.
- Desktop: Niri via greetd auto-login to `dom`.
- Clipboard/resolution: handled by UTM (no VMware tools needed).
- Firewall: disabled in VM (keep host firewall on the mac).
- Sudo: passwordless for `wheel`.

Bootstrap (from mac host):
1. Create the VM in UTM: Apple Virtualization backend, UEFI, virtio disk, no shared directories, networking via shared NAT or bridge as desired.
2. Boot the NixOS ISO, set the root password to `root`, and get the VM IP (`ip a` → `enp0s1`).
3. Bootstrap the disk and base install (defaults to `/dev/vda` when `NIXNAME=vm-utm`):
   ```
   export NIXADDR=192.168.x.y
   export NIXNAME=vm-utm
   make vm/bootstrap0
   ```
4. After the reboot, finalize:
   ```
   export NIXADDR=192.168.x.y
   export NIXNAME=vm-utm
   make vm/bootstrap
   ```
5. Clone the repo inside the VM (`/nix-config` is already synced via rsync), adjust `hardware-configuration.nix` if hardware changes, then `sudo nixos-rebuild switch --flake /nix-config#vm-utm`.

Notes:
- No host shares are mounted in this profile; use `rsync`/`scp` when moving files.
- Root login is enabled for bootstrap only; tighten afterward if desired.
