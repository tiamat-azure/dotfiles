{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  home.username = "2456bru";
  home.homeDirectory = "/home/2456bru";

  # Ne change jamais cette valeur après la première install :
  # https://nix-community.github.io/home-manager/index.xhtml#sec-install-standalone
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    ripgrep
    fd
    bat
    htop
    wezterm
  ];

  programs.home-manager.enable = true;

  # Équivalent GNOME des system.defaults de nix-darwin (dark mode, dock, trackpad...).
  dconf.settings = {
    "org/gnome/desktop/interface".color-scheme = "prefer-dark";

    "org/gnome/desktop/peripherals/keyboard" = {
      repeat-interval = 20; # répétition rapide (ms)
      delay = 200;          # délai avant répétition (ms)
    };

    "org/gnome/desktop/peripherals/touchpad".tap-to-click = true;

    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-fixed = false; # nécessaire pour l'auto-hide
      autohide = true;
    };

    "org/gnome/nautilus/preferences".default-folder-viewer = "list-view";
  };
}
