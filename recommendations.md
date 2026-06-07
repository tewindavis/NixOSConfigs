# Hyprland Configuration Recommendations

Your current Hyprland setup is syntactically valid but functionally minimal. To make it a truly "daily driver" environment across your three systems (UTM, Framework, and Threadripper Rig), I recommend adding the following blocks to your `users/td/home.nix`.

## 1. Window Navigation & Workspaces
Currently, you can open windows but cannot move between them or use multiple workspaces.

### Recommended Bindings:
```nix
bind = [
  # Focus navigation (Vim-style)
  "SUPER, h, movefocus, l"
  "SUPER, l, movefocus, r"
  "SUPER, k, movefocus, u"
  "SUPER, j, movefocus, d"

  # Workspace Switching (1-9)
  "SUPER, 1, workspace, 1"
  "SUPER, 2, workspace, 2"
  "SUPER, 3, workspace, 3"
  # ... through 9

  # Move Window to Workspace (1-9)
  "SUPER_SHIFT, 1, movetoworkspace, 1"
  "SUPER_SHIFT, 2, movetoworkspace, 2"
  # ... through 9
];
```

## 2. Monitor & Scaling (Critical for Framework)
The Framework 13 has a high-resolution display. Without scaling, your text will be tiny.

### Recommended Settings:
```nix
monitor = [
  # name, resolution, position, scale
  "eDP-1, 2256x1504@60, 0x0, 1.25" # For Framework 13
  ", preferred, auto, 1"           # Fallback for VM and DL rig
];
```

## 3. Visual Polish (The "Vibes")
Tiling window managers feel "cramped" without gaps and borders.

### Recommended Settings:
```nix
general = {
  gaps_in = 5;
  gaps_out = 10;
  border_size = 2;
  "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
  "col.inactive_border" = "rgba(595959aa)";
  layout = "dwindle";
};

decoration = {
  rounding = 10;
  drop_shadow = "yes";
  shadow_range = 4;
  "col.shadow" = "rgba(1a1a1aee)";
};
```

## 4. Input Tuning
For the Framework, you'll want natural scrolling and tap-to-click.

### Recommended Settings:
```nix
input = {
  touchpad = {
    natural_scroll = "yes";
    tap-to-click = "yes";
  };
  sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
};
```

## 5. Status Bar (Waybar)
You have `waybar` installed, but it needs a configuration file to show your battery (Framework), CPU usage (Threadripper), and Clock.

**Recommendation:** Create a `users/td/waybar/` directory and manage the `config` and `style.css` via `xdg.configFile."waybar"`.
