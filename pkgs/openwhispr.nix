{ pkgs }:

pkgs.appimageTools.wrapType2 rec {
  pname = "openwhispr";
  version = "1.7.6";

  src = pkgs.fetchurl {
    url = "https://github.com/OpenWhispr/openwhispr/releases/download/v${version}/OpenWhispr-${version}-linux-x86_64.AppImage";
    hash = "sha256-8c1bE3ZfJTb0ZXQb3mRAfj7QtMoUkaby8N3133Gg3z4=";
  };
}
