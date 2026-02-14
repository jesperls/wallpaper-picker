{
  lib,
  stdenvNoCC,
  makeWrapper,
  quickshell,
  hyprland,
  hyprpaper,
  themeEnv ? { },
  wallpaperDir ? null,
}:

stdenvNoCC.mkDerivation {
  pname = "wallpaper-picker";
  version = "0.1.0";
  src = ./..;

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ quickshell ];

  dontBuild = true;

  installPhase =
    let
      runtimeDeps = [
        hyprland
        hyprpaper
      ];
      envFlags = lib.concatStringsSep " " (
        lib.mapAttrsToList (name: value: "--set ${name} \"${value}\"") themeEnv
        ++ lib.optional (wallpaperDir != null) "--set WP_DIR \"${wallpaperDir}\""
      );
    in
    ''
      runHook preInstall

      mkdir -p $out/share/wallpaper-picker
      cp shell.qml $out/share/wallpaper-picker/
      cp WallpaperGrid.qml $out/share/wallpaper-picker/
      cp WallpaperItem.qml $out/share/wallpaper-picker/

      makeWrapper ${quickshell}/bin/qs $out/bin/wallpaper-picker \
        --prefix PATH : "${lib.makeBinPath runtimeDeps}" \
        ${envFlags} \
        --add-flags "-p $out/share/wallpaper-picker"

      runHook postInstall
    '';

  meta = {
    description = "QuickShell GUI wallpaper picker for Hyprland";
    license = lib.licenses.mit;
    mainProgram = "wallpaper-picker";
  };
}
