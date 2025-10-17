# Omarchy-inspired Arch Linux Profile
# Single comprehensive profile replicating Omarchy's feature set
# Based on: https://github.com/basecamp/omarchy
# Theme: Catppuccin Mocha (your preferred theme)
{ config, pkgs, ... }:

{
  # ==========================================
  # Hyprland Window Manager (Omarchy's choice)
  # ==========================================
  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      # Monitor configuration
      monitor = [ ",preferred,auto,1" ];

      # Autostart
      exec-once = [
        "waybar"
        "mako"
        "hyprpaper"
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
      ];

      # Environment variables
      env =
        [ "XCURSOR_SIZE,24" "QT_QPA_PLATFORM,wayland" "MOZ_ENABLE_WAYLAND,1" ];

      # Input configuration
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
        };
        sensitivity = 0;
      };

      # General settings with Catppuccin Mocha colors
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(89b4faee) rgba(cba6f7ee) 45deg";
        "col.inactive_border" = "rgba(585b70aa)";
        layout = "dwindle";
      };

      # Decoration
      decoration = {
        rounding = 8;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
        };
        drop_shadow = true;
        shadow_range = 4;
        shadow_render_power = 3;
        "col.shadow" = "rgba(1a1a1aee)";
      };

      # Animations
      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      # Layout
      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      # Gestures
      gestures = { workspace_swipe = true; };

      # Keybindings
      "$mod" = "SUPER";
      bind = [
        "$mod, Return, exec, ghostty"
        "$mod, D, exec, wofi --show drun"
        "$mod SHIFT, Q, killactive"
        "$mod SHIFT, E, exit"
        "$mod, V, togglefloating"
        "$mod, F, fullscreen"

        # Vi-style navigation
        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, K, movefocus, u"
        "$mod, J, movefocus, d"
        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, L, movewindow, r"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, J, movewindow, d"

        # Workspaces
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"

        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"

        # Screenshots
        '', Print, exec, grim -g "$(slurp)" - | wl-copy''
        ''
          SHIFT, Print, exec, grim -g "$(slurp)" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png''
      ];

      bindm = [ "$mod, mouse:272, movewindow" "$mod, mouse:273, resizewindow" ];
    };
  };

  # ==========================================
  # Packages
  # ==========================================
  home.packages = with pkgs; [
    # Hyprland ecosystem
    hyprland
    hyprpaper
    hypridle
    hyprlock
    hyprpicker

    # UI components
    waybar
    wofi
    mako
    polkit_gnome

    # Utilities
    grim
    slurp
    wl-clipboard
    firefox

    # Development tools (Omarchy essentials)
    mise # Version manager (Node, Ruby, Python, etc.)
    lazydocker # Docker TUI
    btop # System monitor
    docker
    docker-compose

    # Database CLIs
    postgresql
    mysql80
    redis
    sqlite

    # API development
    httpie
    jq

    # Desktop applications
    obsidian # Note-taking
    signal-desktop # Encrypted messaging
    chromium # Browser
    localsend # File sharing

    # Media (comment out what you don't want)
    mpv # Media player
    spotify # Music
    # obs-studio # Screen recording
    # kdenlive # Video editing
    # pinta # Image editing
  ];

  # ==========================================
  # Program Configurations
  # ==========================================

  # Mise (version manager)
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
  };

  # MPV
  programs.mpv = {
    enable = true;
    config = {
      profile = "gpu-hq";
      hwdec = "auto-safe";
      screenshot-directory = "~/Pictures/mpv-screenshots";
    };
  };

  # Chromium
  programs.chromium = { enable = true; };

  # Waybar with Catppuccin Mocha
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        modules-left = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "clock" ];
        modules-right =
          [ "cpu" "memory" "pulseaudio" "network" "battery" "tray" ];

        "hyprland/workspaces" = {
          format = "{id}";
          on-click = "activate";
        };

        "hyprland/window" = {
          max-length = 50;
          separate-outputs = true;
        };

        cpu = {
          format = " {usage}%";
          tooltip = false;
        };

        memory = {
          format = " {}%";
          tooltip = false;
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = " Muted";
          format-icons = { default = [ "" "" "" ]; };
          on-click = "pavucontrol";
        };

        network = {
          format-wifi = " {essid}";
          format-ethernet = " {ifname}";
          format-disconnected = "⚠ Disconnected";
          tooltip-format = "{ifname}: {ipaddr}";
        };

        battery = {
          format = "{icon} {capacity}%";
          format-icons = [ "" "" "" "" "" ];
          format-charging = " {capacity}%";
        };

        clock = {
          format = " {:%H:%M}";
          format-alt = " {:%Y-%m-%d}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
        };

        tray = {
          icon-size = 16;
          spacing = 10;
        };
      };
    };

    # Catppuccin Mocha theme
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

      #workspaces button.active {
        background: #313244;
        border-bottom: 3px solid #89b4fa;
      }

      #clock, #cpu, #memory, #pulseaudio, #network, #battery, #tray {
        padding: 0 10px;
        margin: 0 5px;
        background: #313244;
      }

      #battery.charging { color: #a6e3a1; }
      #battery.warning:not(.charging) { color: #f9e2af; }
      #battery.critical:not(.charging) { color: #f38ba8; }
    '';
  };

  # Mako notifications (Catppuccin Mocha)
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

  # Hyprpaper (wallpaper)
  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [
        # Add your wallpaper path here
      ];
      wallpaper = [
        # ",/path/to/wallpaper.png"
      ];
    };
  };

  # Hypridle (idle management)
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };
      listener = [
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 600;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };

  # Hyprlock (screen locker with Catppuccin Mocha)
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        grace = 0;
        hide_cursor = true;
        no_fade_in = false;
      };

      background = [{
        path = "screenshot";
        blur_passes = 3;
        blur_size = 8;
      }];

      input-field = [{
        size = "200, 50";
        position = "0, -80";
        monitor = "";
        dots_center = true;
        fade_on_empty = false;
        font_color = "rgb(205, 214, 244)";
        inner_color = "rgb(49, 50, 68)";
        outer_color = "rgb(30, 30, 46)";
        outline_thickness = 5;
        placeholder_text = ''<span foreground="##cdd6f4">Password...</span>'';
        shadow_passes = 2;
      }];
    };
  };

  # ==========================================
  # Shell Configuration
  # ==========================================
  programs.zsh.shellAliases = {
    # Docker shortcuts
    dps = "docker ps";
    dpa = "docker ps -a";
    di = "docker images";
    dex = "docker exec -it";
    dlogs = "docker logs -f";
    lzd = "lazydocker";

    # Database shortcuts
    pgstart =
      "docker run --name postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres";
    mysqlstart =
      "docker run --name mysql -e MYSQL_ROOT_PASSWORD=mysql -p 3306:3306 -d mysql:8.0";
    redisstart = "docker run --name redis -p 6379:6379 -d redis";
  };

  # Environment variables
  home.sessionVariables = {
    BROWSER = "chromium";
    MISE_DATA_DIR = "${config.home.homeDirectory}/.local/share/mise";
    MISE_CONFIG_DIR = "${config.home.homeDirectory}/.config/mise";
  };

  # XDG MIME associations
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "chromium.desktop";
      "x-scheme-handler/http" = "chromium.desktop";
      "x-scheme-handler/https" = "chromium.desktop";
      "text/markdown" = "obsidian.desktop";
      "video/mp4" = "mpv.desktop";
      "audio/mpeg" = "mpv.desktop";
    };
  };

  # XDG portal for Hyprland
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    config.common.default = "*";
  };
}
