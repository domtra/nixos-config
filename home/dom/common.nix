{
  config,
  pkgs,
  lib,
  ...
}:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isAarch64 = pkgs.stdenv.isAarch64;
in
{
  home.username = "dom";
  home.homeDirectory = if isDarwin then "/Users/dom" else "/home/dom";
  home.stateVersion = "24.11";

  home.packages =
    with pkgs;
    [
      git
      stow
      gcc
      tree-sitter
      nixfmt
      nixd
      statix
      deadnix
      ripgrep
      fd
      tree
      wget
      curl
      unzip
      htop
      btop
      jq
      yq
      glow
      zoxide
      fzf
      bat
      eza
      tldr
      dust
      fastfetch
      whois
      xmlstarlet
      gum
      imagemagick
      ffmpegthumbnailer
      gh
      lazygit
      lazydocker
      nodejs
      devbox
      home-assistant-cli
      killall
    ]
    ++ lib.optionals (!isDarwin) [
      plocate
    ];

  programs = {
    starship = {
      enable = true;
      settings = {
        add_newline = false;
        format = "$all$character";
        character = {
          success_symbol = "[λ](bold green)";
          error_symbol = "[λ](bold red)";
        };
      };
    };

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

    vscode = lib.mkIf (!isDarwin && !isAarch64) {
      enable = true;
      package = pkgs.vscode.fhs;
    };

    neovim = {
      enable = true;
      extraPackages = [ pkgs.sqlite ];
      plugins = [ pkgs.vimPlugins.sqlite-lua ];
    };

    direnv.enable = true;
    home-manager.enable = true;
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    BROWSER = if isDarwin then "google-chrome" else "firefox";
  };

}
