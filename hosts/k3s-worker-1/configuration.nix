{ config, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "k3s-worker";
  networking.useDHCP = true;

  services.k3s = {
    enable = true;
    role = "agent";
    serverAddr = "https://192.168.2.153:6443";
    tokenFile = /etc/k3s-token;
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

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "24.11";
}
