{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Import Walker's home-manager module
  # imports = [
  #   inputs.walker.homeManagerModules.default
  # ];

  # Home Manager needs a bit of information about you and the paths it should manage
  home.username = "dom";
  home.homeDirectory = "/home/dom";
  # Login shell is set at system level in hosts/um790/configuration.nix (users.users.dom.shell)

  # This value determines the Home Manager release which your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "24.11";

  # Essential CLI packages
  home.packages =
    with pkgs;
    [
      # Version control and development
      git
      stow

      # Text editing
      #neovim
      gcc
      tree-sitter
      nixfmt
      nixd
      statix
      deadnix

      # Search and file management
      ripgrep
      fd
      tree
      wget
      curl
      unzip

      # System monitoring
      htop
      btop

      # Data processing
      jq
      yq

      # Documentation
      glow

      # Wayland helpers (configs managed by Stow)
      wl-clipboard
      grim
      slurp
      swappy
      swaybg

      # Terminal emulator (config via Stow)
      alacritty
      kitty

      # Fonts for terminal and desktop
      #(nerdfonts.override { fonts = [ "JetBrainsMono" "Hasklug" "CaskaydiaMono" ]; })
      nerd-fonts.hasklug
      nerd-fonts.caskaydia-mono

      # Optional notification/launcher/bar tools (configs via Stow)
      mako # Notifications
      wofi # Launcher
      waybar # Status bar
      # swayosd
      # walker

      # Desktop apps
      # evince imv mpv libreoffice kdenlive pinta obs-studio obsidian localsend
      # nautilus sushi signal-desktop spotify
      evince
      imv
      mpv
      libreoffice
      pinta
      obsidian
      localsend
      nautilus
      sushi
      impala

      # CLI & dev
      zoxide
      fzf
      bat
      eza
      tldr
      dust
      fastfetch
      whois
      xmlstarlet
      plocate
      gum
      imagemagick
      ffmpegthumbnailer
      gh
      lazygit
      lazydocker

      # Audio utils
      pamixer
      playerctl
      wiremix

      # GNOME Keyring tools
      seahorse
      libsecret

      # Note: 1Password packages now managed at system level via programs._1password*
      # Browser (chromium with Widevine for Apple Music, firefox via system)
      (chromium.override { enableWideVine = true; })

      bibata-cursors

      # GTK themes and icons
      adwaita-icon-theme
      yaru-theme

      nodejs

      satty
      terminaltexteffects

      vial
      via

      ghostty

      anytype
      obsidian

      home-assistant-cli

      killall
      # Add LM Studio only on x86_64 (not available on aarch64)
    ]
    ++ lib.optionals pkgs.stdenv.isx86_64 [ lmstudio ];

  # Shell configuration
  programs = {
    # Enable fish shell (replacing previous zsh default)
    fish = {
      enable = true;
      interactiveShellInit = ''
        # Extra fish init (keep minimal; main config can live in dotfiles if desired)
        set -gx EDITOR nvim
      '';
    };

    # Starship prompt
    starship = {
      enable = true;
      # Basic configuration - detailed config can be in dotfiles if needed
      settings = {
        add_newline = false;
        format = "$all$character";
        character = {
          success_symbol = "[λ](bold green)";
          error_symbol = "[λ](bold red)";
        };
      };
    };

    # Git configuration (basic - detailed config via Stow)
    git = {
      enable = true;
      userName = "Dominik Tränklein";
      userEmail = "dominik@bleech.de";
      aliases = {
        co = "checkout";
        l = "log --graph --date=short";
        gi = "!gi() { curl -L -s https://www.gitignore.io/api/$@ ;}; gi";
        s = "status";
      };
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = false;
        color.ui = true;
        format.pretty = "format:%C(blue)%ad%Creset %C(yellow)%h%C(green)%d%Creset %C(blue)%s %C(magenta) [%an]%Creset";
        rerere.enabled = true;
      };
    };

    vscode = {
      enable = true;
      package = pkgs.vscode.fhs;
    };

    neovim = {
      enable = true;
      extraPackages = [ pkgs.sqlite ];

      plugins = [ pkgs.vimPlugins.sqlite-lua ];
    };

    direnv = {
      enable = true;
    };
  };

  # # Walker configuration (replaces nixpkgs walker with 1.0.0 beta + Elephant)
  # programs.walker = {
  #   enable = true;
  #   # runAsService = true;
  #   # config = {
  #   #   search.placeholder = "Search...";
  #   #   ui.fullscreen = true;
  #   #   list.height = 200;
  #   #   websearch.prefix = "?";
  #   #   switcher.prefix = "/";
  #   # };
  # };

  # # programs.elephant = {
  # #   enable = true;
  # #   installService = true;
  # #   providers = [
  # #     "desktopapplications"  # Essential for app launching
  # #     "files"                # File search
  # #     "clipboard"            # Clipboard history
  # #     "runner"               # Command runner
  # #     "calc"                 # Calculator
  # #     "websearch"            # Web search
  # #     "symbols"              # Symbols/emojis
  # #   ];
  # # };

  # Session variables
  home.sessionVariables = {
    EDITOR = "nvim";
    BROWSER = "firefox";
    TERMINAL = "alacritty";
    NIXOS_OZONE_WL = "1";
    NH_HOME_FLAKE = "/home/dom/nixos-config#dom@um790";
    NH_OS_FLAKE = "/home/dom/nixos-config#um790";
    SQLITE_CLIB_PATH = "${pkgs.sqlite.out}/lib/libsqlite3.so";
  };

  # Link Niri config as an out-of-store symlink to the dotfiles repo
  # This avoids copying the file into the Nix store and keeps edits live.
  home.file.".config/niri" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos-config/dotfiles/niri";
    recursive = true;
  };

  home.pointerCursor = {
    # name = "Bibata-Modern-Ice";   # must match the theme's name
    # package = pkgs.bibata-cursors;
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    gtk.enable = true; # make GTK apps follow it
    x11.enable = true; # XWayland apps follow it
  };

  # GTK theme configuration
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Yaru-blue";
      package = pkgs.yaru-theme;
    };
  };

  dconf.enable = true;
  # dconf settings for consistent theming
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Adwaita-dark";
      icon-theme = "Yaru-blue";
    };
  };

  services.darkman = {
    enable = true;
    # Either let geoclue detect your location…
    settings.usegeoclue = true;
    # …or set it explicitly (Berlin):
    # settings = { lat = 52.52; lng = 13.405; };

    # Hooks when switching:
    darkModeScripts = {
      "default" = ''
        omx-theme-set catppuccin
      '';
    };
    lightModeScripts = {
      "default" = ''
        omx-theme-set catppuccin-latte
      '';
    };
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Note: Detailed configurations for individual programs are managed
  # via GNU Stow in the dotfiles/ directory to avoid conflicts with
  # Home Manager. This includes:
  # - Hyprland configuration (.config/hypr/*)
  # - Alacritty configuration (.config/alacritty/*)
  # - Detailed git configuration (.config/git/*)
  # - Shell RC files (.zshrc, etc.)
  # - Other application dotfiles
}
