{ pkgs, ... }:
let
in
{
  networking.hostName = "nix-builder";
  networking.useDHCP = true;

  users.users.nix-builder = {
    isNormalUser = true;
    group = "nix-builder";
    openssh.authorizedKeys.keyFiles = [
      ./builder.keys
      ../../modules/root.keys
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

  services.openssh.extraConfig = ''
    Match User nix-builder
      ForceCommand ${pkgs.nix}/bin/nix-daemon --stdio
      AllowTcpForwarding no
      AllowAgentForwarding no
      PermitTTY no
  '';

  environment.systemPackages = with pkgs; [ attic-client ];

  # Asynchronously push to the cache, without using a synchronous post-build-hook
  systemd.services.attic-watch-store = {
    description = "Attic watch-store daemon";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.attic-client}/bin/attic watch-store yaka-cache";
      Restart = "on-failure";
      RestartSec = "5s";
      # Ensure this runs as a user that has access to the Nix store and is logged into Attic
      User = "root";
    };
  };

  system.stateVersion = "25.11";
}
