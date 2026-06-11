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
    if lib.hasPrefix "~" cfg.wallpaperDir then
      "${config.home.homeDirectory}${lib.removePrefix "~" cfg.wallpaperDir}"
    else
      cfg.wallpaperDir;

  themeEnv = lib.filterAttrs (_: v: v != null) {
    WP_ACCENT = cfg.baseColors.accent or null;
    WP_ACCENT2 = cfg.baseColors.accent2 or null;
    WP_BG = cfg.baseColors.background or null;
    WP_SURFACE = cfg.baseColors.surface or null;
    WP_SURFACE_ALT = cfg.baseColors.surfaceAlt or null;
    WP_TEXT = cfg.baseColors.text or null;
    WP_MUTED = cfg.baseColors.muted or null;
    WP_BORDER = cfg.baseColors.border or null;
    WP_SHADOW = cfg.baseColors.shadow or null;
    WP_ROUNDING = toString cfg.baseRounding;
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

    baseColors = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Base theme colors attrset (accent, accent2, background, surface, surfaceAlt, text, muted, border, shadow). Missing colors fall back to built-in defaults.";
    };

    baseRounding = mkOption {
      type = types.int;
      default = 10;
      description = "Corner rounding in pixels.";
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
      on = [
        {
          _args = [
            "hyprland.start"
            (lib.generators.mkLuaInline ''
              function()
                hl.exec_cmd("wallpaper-manager init")
              end
            '')
          ];
        }
      ];
    };

    home.packages = [ pickerPkg ];
  };
}
