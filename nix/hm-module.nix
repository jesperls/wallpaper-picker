self:
{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;
  cfg = config.programs.wallpaperPicker;
  colors = osConfig.mySystem.theme.colors;
  rounding = osConfig.mySystem.theme.rounding;

  expandedWallpaperDir =
    if lib.hasPrefix "~" cfg.wallpaperDir
    then "${config.home.homeDirectory}${lib.removePrefix "~" cfg.wallpaperDir}"
    else cfg.wallpaperDir;

  pickerPkg = cfg.package.override {
    themeEnv = {
      WP_ACCENT = colors.accent;
      WP_BG = colors.background;
      WP_SURFACE = colors.surface;
      WP_TEXT = colors.text;
      WP_MUTED = colors.muted;
      WP_BORDER = colors.border;
      WP_ROUNDING = toString rounding;
    };
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

    hyprpaper.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable and configure hyprpaper.";
    };

    keybinds = {
      enable = mkEnableOption "wallpaper keybinds in Hyprland" // { default = true; };

      cycle = mkOption {
        type = types.str;
        default = "$mainMod SHIFT, W";
        description = "Keybind for cycling wallpapers.";
      };

      pick = mkOption {
        type = types.str;
        default = "$mainMod CTRL, W";
        description = "Keybind for opening the wallpaper picker.";
      };
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

    wayland.windowManager.hyprland.settings = lib.mkIf cfg.keybinds.enable {
      bind = [
        "${cfg.keybinds.cycle}, exec, wallpaper-manager cycle"
        "${cfg.keybinds.pick}, exec, wallpaper-manager pick"
      ];
      exec-once = lib.mkIf cfg.hyprpaper.enable [
        "wallpaper-manager init"
      ];
    };

    home.packages = [ pickerPkg ];
  };
}
