{ pkgs, ... }:
let
in
{
  networking.hostName = "nix-assistant";
  networking.useDHCP = true;

  users.users.assistant = {
    isNormalUser = true;
    group = "users";
    openssh.authorizedKeys.keyFiles = [
      ../../modules/root.keys
      ./assistants.keys
    ];
  };

  nix.settings = {
    trusted-users = [ "assistant" ];
    min-free = 10 * 1024 * 1024 * 1024;
    max-free = 20 * 1024 * 1024 * 1024;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  environment.systemPackages = with pkgs; [
    vim
    helix
    git
  ];

  system.stateVersion = "25.11";
}
