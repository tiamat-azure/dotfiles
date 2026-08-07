{
  description = "dotfiles Ubuntu de Tiamat";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # Pour les paquets absents du channel stable ci-dessus (ex: herdr).
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # Nécessaire hors NixOS : fournit les libs OpenGL/EGL (Mesa/Nvidia) que les
    # apps GUI construites par Nix (wezterm...) cherchent à charger au runtime.
    nixgl.url = "github:nix-community/nixGL";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, nixgl, ... }:
    let
      system = "x86_64-linux";
      pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
      # Une config par machine : le même home.nix, paramétré par utilisateur et
      # par `desktop` (les blocs GNOME/GUI ne s'appliquent que si desktop = true).
      mkHome = { username, desktop }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = { inherit nixgl system pkgs-unstable username desktop; };
          modules = [ ./home.nix ];
        };
    in {
      homeConfigurations = {
        # Portable : Ubuntu desktop natif (GNOME + WezTerm/nixGL + services GUI).
        "2456bru" = mkHome { username = "2456bru"; desktop = true; };
        # PC bureautique sous WSL2 : cœur CLI + symlinks, sans GNOME/GUI.
        "tiamat" = mkHome { username = "tiamat"; desktop = false; };
      };
    };
}
