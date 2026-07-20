{
  description = "dotfiles Ubuntu de Tiamat";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # Nécessaire hors NixOS : fournit les libs OpenGL/EGL (Mesa/Nvidia) que les
    # apps GUI construites par Nix (wezterm...) cherchent à charger au runtime.
    nixgl.url = "github:nix-community/nixGL";
  };

  outputs = { self, nixpkgs, home-manager, nixgl, ... }:
    let
      system = "x86_64-linux";
      user = "2456bru";
    in {
      homeConfigurations.${user} = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = { inherit nixgl system; };
        modules = [ ./home.nix ];
      };
    };
}
