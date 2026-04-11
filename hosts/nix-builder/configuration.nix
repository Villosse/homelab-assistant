{ config, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nix-builder";
  networking.useDHCP = true;

  users.users.nix-builder = {
    isSystemUser = true;
    group = "nix-builder";
    openssh.authorizedKeys.keys = [
      "" # clé SSH du client Nix
    ];
  };
  users.groups.nix-builder = { };

  nix.settings = {
    trusted-users = [ "nix-builder" ];
    min-free = 10 * 1024 * 1024 * 1024;
    max-free = 20 * 1024 * 1024 * 1024;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      # Interdit SSH pour tout le monde par défaut
      DenyUsers = [ "nix-builder" ];
      # Seul root peut se connecter normalement
      PermitRootLogin = "prohibit-password";
    };
    extraConfig = ''
      Match User nix-builder
        ForceCommand ${pkgs.nix}/bin/nix-daemon --stdio
        AllowTcpForwarding no
        AllowAgentForwarding no
        PermitTTY no
    '';
  };

  users.users.root = {
    initialPassword = "changeme";
    openssh.authorizedKeys.keys = [
      "" # ta clé SSH perso
    ];
  };

  system.stateVersion = "24.11";
}
