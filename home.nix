{ config, pkgs, nixgl, system, ... }:

let
  # Hors NixOS, wezterm ne trouve pas libEGL au runtime (pas de /run/opengl-driver).
  # On le fait passer par nixGL, qui injecte les bonnes libs Mesa/Intel.
  wezterm-gl = pkgs.writeShellScriptBin "wezterm" ''
    exec ${nixgl.packages.${system}.nixGLIntel}/bin/nixGLIntel ${pkgs.wezterm}/bin/wezterm "$@"
  '';

  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in
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
    wezterm-gl
    nerd-fonts.hack
  ];
  fonts.fontconfig.enable = true;

  programs.home-manager.enable = true;

  # Edit-in-place à la Kun Chen : le vrai fichier reste dans le repo,
  # ~/.config/wezterm n'est qu'un lien vers lui (pas de rebuild pour l'éditer).
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";

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
