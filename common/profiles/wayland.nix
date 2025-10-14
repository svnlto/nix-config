# Wayland/Sway Profile
# Optional module for desktop environments with Sway window manager
# Usage: Add to extraModules in flake.nix for specific configurations
{ config, pkgs, ... }:

{
  # Wayland-specific packages
  home.packages = with pkgs; [
    # Window manager
    sway # Tiling Wayland compositor
    swaylock # Screen locker
    swayidle # Idle management daemon

    # UI components
    waybar # Customizable status bar
    wofi # Application launcher
    mako # Notification daemon

    # Utilities
    grim # Screenshot tool
    slurp # Screen region selector
    wl-clipboard # Clipboard utilities (wl-copy, wl-paste)
    foot # Wayland-native terminal emulator

    # Additional desktop tools
    firefox # Web browser (Wayland-native)
  ];

  # Sway window manager configuration
  wayland.windowManager.sway = {
    enable = true;
    config = {
      modifier = "Mod4"; # Super/Windows key
      terminal = "foot";
      menu = "wofi --show drun";

      bars = [{ command = "waybar"; }];

      # Keybindings with vi-style navigation
      keybindings = let mod = config.wayland.windowManager.sway.config.modifier;
      in {
        # Basic actions
        "${mod}+Return" =
          "exec ${config.wayland.windowManager.sway.config.terminal}";
        "${mod}+Shift+q" = "kill";
        "${mod}+d" = "exec ${config.wayland.windowManager.sway.config.menu}";

        # Focus navigation (vi-style)
        "${mod}+h" = "focus left";
        "${mod}+j" = "focus down";
        "${mod}+k" = "focus up";
        "${mod}+l" = "focus right";

        # Move windows (vi-style)
        "${mod}+Shift+h" = "move left";
        "${mod}+Shift+j" = "move down";
        "${mod}+Shift+k" = "move up";
        "${mod}+Shift+l" = "move right";

        # Workspaces
        "${mod}+1" = "workspace number 1";
        "${mod}+2" = "workspace number 2";
        "${mod}+3" = "workspace number 3";
        "${mod}+4" = "workspace number 4";
        "${mod}+5" = "workspace number 5";
        "${mod}+6" = "workspace number 6";
        "${mod}+7" = "workspace number 7";
        "${mod}+8" = "workspace number 8";
        "${mod}+9" = "workspace number 9";
        "${mod}+0" = "workspace number 10";

        # Move containers to workspaces
        "${mod}+Shift+1" = "move container to workspace number 1";
        "${mod}+Shift+2" = "move container to workspace number 2";
        "${mod}+Shift+3" = "move container to workspace number 3";
        "${mod}+Shift+4" = "move container to workspace number 4";
        "${mod}+Shift+5" = "move container to workspace number 5";
        "${mod}+Shift+6" = "move container to workspace number 6";
        "${mod}+Shift+7" = "move container to workspace number 7";
        "${mod}+Shift+8" = "move container to workspace number 8";
        "${mod}+Shift+9" = "move container to workspace number 9";
        "${mod}+Shift+0" = "move container to workspace number 10";

        # Layout
        "${mod}+b" = "splith";
        "${mod}+v" = "splitv";
        "${mod}+s" = "layout stacking";
        "${mod}+w" = "layout tabbed";
        "${mod}+e" = "layout toggle split";
        "${mod}+f" = "fullscreen toggle";
        "${mod}+Shift+space" = "floating toggle";
        "${mod}+space" = "focus mode_toggle";

        # Reload/Exit
        "${mod}+Shift+c" = "reload";
        "${mod}+Shift+e" =
          "exec swaynag -t warning -m 'Exit sway?' -b 'Yes' 'swaymsg exit'";

        # Screenshots
        "Print" = ''exec grim -g "$(slurp)" - | wl-copy'';
        "Shift+Print" = ''
          exec grim -g "$(slurp)" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png'';
      };

      # Input configuration (adjust as needed)
      input = {
        "*" = {
          xkb_layout = "us";
          # Uncomment for touchpad
          # tap = "enabled";
          # natural_scroll = "enabled";
        };
      };

      # Output configuration (adjust for your display)
      output = {
        "*" = {
          bg = "#1e1e2e solid_color"; # Catppuccin Mocha background
        };
      };
    };
  };

  # Waybar status bar configuration
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        modules-left = [ "sway/workspaces" "sway/mode" ];
        modules-center = [ "sway/window" ];
        modules-right = [ "cpu" "memory" "clock" ];

        cpu = {
          format = " {usage}%";
          tooltip = false;
        };

        memory = {
          format = " {}%";
          tooltip = false;
        };

        clock = {
          format = " {:%H:%M}";
          format-alt = " {:%Y-%m-%d}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
        };

        "sway/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
        };
      };
    };

    # Catppuccin Mocha theme for Waybar
    style = ''
      * {
        font-family: "Hack Nerd Font";
        font-size: 13px;
        border: none;
        border-radius: 0;
      }

      window#waybar {
        background: #1e1e2e;
        color: #cdd6f4;
      }

      #workspaces button {
        padding: 0 5px;
        background: transparent;
        color: #cdd6f4;
        border-bottom: 3px solid transparent;
      }

      #workspaces button.focused {
        background: #313244;
        border-bottom: 3px solid #89b4fa;
      }

      #clock,
      #cpu,
      #memory {
        padding: 0 10px;
        margin: 0 5px;
        background: #313244;
      }
    '';
  };

  # Mako notification daemon configuration
  services.mako = {
    enable = true;
    settings = {
      background-color = "#1e1e2e";
      text-color = "#cdd6f4";
      border-color = "#89b4fa";
      border-size = 2;
      border-radius = 5;
      default-timeout = 5000;
    };
  };
}
