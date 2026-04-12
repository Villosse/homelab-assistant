{ config, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  networking.hostName = "k3s-master";
  networking.useDHCP = true;

  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = "--disable traefik"; # on gérera l'ingress nous-mêmes
  };

  services.tailscale.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  users.users.root = {
    initialPassword = "changeme";
    openssh.authorizedKeys.keyFiles = [ ./root.keys ];
  };

  nix.settings.trusted-users = [ "root" ];

  environment.systemPackages = with pkgs; [
    kubectl
    k9s
  ];

  system.stateVersion = "24.11";
}
