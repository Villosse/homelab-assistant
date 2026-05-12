{ config, pkgs, ... }:

{
  # 1. Dashboard User Definition
  users.users.dashboard = {
    isNormalUser = true;
    description = "Kiosk Dashboard User";
    extraGroups = [
      "video"
      "input"
    ]; # Required for hardware acceleration & Wayland
  };

  # 2. Autologin on tty1
  services.getty.autologinUser = "dashboard";

  # 3. Auto-start Sway when the dashboard user logs into tty1
  environment.loginShellInit = ''
    if [ "$(tty)" = "/dev/tty1" ] && [ "$USER" = "dashboard" ]; then
      exec sway
    fi
  '';

  # 4. Enable Sway and Native Wayland for Firefox
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1"; # Forces Firefox to use Wayland natively
  };

  # 5. Required Packages
  environment.systemPackages = with pkgs; [
    firefox
    kitty # Added as a failsafe terminal in case you need to debug
  ];

  # 6. Declarative Sway Configuration
  environment.etc."sway/config".text = ''
    # --- Failsafe ---
    # Press Super/Windows + Enter to open a terminal if things break
    set $mod Mod4
    bindsym $mod+Return exec kitty

    # --- Appearance & Kiosk Mode ---
    default_border none
    hide_edge_borders both
    # Hide the bottom status bar
    bar {
        mode hide
    }

    # Disable screen blanking (Keep dashboards ON 24/7)
    exec swaymsg "output * dpms on"

    # --- Monitor Assignment ---
    # NOTE: You MUST replace these with your actual output names!
    # Run `swaymsg -t get_outputs` in the terminal to find them.
    workspace 1 output DP-1
    workspace 2 output DP-2
    workspace 3 output HDMI-A-1

    # --- Launch Firefox on Specific Monitors ---
    # We use 'sleep' to ensure Firefox fully claims the active workspace 
    # before Sway switches to the next one.

    # Monitor 1
    exec "swaymsg 'workspace 1; exec firefox --kiosk --new-window https://dashboard1.example.com'"

    # Monitor 2 (Wait 3 seconds for the first to load, then switch and launch)
    exec "sleep 3 && swaymsg 'workspace 2; exec firefox --kiosk --new-window https://dashboard2.example.com'"

    # Monitor 3 (Wait another 3 seconds)
    exec "sleep 6 && swaymsg 'workspace 3; exec firefox --kiosk --new-window https://dashboard3.example.com'"
  '';
}
