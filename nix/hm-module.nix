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

  # Build the picker package with theme colors baked in
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
    wallpaperDir = cfg.wallpaperDir;
  };

  # Wallpaper manager script — uses the picker for 'pick' and hyprpaper for everything else
  wallpaperManager = pkgs.writeShellApplication {
    name = "wallpaper-manager";
    runtimeInputs = with pkgs; [
      hyprpaper
      hyprland
      jq
      findutils
      coreutils
      pickerPkg
    ];
    text = builtins.readFile "${self}/wallpaper-manager.sh";
  };
in
{
  options.programs.wallpaperPicker = with lib; {
    enable = mkEnableOption "QuickShell wallpaper picker with wallpaper management";

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

    keybinds.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to add wallpaper keybinds to Hyprland.";
    };

    keybinds.cycle = mkOption {
      type = types.str;
      default = "$mainMod SHIFT, W";
      description = "Keybind for cycling wallpapers.";
    };

    keybinds.pick = mkOption {
      type = types.str;
      default = "$mainMod CTRL, W";
      description = "Keybind for opening the wallpaper picker.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Hyprpaper service
    services.hyprpaper = lib.mkIf cfg.hyprpaper.enable {
      enable = true;
      settings = {
        ipc = "on";
        splash = false;
      };
    };

    # Hyprland keybinds
    wayland.windowManager.hyprland.settings.bind = lib.mkIf cfg.keybinds.enable [
      "${cfg.keybinds.cycle}, exec, wallpaper-manager"
      "${cfg.keybinds.pick}, exec, wallpaper-manager pick"
    ];

    # Hyprland exec-once for wallpaper restore on login
    wayland.windowManager.hyprland.settings.exec-once = lib.mkIf cfg.hyprpaper.enable [
      "wallpaper-manager init"
    ];

    # Packages
    home.packages = [
      wallpaperManager
      pickerPkg
    ];
  };
}
