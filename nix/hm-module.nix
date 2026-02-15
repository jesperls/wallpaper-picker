self:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;
  cfg = config.programs.wallpaperPicker;

  expandedWallpaperDir =
    if lib.hasPrefix "~" cfg.wallpaperDir
    then "${config.home.homeDirectory}${lib.removePrefix "~" cfg.wallpaperDir}"
    else cfg.wallpaperDir;

  themeEnv = lib.filterAttrs (_: v: v != null) {
    WP_ACCENT = cfg.theme.accent;
    WP_ACCENT2 = cfg.theme.accent2;
    WP_BG = cfg.theme.background;
    WP_SURFACE = cfg.theme.surface;
    WP_SURFACE_ALT = cfg.theme.surfaceAlt;
    WP_TEXT = cfg.theme.text;
    WP_MUTED = cfg.theme.muted;
    WP_BORDER = cfg.theme.border;
    WP_SHADOW = cfg.theme.shadow;
    WP_ROUNDING = toString cfg.theme.rounding;
  };

  pickerPkg = cfg.package.override {
    inherit themeEnv;
    wallpaperDir = expandedWallpaperDir;
  };
in
{
  options.programs.wallpaperPicker = with lib; {
    enable = mkEnableOption "Wallpaper picker and manager for Hyprland";

    package = mkOption {
      type = types.package;
      default = self.packages.${system}.default;
      description = "The wallpaper-picker package to use.";
    };

    wallpaperDir = mkOption {
      type = types.str;
      default = "~/Pictures/Wallpapers";
      description = "Directory containing wallpaper images.";
    };

    theme = {
      accent = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Accent color (hex). Falls back to built-in default if null.";
      };
      accent2 = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Secondary accent color (hex). Falls back to built-in default if null.";
      };
      background = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Background color (hex). Falls back to built-in default if null.";
      };
      surface = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Surface color (hex). Falls back to built-in default if null.";
      };
      surfaceAlt = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Alternate surface color (hex). Falls back to built-in default if null.";
      };
      text = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Text color (hex). Falls back to built-in default if null.";
      };
      muted = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Muted text color (hex). Falls back to built-in default if null.";
      };
      border = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Border color (hex). Falls back to built-in default if null.";
      };
      shadow = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Shadow color (hex). Falls back to built-in default if null.";
      };
      rounding = mkOption {
        type = types.int;
        default = 10;
        description = "Corner rounding in pixels.";
      };
    };

    hyprpaper.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable and configure hyprpaper.";
    };

  };

  config = lib.mkIf cfg.enable {
    services.hyprpaper = lib.mkIf cfg.hyprpaper.enable {
      enable = true;
      settings = {
        ipc = "on";
        splash = false;
      };
    };

    wayland.windowManager.hyprland.settings = lib.mkIf cfg.hyprpaper.enable {
      exec-once = [
        "wallpaper-manager init"
      ];
    };

    home.packages = [ pickerPkg ];
  };
}
