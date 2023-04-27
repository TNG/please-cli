{
  description = "Please CLI by TNG Technology Consulting";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, flake-utils, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages = let p = import ./default.nix { inherit pkgs; }; in {
          please = p;
          default = p;
        };
      }
    );
}
