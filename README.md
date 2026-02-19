# wallpaper-picker

A QuickShell-based wallpaper picker and manager for Hyprland. Provides a GUI grid picker and CLI wallpaper cycling, backed by hyprpaper.

## Demo

https://github.com/user-attachments/assets/c2801108-db93-43ce-b630-1e72a7759082

## Features

- Visual grid picker as a Wayland overlay (keyboard and mouse navigation)
- Per-monitor wallpaper cycling
- Wallpaper state persisted across reboots
- Responsive layout that adapts to different monitor sizes and orientations

## Usage

### Home Manager module

Add the flake input and import the module:

```nix
# flake.nix
inputs.wallpaper-picker = {
  url = "github:jesperls/wallpaper-picker";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

```nix
# home-manager config
imports = [ inputs.wallpaper-picker.homeManagerModules.default ];

programs.wallpaperPicker = {
  enable = true;
  wallpaperDir = "~/Pictures/Wallpapers"; # default
  hyprpaper.enable = true;                # default, manages hyprpaper service
  baseColors = {
    accent = "#d47fa6";
    accent2 = "#e3b17a";
    background = "#0f1117";
    surface = "#191b21";
    surfaceAlt = "#13141a";
    text = "#e6e3e8";
    muted = "#b3adb9";
    border = "#2a2d36";
    shadow = "#08090d";
  };
  baseRounding = 10;
};
```

The module handles hyprpaper service and wallpaper restore on login. Configure Hyprland keybinds in your own Hyprland config.

Example Hyprland binds:

```nix
wayland.windowManager.hyprland.settings.bind = [
  "$mainMod SHIFT, W, exec, wallpaper-manager cycle"
  "$mainMod CTRL, W, exec, wallpaper-manager pick"
];
```

### CLI

```
wallpaper-manager cycle            # next wallpaper on focused monitor
wallpaper-manager pick             # open the GUI picker
wallpaper-manager set <output> <path>  # set a specific wallpaper
wallpaper-manager init             # restore wallpapers (runs on login)
```

### Wallpaper directory

Place images (`.png`, `.jpg`, `.jpeg`, `.webp`, `.bmp`) in your wallpaper directory.

For per-monitor wallpapers when cycling, create subdirectories named after your monitor outputs (e.g. `~/Pictures/Wallpapers/HDMI-A-1/`). The picker GUI always shows the top-level directory.

## Theming

All colors are configurable via `programs.wallpaperPicker.theme`. Any unset color (`null`) uses the built-in default from `shell.qml`.

| Option       | Env variable     | Default     |
|--------------|------------------|-------------|
| `accent`     | `WP_ACCENT`      | `#d47fa6`   |
| `accent2`    | `WP_ACCENT2`     | `#e3b17a`   |
| `background` | `WP_BG`          | `#0f1117`   |
| `surface`    | `WP_SURFACE`     | `#191b21`   |
| `surfaceAlt` | `WP_SURFACE_ALT` | `#13141a`   |
| `text`       | `WP_TEXT`        | `#e6e3e8`   |
| `muted`      | `WP_MUTED`       | `#b3adb9`   |
| `border`     | `WP_BORDER`      | `#2a2d36`   |
| `shadow`     | `WP_SHADOW`      | `#08090d`   |
| `rounding`   | `WP_ROUNDING`    | `10`        |

## Dependencies

Managed by the flake — no manual installation needed:

- [QuickShell](https://git.outfoxxed.me/outfoxxed/quickshell) (Qt6/QML shell)
- hyprpaper (wallpaper daemon)
- hyprland (compositor, `hyprctl` IPC)
- jq, coreutils, findutils
