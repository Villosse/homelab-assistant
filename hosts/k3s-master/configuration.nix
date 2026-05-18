{ config, pkgs, ... }:
{
  networking.hostName = "k3s-master";
  networking.useDHCP = true;
  environment.variables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";

  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = "--disable traefik --write-kubeconfig-mode 644";
  };

  networking.firewall = {
    allowedTCPPorts = [
      6443
      30829
      31589
    ];
    trustedInterfaces = [
      "cni0"
      "flannel.1"
    ];
    allowedUDPPorts = [
      8472
    ];
  };

  environment.systemPackages = with pkgs; [
    kubectl
    k9s
  ];

  system.stateVersion = "25.11";
}
