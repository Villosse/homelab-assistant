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
  networking.firewall.extraCommands = ''
    # fxled
    iptables -A INPUT -p tcp --dport 8888 -m comment --comment "fxled" -j ACCEPT
  '';
  time.timeZone = "Europe/Paris";

  users.users.dashboard = {
    isNormalUser = true;
    extraGroups = [
      "video"
      "input"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGxaMAEHzRS8L757ktuJHHwdSqTwmFn/lHLsR0vL6qFL stor@gram"
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHBzvWN6JI7NJdgGyoygFYfVcrjx2N22NVukJ523jLtM gabin1.cadic"
  ];

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
    xrandr
    xset
    arandr
    pavucontrol
    ledfx
    alsa-utils
  ];

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  environment.variables.TERMINAL = "kitty";

  services.xserver = {
    enable = true;
    videoDrivers = [ "amdgpu" ];
    serverFlagsSection = ''
      Option "BlankTime" "0"
      Option "StandbyTime" "0"
      Option "SuspendTime" "0"
      Option "OffTime" "0"
    '';
    monitorSection = ''
      Option "DPMS" "false"
    '';
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
