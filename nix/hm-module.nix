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
in
{
  options.programs.wallpaperPicker = with lib; {
    enable = mkEnableOption "QuickShell wallpaper picker";

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
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (cfg.package.override {
        themeEnv = {
          WP_ACCENT = colors.accent;
          WP_BG = colors.background;
          WP_SURFACE = colors.surface;
          WP_TEXT = colors.text;
          WP_MUTED = colors.muted;
          WP_BORDER = colors.border;
          WP_ROUNDING = toString rounding;
        };
        wallpaperDir = cfg.wallpaperDir;
      })
    ];
  };
}
