{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should manage
  home.username = "dom";
  home.homeDirectory = "/home/dom";

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
    (nerdfonts.override { fonts = [ "JetBrainsMono" "Hasklug" "CaskaydiaMono" ]; })

    # Optional notification/launcher/bar tools (configs via Stow)
    mako          # Notifications
    wofi          # Launcher
    waybar        # Status bar
  ];

  # Shell configuration
  programs = {
    # Enable zsh with starship prompt
    zsh = {
      enable = true;
      # RC file managed by Stow - avoid conflicts
      initExtra = ''
        # This space intentionally left minimal
        # Main zsh config is managed via Stow in dotfiles/zsh/.zshrc
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
      userName = "dom";
      userEmail = "dom@example.com"; # Replace with actual email
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = false;
      };
    };
  };

  # Session variables
  home.sessionVariables = {
    EDITOR = "nvim";
    BROWSER = "firefox";
    TERMINAL = "alacritty";
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