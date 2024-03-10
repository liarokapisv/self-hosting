{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  inputs.disko.url = "github:nix-community/disko";
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";

  inputs.agenix.url = "github:ryantm/agenix";
  inputs.agenix.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, disko, agenix, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      nixosConfigurations.next-cloud = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit self;
        };
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          ./configuration.nix
        ];
      };

      devShells = forAllSystems
        (system:
          let
            pkgs = import nixpkgs {
              inherit system;
              config = {
                allowUnfree = true;
              };
            };
          in
          {
            default = pkgs.mkShell
              {
                packages = with pkgs;[
                  jq
                  gnused
                  terraform
                  terraform-ls
                  cntb
                  agenix.packages.${system}.default
                ] ++ nixpkgs.lib.optionals pkgs.stdenv.isLinux [
                  util-linux
                ];
              };
          });
    };
}
