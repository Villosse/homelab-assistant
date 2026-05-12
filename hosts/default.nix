{ nixpkgs }:
{
  nix-builder = import ./nix-builder { inherit nixpkgs; };
  k3s-master = import ./k3s-master { inherit nixpkgs; };
  k3s-worker-1 = import ./k3s-worker-1 { inherit nixpkgs; };
  dashboard = import ./dashboard { inherit nixpkgs; };
}
