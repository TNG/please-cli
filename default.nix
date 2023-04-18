{ pkgs ? import <nixpkgs> { }

, stdenv ? pkgs.stdenv
, lib ? pkgs.lib
, makeWrapper ? pkgs.makeWrapper

, curl ? pkgs.curl
, jq ? pkgs.jq
}:

stdenv.mkDerivation rec {
  name = "please";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin

    cp $src/please.sh $out/bin/

    makeWrapper $out/bin/please.sh $out/bin/${name} \
      --prefix PATH : ${lib.makeBinPath [ curl jq ]}
  '';

  meta = with lib; {
    homepage = "https://github.com/TNG/please-cli";
    description = "An AI helper script to create CLI commands.";
    platforms = platforms.all;
    license = licenses.asl20;
  };
}
