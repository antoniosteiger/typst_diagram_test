{
  description = "Lean LaTeX environment for thesis diagrams";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAll = f: nixpkgs.lib.genAttrs systems (s: f nixpkgs.legacyPackages.${s});
    in {
      devShells = forAll (pkgs: {
        default = pkgs.mkShell {
          packages = [
            (pkgs.texlive.combine {
              inherit (pkgs.texlive) scheme-basic standalone pgf xcolor amsmath amsfonts lm latex-bin;
            })
          ];
        };
      });
    };
}
