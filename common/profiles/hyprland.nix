# Omarchy-inspired Arch Linux Profile
# This profile is Linux-only and should not be applied to macOS systems
{ pkgs, lib, ... }:

assert lib.assertMsg pkgs.stdenv.isLinux
  "Hyprland profile is Linux-only. Remove this profile from extraModules when building macOS configurations.";

{
  # macOS-like font configuration
  fonts.fontconfig.enable = true;

  # Using system Hyprland from pacman for hardware compatibility
  # Config will still be generated at ~/.config/hypr/hyprland.conf
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false; # Don't manage via systemd

    settings = {

      exec-once = [
        "waybar"
        "mako"
        "hyprpaper"
        "/usr/lib/hyprpolkitagent/hyprpolkitagent"
        "blueman-applet"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
        "ELECTRON_OZONE_PLATFORM_HINT=x11 /opt/1Password/1password --silent"
      ];

      env =
        [ "XCURSOR_SIZE,24" "QT_QPA_PLATFORM,wayland" "MOZ_ENABLE_WAYLAND,1" ];

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        sensitivity = 0;
        touchpad = { natural_scroll = true; };
      };

      general = {
        gaps_in = 2;
        gaps_out = 5;
        border_size = 2;
        "col.active_border" = "rgba(89b4faee) rgba(cba6f7ee) 45deg";
        "col.inactive_border" = "rgba(585b70aa)";
        layout = "dwindle";
      };

      decoration = {
        blur = {
          enabled = true;
          size = 8;
          passes = 3;
          new_optimizations = true;
          xray = true;
          noise = 1.17e-2;
          contrast = 0.8916;
          brightness = 0.8172;
        };
        rounding = 10;
        active_opacity = 1.0;
        inactive_opacity = 0.95;
        fullscreen_opacity = 1.0;
      };

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

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      misc = {
        disable_hyprland_logo = true;
        vfr = true;
        vrr = 0;
        animate_manual_resizes = true;
        animate_mouse_windowdragging = true;
        enable_swallow = true;
        swallow_regex = "^(foot|kitty|alacritty)$";
      };

      "$mod" = "SUPER";
      bind = [
        "$mod, Return, exec, /usr/bin/ghostty"
        "$mod, Space, exec, rofi -show drun"
        "$mod, C, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"
        "$mod SHIFT, Q, killactive"
        "$mod SHIFT, E, exit"
        "$mod, V, togglefloating"
        "$mod, F, fullscreen"

        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, K, movefocus, u"
        "$mod, J, movefocus, d"
        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, L, movewindow, r"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, J, movewindow, d"

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

        # Screenshots: saves file AND copies FILE PATH to clipboard (Claude Code can read the path)
        "$mod SHIFT, S, exec, bash -c 'mkdir -p ~/Pictures/screenshots && FILE=~/Pictures/screenshots/$(date +%Y-%m-%d_%H-%M-%S).png && grim -g \"$(slurp)\" \"$FILE\" && echo -n \"$FILE\" | wl-copy'"

        # Audio output switcher
        "$mod, A, exec, ~/.local/bin/rofi-audio-switcher"
      ];

      bindl = [
        # Media keys
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ];

      bindle = [
        # Volume control (repeatable)
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"

        # Brightness control
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ];

      bindm = [ "$mod, mouse:272, movewindow" "$mod, mouse:273, resizewindow" ];
    };
  };

  # Monitor configuration as a separate file
  home.file.".config/hypr/monitors.conf".text = ''
    monitor=eDP-1,1920x1080@60,0x0,1
    monitor=DP-3,5120x2880@60,1920x0,2
    monitor=,preferred,auto,1
  '';

  home.packages = with pkgs; [
    hyprpaper
    hypridle
    hyprlock
    hyprpicker
    waybar
    rofi
    wlogout
    mako
    polkit_gnome
    grim
    slurp
    wl-clipboard
    cliphist
    foot
    pavucontrol
    brightnessctl
    bluez
    bluez-tools
    blueman
    docker
    docker-compose
    lazydocker
    btop
    jq
    obsidian
    signal-desktop
    chromium
    localsend
    mpv
    mesa
    # macOS-like fonts
    inter
  ];

  programs.mpv = {
    enable = true;
    config = {
      profile = "gpu-hq";
      hwdec = "auto-safe";
      screenshot-directory = "~/Pictures/mpv-screenshots";
    };
  };

  programs.chromium = { enable = true; };

  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        modules-left = [ "clock" "hyprland/workspaces" "tray" ];
        modules-center = [ "hyprland/window" ];
        modules-right = [
          "temperature"
          "memory"
          "cpu"
          "pulseaudio"
          "battery"
          "bluetooth"
          "network"
          "custom/powermenu"
        ];

        "hyprland/workspaces" = {
          format = "{icon}";
          on-click = "activate";
          separate-outputs = false;
          active-only = false;
          all-outputs = false;
          format-icons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            "6" = "6";
            "7" = "7";
            "8" = "8";
            "9" = "9";
            "10" = "10";
          };
        };

        "hyprland/window" = {
          format = "{}";
          max-length = 50;
          separate-outputs = true;
        };

        cpu = {
          format = " {usage}%";
          tooltip = false;
        };

        memory = {
          format = "󰫗 {}%";
          tooltip = false;
        };

        temperature = {
          format = "{icon} {temperatureC}°C";
          hwmon-path = "/sys/class/hwmon/hwmon6/temp1_input";
          critical-threshold = 80;
          format-icons = [ "" "" "" ];
        };

        pulseaudio = {
          format = " {volume}%";
          format-muted = " Muted";
          scroll-step = 1;
          on-click = "pavucontrol";
        };

        network = {
          format = " 󰖩";
          format-wifi = " {essid} ↓{bandwidthDownBytes} ↑{bandwidthUpBytes}";
          format-ethernet =
            " {ifname} ↓{bandwidthDownBytes} ↑{bandwidthUpBytes}";
          format-disconnected = "⚠ Disconnected";
          tooltip-format = ''
            {essid}
            IP: {ipaddr}
            ↓ {bandwidthDownBytes} ↑ {bandwidthUpBytes}'';
          interval = 2;
        };

        bluetooth = {
          format = "";
          format-on = "";
          format-off = "";
          format-disabled = "";
          format-connected = " {device_alias}";
          format-connected-battery =
            " {device_alias} {device_battery_percentage}%";
          tooltip-format = ''
            {controller_alias}	{controller_address}

            {num_connections} connected'';
          tooltip-format-connected = ''
            {controller_alias}	{controller_address}

            {num_connections} connected

            {device_enumerate}'';
          tooltip-format-enumerate-connected =
            "{device_alias}	{device_address}";
          tooltip-format-enumerate-connected-battery =
            "{device_alias}	{device_address}	{device_battery_percentage}%";
          on-click = "blueman-manager";
        };

        battery = {
          format = "{capacity}% {icon}";
          format-icons = [ "" "" "" "" "" ];
          format-charging = " {capacity}%";
        };

        clock = {
          format = " 󰸗 {:%H:%M}";
          format-alt = " 󰸗 {:%Y-%m-%d}";
          interval = 60;
          tooltip = true;
          tooltip-format = "{:%d %B %H:%M}";
        };

        tray = {
          icon-size = 16;
          spacing = 8;
        };

        "custom/powermenu" = {
          format = "⏻";
          tooltip = false;
          on-click = "wlogout -p layer-shell";
        };
      };
    };

    style = ''
      * {
        font-family: "Inter", "Hack Nerd Font";
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

  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [ "~/.config/wallpaper.jpg" ];
      wallpaper =
        [ ",contain:~/.config/wallpaper.jpg" ]; # contain instead of stretch
      splash = false;
      ipc = false;
    };
  };

  home.file.".config/wallpaper.jpg".source = ./wallpapers/bg.jpg;

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

  home.sessionVariables = { BROWSER = "chromium"; };

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

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    config.common.default = "*";
  };

  # PipeWire audio profile configuration - use Speaker instead of Headphones
  xdg.configFile."wireplumber/main.lua.d/51-thinkpad-speaker.lua".text = ''
    rule = {
      matches = {
        {
          { "device.name", "equals", "alsa_card.pci-0000_00_1f.3-platform-skl_hda_dsp_generic" },
        },
      },
      apply_properties = {
        ["device.profile"] = "HiFi (HDMI1, HDMI2, HDMI3, Mic1, Mic2, Speaker)",
      },
    }

    table.insert(alsa_monitor.rules, rule)
  '';

  # MOTU UltraLite-mk4 configuration
  xdg.configFile."wireplumber/main.lua.d/52-motu-ultralite.lua".text = ''
    -- Channel mapping - route stereo to main outputs (channels 0-1)
    rule = {
      matches = {
        {
          { "node.name", "equals", "alsa_output.usb-MOTU_UltraLite-mk4_0001f2fffe00a1fe-00.multichannel-output" },
        },
      },
      apply_properties = {
        ["audio.position"] = "FL,FR",
        ["api.alsa.period-size"] = 256,
        ["api.alsa.headroom"] = 1024,
        ["priority.session"] = 2000,  -- Higher priority than laptop speakers (1100)
      },
    }
    table.insert(alsa_monitor.rules, rule)

    -- Auto-select UltraLite when connected
    ultralite_rule = {
      matches = {
        {
          { "device.name", "equals", "alsa_card.usb-MOTU_UltraLite-mk4_0001f2fffe00a1fe-00" },
        },
      },
      apply_properties = {
        ["device.disabled"] = false,
        ["priority.driver"] = 2000,
        ["priority.session"] = 2000,
      },
    }
    table.insert(alsa_monitor.rules, ultralite_rule)
  '';
}
