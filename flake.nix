{
  description = "Homelab infrastructure";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-25-11.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs =
    { self, nixpkgs, nixpkgs-25-11 }:
    {
      nixosConfigurations = import ./hosts { inherit nixpkgs nixpkgs-25-11; };
    };
}
