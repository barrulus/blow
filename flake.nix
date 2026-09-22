{
  description = "Flow Control text editor (barrulus/blow)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          flow = pkgs.callPackage ./nix/package.nix { };
        in
        {
          default = flow;
          flow-control = flow;
        }
      );

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/flow";
          meta.description = "Flow Control text editor";
        };
      });

      overlays.default = final: prev: {
        flow-control = final.callPackage ./nix/package.nix { };
      };

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.zig_0_16
              pkgs.git
              pkgs.ripgrep
            ];
          };
        }
      );

      checks = forAllSystems (system: {
        inherit (self.packages.${system}) flow-control;
      });
    };
}
