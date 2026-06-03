{
  description = "Homelab infrastructure";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs =
    { self, nixpkgs }:
    let
      mkHost =
        host:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./modules/base.nix
            ./modules/ssh.nix
            ./hosts/${host}/hardware-configuration.nix
            ./hosts/${host}/configuration.nix
          ];
        };
    in
    {
      nixosConfigurations = {
        nix-builder = mkHost "nix-builder";
        k3s-master = mkHost "k3s-master";
        k3s-worker-1 = mkHost "k3s-worker-1";
        dashboard = mkHost "dashboard";
      };
    };
}
