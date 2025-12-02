{
  config,
  pkgs,
  lib,
  ...
}:

let
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  home.packages = with pkgs; [
    devbox
    nh
  ];

  home.sessionVariables = {
    NH_HOME_FLAKE = "/Users/dom/config/nixos-config#dom@macbook-pro-m4";
    NH_OS_FLAKE = "/Users/dom/config/nixos-config#macbook-pro-m4";
  };

  # Keep host-specific overrides minimal; most settings live in common.nix
  xdg.enable = lib.mkIf isDarwin true;
}
