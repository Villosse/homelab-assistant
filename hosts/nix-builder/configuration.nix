{ config, pkgs, ... }:
let
  atticPushHook = pkgs.writeShellScript "attic-push-hook" ''
    set -f # Disable globbing

    export PATH="${pkgs.attic-client}/bin:$PATH"

    exec attic push cluster-cache $OUT_PATHS
  '';
in
{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nix-builder";
  networking.useDHCP = true;

  users.users.nix-builder = {
    isNormalUser = true;
    group = "nix-builder";
    openssh.authorizedKeys.keyFiles = [
      ./builder.keys
      ./root.keys
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

  nix.extraOptions = ''
    post-build-hook = ${atticPushHook}
  '';

  services.tailscale.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      # Interdit SSH pour tout le monde par défaut
      # DenyUsers = [ "nix-builder" ];
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

  environment.systemPackages = with pkgs; [ attic-client ];

  users.users.root = {
    initialPassword = "changeme";
    openssh.authorizedKeys.keyFiles = [
      ./root.keys
    ];
  };

  system.stateVersion = "24.11";
}
