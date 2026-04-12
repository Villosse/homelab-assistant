{ nixpkgs }:
{
  nix-builder = import ./nix-builder { inherit nixpkgs; };
  k3s-master = import ./k3s-master { inherit nixpkgs; };
}
