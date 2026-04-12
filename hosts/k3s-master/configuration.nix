{ config, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  networking.hostName = "k3s-master";
  networking.useDHCP = true;
  environment.variables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";

  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = "--disable traefik --write-kubeconfig-mode 644"; # on gérera l'ingress nous-mêmes
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

  environment.systemPackages = with pkgs; [
    kubectl
    k9s
  ];

  system.stateVersion = "24.11";
}
