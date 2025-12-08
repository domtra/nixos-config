NIXADDR ?= unset
NIXPORT ?= 22
NIXUSER ?= dom
NIXNAME ?= vm-fusion

ifeq ($(NIXNAME),vm-utm)
  NIXDISK ?= /dev/vda
else
  NIXDISK ?= /dev/nvme0n1
endif

PARTSEP :=
ifneq (,$(findstring nvme,$(NIXDISK)))
  PARTSEP := p
endif

MAKEFILE_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

SSH_OPTIONS = -o PubkeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no

switch:
	sudo NIXPKGS_ALLOW_UNFREE=1 nixos-rebuild switch --flake ".#${NIXNAME}"

test:
	sudo NIXPKGS_ALLOW_UNFREE=1 nixos-rebuild test --flake ".#${NIXNAME}"

vm/bootstrap0:
	ssh $(SSH_OPTIONS) -p$(NIXPORT) root@$(NIXADDR) " \
		parted $(NIXDISK) -- mklabel gpt; \
		parted $(NIXDISK) -- mkpart primary 512MB -8GB; \
		parted $(NIXDISK) -- mkpart primary linux-swap -8GB 100%; \
		parted $(NIXDISK) -- mkpart ESP fat32 1MB 512MB; \
		parted $(NIXDISK) -- set 3 esp on; \
		sleep 1; \
		mkfs.ext4 -L nixos $(NIXDISK)$(PARTSEP)1; \
		mkswap -L swap $(NIXDISK)$(PARTSEP)2; \
		mkfs.fat -F 32 -n boot $(NIXDISK)$(PARTSEP)3; \
		sleep 1; \
		mount /dev/disk/by-label/nixos /mnt; \
		mkdir -p /mnt/boot; \
		mount /dev/disk/by-label/boot /mnt/boot; \
		nixos-generate-config --root /mnt; \
		sed --in-place '/system\\.stateVersion = .*/a \
			nix.package = pkgs.nixVersions.latest;\\n \
			nix.settings.experimental-features = [\"nix-command\" \"flakes\"];\\n \
			nix.settings.substituters = [\"https://cache.nixos.org/\" \"https://walker-git.cachix.org\"];\\n \
			nix.settings.trusted-public-keys = [\"cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=\" \"walker-git.cachix.org-1:vmC0ocfPWh0S/vRAQGtChuiZBTAe4wiKDeyyXM0/7pM=\"];\\n \
			services.openssh.enable = true;\\n \
			services.openssh.settings.PasswordAuthentication = true;\\n \
			services.openssh.settings.PermitRootLogin = \"yes\";\\n \
			users.users.root.initialPassword = \"root\";\\n \
		' /mnt/etc/nixos/configuration.nix; \
		nixos-install --no-root-passwd && reboot; \
	"

vm/bootstrap:
	NIXUSER=root $(MAKE) vm/copy
	NIXUSER=root $(MAKE) vm/switch
	$(MAKE) vm/secrets
	ssh $(SSH_OPTIONS) -p$(NIXPORT) $(NIXUSER)@$(NIXADDR) " \
		sudo reboot; \
	"

vm/secrets:
	rsync -av -e 'ssh $(SSH_OPTIONS)' \
		--exclude='.#*' \
		--exclude='S.*' \
		--exclude='*.conf' \
		$(HOME)/.gnupg/ $(NIXUSER)@$(NIXADDR):~/.gnupg
	rsync -av -e 'ssh $(SSH_OPTIONS)' \
		--exclude='environment' \
		$(HOME)/.ssh/ $(NIXUSER)@$(NIXADDR):~/.ssh

vm/copy:
	rsync -av -e 'ssh $(SSH_OPTIONS) -p$(NIXPORT)' \
		--exclude='vendor/' \
		--exclude='.git/' \
		--exclude='.git-crypt/' \
		--exclude='.jj/' \
		--exclude='iso/' \
		--rsync-path="sudo rsync" \
		$(MAKEFILE_DIR)/ $(NIXUSER)@$(NIXADDR):/nix-config

vm/switch:
	ssh $(SSH_OPTIONS) -p$(NIXPORT) $(NIXUSER)@$(NIXADDR) " \
		sudo NIXPKGS_ALLOW_UNFREE=1 nixos-rebuild switch --flake \"/nix-config#${NIXNAME}\" \
	"
