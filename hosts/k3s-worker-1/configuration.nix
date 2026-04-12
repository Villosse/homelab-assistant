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
    token = "K10bd718a26a752b25a1c8a443d7fafd1469f6b9d1dc031b7c3c45244ccf286d6d8::server:7509289155d84cd7972023295e1d221c";
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

  networking.firewall = {
    allowedTCPPorts = [
      6443
      30829
      31589
    ];
    trustedInterfaces = [
      "cni0"
      "flannel.1"
      "tailscale0"
    ];
  };

  system.stateVersion = "24.11";
}
