{ ... }:
{
  # Point nh to this host's flake outputs
  home.sessionVariables = {
    NH_HOME_FLAKE = "/home/dom/nixos-config#dom@mba-m1";
    NH_OS_FLAKE   = "/home/dom/nixos-config#mba-m1";
  };
}
