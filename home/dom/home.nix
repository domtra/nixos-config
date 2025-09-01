{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should manage
  home.username = "dom";
  home.homeDirectory = "/home/dom";
  # Login shell is set at system level in hosts/um790/configuration.nix (users.users.dom.shell)

  # This value determines the Home Manager release which your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "24.11";

  # Essential CLI packages
  home.packages = with pkgs; [
    # Version control and development
    git
    stow

    # Text editing
    neovim

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

    # Fonts for terminal and desktop
    #(nerdfonts.override { fonts = [ "JetBrainsMono" "Hasklug" "CaskaydiaMono" ]; })
    nerd-fonts.hasklug
    nerd-fonts.caskaydia-mono

    # Optional notification/launcher/bar tools (configs via Stow)
    mako          # Notifications
    wofi          # Launcher
    waybar        # Status bar
    # swayosd
    # walker

    # Hyprland helpers
    hypridle hyprlock hyprpicker hyprshot hyprsunset hyprland-qtutils
    swayosd wl-clip-persist wl-screenrec wf-recorder walker

    # Desktop apps
    # evince imv mpv libreoffice kdenlive pinta obs-studio obsidian localsend
    # nautilus sushi signal-desktop spotify
    evince imv mpv libreoffice pinta obsidian localsend
    nautilus sushi impala

    # CLI & dev
    zoxide fzf bat eza tldr dust fastfetch whois xmlstarlet plocate gum
    imagemagick ffmpegthumbnailer gh lazygit lazydocker

    # Audio utils
    pamixer playerctl wiremix

    google-chrome
    _1password-cli
    _1password-gui

    bibata-cursors
  ];

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
      userName = "Dominik Traenklein";
      userEmail = "dominik@bleech.de"; # Replace with actual email
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = false;
      };
    };

    vscode = {
      enable = true;
      package = pkgs.vscode.fhs;
    };
  };

  # Session variables
  home.sessionVariables = {
    EDITOR = "nvim";
    BROWSER = "firefox";
    TERMINAL = "alacritty";
    NIXOS_OZONE_WL = "1";
    NH_HOME_FLAKE = "/home/dom/nixos-config#dom@um790";

  };

  home.pointerCursor = {
    name = "Bibata-Modern-Ice";   # must match the theme’s name
    package = pkgs.bibata-cursors;
    size = 28;
    gtk.enable = true;            # make GTK apps follow it
    x11.enable = true;            # XWayland apps follow it
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
