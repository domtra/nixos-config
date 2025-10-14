{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Core
    vim
    wget
    curl
    git
    htop
    usbutils
    imagemagick
    ghostscript
    sqlite

    # Printing
    cups
    cups-pdf-to-pdf

    # Desktop utilities
    gnome-calculator
    gnome-calendar
    gnome-themes-extra
    gum

    # Qt/Wayland helpers
    libsForQt5.qtstyleplugin-kvantum
    kdePackages.qtstyleplugin-kvantum
    libsForQt5.qt5.qtwayland
    kdePackages.qtwayland

    # Hyprland helpers
    hypridle
    hyprlock
    hyprpicker
    hyprshot
    hyprsunset
    hyprland-qtutils
    swayosd
    wl-clip-persist
    wl-screenrec
    wf-recorder
    walker

    # KDE fuse helper
    kdePackages.kio-fuse

    devbox
  ];
}
