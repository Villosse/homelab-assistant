{ ... }:
{
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
}
