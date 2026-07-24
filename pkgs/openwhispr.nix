{ pkgs }:

let
  pname = "openwhispr";
  version = "1.7.6";
  src = pkgs.fetchurl {
    url = "https://github.com/OpenWhispr/openwhispr/releases/download/v${version}/OpenWhispr-${version}-linux-x86_64.AppImage";
    hash = "sha256-8c1bE3ZfJTb0ZXQb3mRAfj7QtMoUkaby8N3133Gg3z4=";
  };
  appimageContents = pkgs.appimageTools.extractType2 {
    inherit pname version src;
  };
in
pkgs.stdenv.mkDerivation {
  inherit pname version src;
  dontUnpack = true;
  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/${pname}" "$out/bin"
    cp -a ${appimageContents}/* "$out/lib/${pname}/"

    makeWrapper "$out/lib/${pname}/AppRun" "$out/bin/${pname}" \
      --chdir "$out/lib/${pname}" \
      --set SSL_CERT_FILE /etc/ssl/certs/ca-certificates.crt \
      --set NIX_SSL_CERT_FILE /etc/ssl/certs/ca-certificates.crt \
      --set NODE_EXTRA_CA_CERTS /etc/ssl/certs/ca-certificates.crt \
      --add-flags "--use-system-cert-verifier"

    runHook postInstall
  '';
}
