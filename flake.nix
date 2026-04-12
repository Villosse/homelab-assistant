{
  description = "Homelab infrastructure";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs =
    { self, nixpkgs }:
    {
      nixosConfigurations = import ./hosts { inherit nixpkgs; };
    };
}
