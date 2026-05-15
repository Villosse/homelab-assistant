{ pkgs, ... }:
{
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelParams = [
    "radeon.si_support=0"
    "amdgpu.si_support=1"
    "radeon.cik_support=0"
    "amdgpu.cik_support=1"
    "amdgpu.dc=1"
  ];
  hardware.enableRedistributableFirmware = true;

  networking.hostName = "dashboard";
  networking.networkmanager.enable = true;
  time.timeZone = "Europe/Paris";

  users.users.dashboard = {
    isNormalUser = true;
    extraGroups = [
      "video"
      "input"
    ];
  };

  services.getty.autologinUser = "dashboard";

  services.displayManager.autoLogin = {
    enable = true;
    user = "dashboard";
  };

  environment.systemPackages = with pkgs; [
    firefox
    kitty
    vim
    helix
    xorg.xrandr
    xorg.xset
    arandr
  ];

  environment.variables.TERMINAL = "kitty";

  services.xserver = {
    enable = true;
    videoDrivers = [ "amdgpu" ];
    displayManager.sessionCommands = ''
      xset -dpms
      xset s off
      xset s noblank
    '';
    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        dmenu
        i3status
        i3lock
      ];
    };
  };

  system.stateVersion = "25.11";
}
