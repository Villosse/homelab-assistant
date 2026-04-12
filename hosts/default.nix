{ nixpkgs }:
{
  nix-builder = import ./nix-builder { inherit nixpkgs; };
}
