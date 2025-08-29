# UM790 Pro NixOS Workstation – **Spec & Checklist**

---

## 0) Goals & Constraints

* Device: **MINISFORUM UM790 Pro** (Ryzen 9 7940HS, Radeon 780M, 1TB SSD, 32GB RAM).
* OS: **NixOS** tracking **nixos-unstable**, using **flakes**.
* Desktop: **Hyprland** on Wayland with xdg-desktop-portal-hyprland.
* Disk: **Full‑disk encryption** (LUKS) + **Btrfs** subvolumes; **swap partition** inside LUKS (hibernate‑ready).
* Power: Use **power-profiles-daemon** (not TLP). Enable `amd_pstate=active` (or guided) for low idle.
* Experiments: **Distrobox** (rootless **Podman**) + **libvirt** VMs (UEFI/TPM).
* Remote Swarm: **Docker CLI only** to run `docker stack` on remote hosts via **SSH** (no local dockerd).
* Dotfiles: Use **Home Manager** for packages/services **and** **GNU Stow** to symlink personal configs (no overlap).
* Peripherals: Apple **Magic Trackpad** & **Magic Keyboard (Touch ID keyboard works; Touch ID not supported)** via Bluetooth; **Elgato Cam Link 4K** (UVC); **Behringer UMC22** (USB audio class).
* Locale/timezone: **Europe/Berlin**, EN/DE locales.
* Firmware updates enabled (fwupd).

---

## 1) Repository Layout (to be generated)

```
repo/
├─ flake.nix
├─ flake.lock
├─ hosts/
│  └─ um790/
│     ├─ configuration.nix
│     ├─ hardware-configuration.nix
│     ├─ disko.nix
│     ├─ modules/
│     │  ├─ graphics.nix
│     │  ├─ hyprland.nix
│     │  ├─ power.nix
│     │  ├─ audio-bluetooth.nix
│     │  ├─ containers.nix
│     │  ├─ virtualization.nix
│     │  ├─ firmware.nix
│     │  └─ snapshots.nix
│     └─ README.md
├─ home/
│  └─ dom/
│     ├─ home.nix
│     ├─ programs.nix
│     ├─ wayland.nix
│     └─ devtools.nix
└─ dotfiles/
   ├─ hypr/.config/hypr/hyprland.conf
   ├─ hypr/.config/hypr/hypridle.conf
   ├─ hypr/.config/hypr/hyprlock.conf
  ├─ alacritty/.config/alacritty/alacritty.toml   (or foot/kitty)
   ├─ git/.config/git/config
   ├─ zsh/.zshrc   (or fish/config.fish)
   ├─ wlogout/.config/wlogout/layout
   └─ ... (ONLY files not managed by Home Manager)
```

* [x] Create the above directory structure.
* [x] Ensure dotfiles placed under `dotfiles/` do **not** conflict with HM‑managed files.

---

## 2) `flake.nix` (inputs/outputs)

**Purpose:** Pin channels and compose the UM790 configuration.

**Requirements**

* [x] Inputs: `nixpkgs = nixos-unstable`, `disko`, `home-manager`.
* [x] Outputs: `nixosConfigurations.um790` using `nixosSystem { modules = [ disko module, ./hosts/um790/* ] }`.
* [x] Globally enable flakes & nix‑command.
* [x] Allow unfree packages if needed (fonts/codecs).

**Acceptance**

* [ ] `nix flake check` passes.
* [ ] `nixos-rebuild switch --flake .#um790` compiles.

---

## 3) `hosts/um790/disko.nix` (partitioning)

**Purpose:** Declarative storage for encrypted Btrfs.

**Layout**

* [x] Target disk (parameterizable): `/dev/nvme0n1`.
* [x] GPT partitions: (1) **ESP** 1 GiB FAT32 → `/boot/efi`; (2) **LUKS** container for the rest.
* [x] Inside LUKS: **Btrfs** with subvolumes:

  * [x] `@root` → `/` (zstd, noatime)
  * [x] `@home` → `/home`
  * [x] `@nix`  → `/nix` (noatime)
  * [x] `@log`  → `/var/log`
  * [x] `@snapshots` → `/.snapshots` (dedicated snapshots subvolume for btrbk; keeps `@root` clean)
* [x] **Swap partition** inside LUKS sized ≈ 1–1.5× RAM (hibernate‑ready).
* [x] Mount options: `compress=zstd`, `noatime` where noted.

**Acceptance**

* [ ] `lsblk` shows expected LUKS mapping and mounts.
* [ ] `btrfs subvolume list /` shows subvolumes.
* [ ] `swapon --show` lists encrypted swap.

---

## 4) `hosts/um790/configuration.nix` (system glue)

**Purpose:** System‑level config importing split modules and setting host basics.

**Include**

* [x] Import `hardware-configuration.nix`, `disko.nix`, and all `modules/*.nix`.
* [x] Boot: `systemd-boot` on UEFI.
* [x] Kernel: `boot.kernelPackages = linuxPackages_latest` (≥ 6.11).
* [x] Kernel params: `amd_pstate=active` (or guided).
* [x] Hibernate: set `boot.resumeDevice` to encrypted swap.
* [x] Filesystem: mounts per disko; `services.fstrim.enable = true`.
* [x] Networking: `networking.networkmanager.enable = true`.
* [x] Time/Locale: `time.timeZone = "Europe/Berlin"`; locales `en_US.UTF-8` and `de_DE.UTF-8`.
* [x] User: create **dom** (wheel); set default shell; add SSH keys.
* [x] Nix: enable experimental features and nix command; GC schedule; `auto-optimise-store = true`.

**Acceptance**

* [ ] System boots; `uname -r` ≥ 6.11.
* [ ] `powerprofilesctl get` works.
* [ ] `journalctl -b` shows no critical errors.

---

## 5) `hosts/um790/modules/firewall.nix`

**Purpose:** Default‑deny inbound host firewall (workstation should not expose services).

**Requirements**

* [x] `networking.firewall.enable = true`.
* [x] No inbound TCP/UDP ports opened (`allowedTCPPorts = [ ]; allowedUDPPorts = [ ];`).
* [x] Disable ping (`allowPing = false`) unless later needed for diagnostics.
* [x] Log refused connections (`logRefusedConnections = true`).
* [x] Document (in comments) how to temporarily open a port and container/libvirt interaction.
* [x] IPv6 filtered equally (default behavior retained).

**Acceptance**

* [ ] `sudo nft list ruleset` shows default accept established/related; unsolicited inbound dropped.
* [ ] `nc -vz <host> 22` from another machine fails (unless SSH deliberately opened later).
* [ ] `ping <host>` times out; outbound ping works.
* [ ] Adding a port to `allowedTCPPorts` then rebuilding makes it reachable; removing closes it.

---

## 6) `hosts/um790/modules/graphics.nix`

**Purpose:** 780M graphics stack.

* [x] Enable modern graphics API: `hardware.graphics.enable = true; hardware.graphics.enable32Bit = true;` (24.11+).
* [x] Provide Mesa/VA‑API/Vulkan userspace.
* [x] (Optional) Steam OFF by default.
* [x] Install diagnostics (`glxinfo`, `vulkan-tools`).

**Acceptance**

* [ ] `glxinfo | grep "OpenGL renderer"` shows RADV/780M.
* [ ] `vulkaninfo` succeeds.

---

## 7) `hosts/um790/modules/hyprland.nix`

**Purpose:** Wayland desktop.

* [x] `programs.hyprland.enable = true`.
* [x] Ensure xdg-desktop-portal-hyprland is active via the module.
* [x] Provide/enable a polkit agent.
* [x] Install Wayland helpers (wl-clipboard, grim, slurp, swappy) via HM **only**; **do not** manage Hyprland config files here.
* [x] Place Hyprland configs under `dotfiles/` and symlink via **Stow**.

**Acceptance**

* [ ] Login to Hyprland session works.
* [ ] `xdg-desktop-portal --list` shows Hyprland portal.

---

## 8) `hosts/um790/modules/power.nix`

**Purpose:** Idle power + profiles using **power-profiles-daemon**.

* [x] `services.power-profiles-daemon.enable = true`.
* [x] Confirm kernel param `amd_pstate=active` is set (from configuration).
* [x] Add a systemd oneshot to set the default profile at boot (e.g., `power-saver` or `balanced`).
* [x] Prefer BIOS ASPM/ErP/Resizable BAR enabled when available (document; do not fail if missing).

**Acceptance**

* [ ] `powerprofilesctl get` returns desired profile after boot.
* [ ] Idle power reduced compared to performance profile.

---

## 9) `hosts/um790/modules/audio-bluetooth.nix`

**Purpose:** PipeWire + Bluetooth; Apple peripherals; USB audio.

* [ ] PipeWire: `services.pipewire.enable = true;` with `alsa`, `pulse`, `jack` submodules and `security.rtkit.enable = true`.
* [ ] Bluetooth: `hardware.bluetooth.enable = true;` and `services.blueman.enable = true`.
* [ ] Notes (comments): Magic Keyboard’s **Touch ID not supported**; keyboard works. Magic Trackpad works; if using newest USB‑C model ensure kernel ≥ 6.11.
* [ ] UMC22 class‑compliant; prefer conservative USB autosuspend (we don’t use TLP).
* [ ] Cam Link 4K is UVC; appears as `/dev/video*`.

**Acceptance**

* [ ] `pactl info` shows PipeWire.
* [ ] `bluetoothctl` can pair devices.
* [ ] `arecord -l` lists UMC22; `v4l2-ctl --list-devices` lists Cam Link.

---

## 10) `hosts/um790/modules/containers.nix`

**Purpose:** Rootless Podman + Distrobox + Docker CLI for remote Swarm.

* [ ] `virtualisation.podman.enable = true`.
* [ ] `virtualisation.podman.dockerCompat = true` (provides `docker` shim for tools; no local dockerd).
* [ ] Install packages: `distrobox`, `docker-client`.
* [ ] Docs: Show how to create Docker SSH context and deploy a stack:

  * [ ] `docker context create <name> --docker "host=ssh://USER@HOST"`
  * [ ] `docker --context <name> stack deploy -c stack.yml mystack`

**Acceptance**

* [ ] `podman info` works rootless as user.
* [ ] `distrobox create -n test --image fedora:latest` works.
* [ ] `docker --context <name> ps` shows remote engine output.

---

## 11) `hosts/um790/modules/virtualization.nix`

**Purpose:** Lightweight VMs for experiments.

* [ ] `virtualisation.libvirtd.enable = true`.
* [ ] `programs.virt-manager.enable = true`.
* [ ] Include OVMF (UEFI) and swtpm packages for UEFI/TPM VMs.

**Acceptance**

* [ ] `virsh list --all` works.
* [ ] virt-manager GUI opens and can create a UEFI VM.

---

## 12) `hosts/um790/modules/firmware.nix`

**Purpose:** Firmware updates.

* [x] `services.fwupd.enable = true`.

**Acceptance**

* [ ] `fwupdmgr get-devices` works and lists devices.

---

## 13) `hosts/um790/modules/snapshots.nix`

**Purpose:** Btrfs snapshots & NixOS autosnap.

* [ ] Implement **btrbk** with a simple local retention policy for `root` (/@root) and `home` (/@home) subvolumes using the dedicated `@snapshots` subvolume mounted at `/.snapshots`.
* [ ] Provide pre/post `nixos-rebuild` snapshot hooks (documented in comments) via a lightweight systemd service or activation script calling `btrbk run --target @preserve` (or equivalent) before and after rebuilds.
* [ ] Document rollback procedure in comments (mount older snapshot read-only, `btrfs send/receive` or `btrfs subvolume snapshot` to promote, then rebuild).

**Acceptance**

* [ ] Snapshot tool lists snapshots.
* [ ] `nixos-rebuild switch` creates snapshots.

---

## 14) `hosts/um790/hardware-configuration.nix`

**Purpose:** Autogenerated by installer; minimal edits only.

* [x] Ensure filesystems/initrd/µcode match actual hardware.
* [x] Keep manual edits minimal and consistent with disko.

**Acceptance**

* [ ] System boots and mounts as expected.

---

## 15) `home/dom/home.nix` (Home Manager entry)

**Purpose:** User‑level packages/services; avoid overlap with Stow.

* [x] Enable HM as NixOS module (`programs.home-manager.enable = true`).
* [x] CLI packages: git, stow, neovim, ripgrep, fd, htop/btop, jq, yq, glow, tree, wget, curl, unzip.
* [x] **SKIP** Dev tools: nodejs, php (optional), python, gcc/clang, pkg-config; nix-ld if needed.
* [x] Wayland helpers: wl-clipboard, grim, slurp, swappy, swaybg/swww (configs live in Stow if app supports dotfiles).
* [x] Terminal(s): install alacritty (but **configs via Stow** only).
* [x] Shell: zsh or fish (set as default); prompt via starship (rc files via Stow).
* [x] Fonts: JetBrainsMono Nerd Font, Hasklug Nerd Font Mono, CaskaydiaMono Nerd Font (Omarchy preference). (Nix: add corresponding `nerd-fonts` derivations / `pkgs.nerd-fonts.{jetbrains-mono,hasklug,caskaydia-mono}`).
* [x] Notifications/launcher/bar (mako/swaync, wofi/rofi‑wayland, waybar) **optional**; configs via Stow.

**Acceptance**

* [ ] `home-manager switch --flake .#dom@um790` succeeds.
* [ ] Session has required tools without config overlaps.

---

## 16) `home/dom/programs.nix` / `wayland.nix` / `devtools.nix` (optional splits)

**Purpose:** Keep `home.nix` tidy.

* [ ] Factor package lists and HM options into these files.
* [ ] Ensure no file content overlaps with Stow‑managed dotfiles.

**Acceptance**

* [ ] HM evaluation remains successful after split.

---

## 17) `dotfiles/` (GNU Stow)

**Purpose:** Personal configs as symlinks.

* [x] Place only files not managed by HM.
* [x] Initial sets:

  * [x] `hypr/.config/hypr/{hyprland.conf, hypridle.conf, hyprlock.conf}`
  * [x] `alacritty/.config/alacritty/alacritty.toml` (or foot/kitty)
  * [x] `git/.config/git/config`
  * [x] `zsh/.zshrc` (or `fish/config.fish`)
  * [x] `wlogout/.config/wlogout/layout` (if used)
* [x] Test symlinks: `stow -v -t ~ hypr alacritty git zsh`.

**Acceptance**

* [ ] Symlinks created; no conflict with HM files.

---

## 18) `hosts/um790/README.md` (Runbook)

**Purpose:** Human install & ops guide.

**Install steps**

* [ ] Boot NixOS ISO; `nix-shell -p git`; clone repo.
* [ ] Adjust disk path in `disko.nix` if needed.
* [ ] Run disko: `sudo nix run github:nix-community/disko -- --mode disko ./hosts/um790/disko.nix`.
* [ ] Install: `nixos-install --flake .#um790`.

**First boot**

* [ ] Login as `dom` and run `home-manager switch`.
* [ ] Use `stow` to link desired dotfile groups.

**Remote Swarm**

* [ ] Create Docker SSH context and deploy stacks as documented in `containers.nix`.

**Hibernate test**

* [ ] `systemctl hibernate` and verify successful resume.

**Troubleshooting**

* [ ] Document Bluetooth pairing tips, PipeWire device selection, Hyprland logs.

---

## 19) Defaults & Policies

* [ ] Kernel: use `linuxPackages_latest` (≥ 6.11).
* [ ] Security: SSH key‑based login; sudo for wheel; avoid passwordless sudo by default.
* [ ] Updates: manual `nix flake update` + rebuild; no auto‑upgrade unless requested.
* [ ] Nix store: enable weekly GC; store optimization.
* [ ] No telemetry unless explicitly requested.

---

## 20) Post‑Gen Validation Checklist (commands to run)

* [ ] Storage: `lsblk -e7 -o NAME,SIZE,TYPE,MOUNTPOINT`.
* [ ] Btrfs: `sudo btrfs subvolume list /`.
* [ ] Encryption: `sudo cryptsetup status cryptroot`.
* [ ] Swap/Hibernate: `swapon --show`; `systemctl hibernate` then resume.
* [ ] Graphics: `glxinfo | grep renderer`; `vulkaninfo | head -n 20`.
* [ ] Power: `powerprofilesctl get` (expect chosen profile).
* [ ] Wayland: `echo $XDG_SESSION_TYPE` → `wayland`.
* [ ] Bluetooth: `bluetoothctl show` and pair device.
* [ ] Audio/Video: `pactl list short sinks`; `v4l2-ctl --list-devices`.
* [ ] Containers: `podman info`; `distrobox create -n test --image fedora:latest`.
* [ ] Remote Docker: `docker context ls`; `docker --context <name> ps`.

---

## 21) Notes & Edge Cases (document in comments)

* [ ] Apple Magic Keyboard **Touch ID not supported** on Linux; keyboard functions normally.
* [ ] Magic Trackpad USB‑C (newest) may require kernel ≥ 6.11 for full support.
* [ ] Prefer enabling BIOS **PCIe ASPM**, **ErP**, **Resizable BAR** where available.
* [ ] Avoid aggressive USB autosuspend for USB audio; power‑profiles-daemon is used instead of TLP.

---
