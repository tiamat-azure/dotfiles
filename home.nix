{ pkgs, ... }:

{
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
  ];

  programs.home-manager.enable = true;
}
