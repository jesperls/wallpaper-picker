{
  lib,
  stdenvNoCC,
  makeWrapper,
  quickshell,
  jq,
  coreutils,
  findutils,
  bash,
  themeEnv ? { },
  wallpaperDir ? null,
}:

stdenvNoCC.mkDerivation {
  pname = "wallpaper-picker";
  version = "0.1.0";
  src = ./..;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase =
    let
      # hyprctl is intentionally not bundled: it must match the running
      # compositor, and the session always has it on PATH.
      runtimeDeps = [
        jq
        coreutils
        findutils
        bash
      ];
      envFlags = lib.concatStringsSep " " (
        lib.mapAttrsToList (name: value: "--set ${name} \"${value}\"") themeEnv
        ++ lib.optional (wallpaperDir != null) "--set WP_DIR \"${wallpaperDir}\""
      );
    in
    ''
      runHook preInstall

      mkdir -p $out/share/wallpaper-picker $out/bin

      cp shell.qml WallpaperGrid.qml WallpaperItem.qml $out/share/wallpaper-picker/

      makeWrapper ${quickshell}/bin/qs $out/bin/wallpaper-picker \
        --prefix PATH : "$out/bin:${lib.makeBinPath runtimeDeps}" \
        ${envFlags} \
        --add-flags "-p $out/share/wallpaper-picker"

      install -Dm755 wallpaper-manager.sh $out/bin/wallpaper-manager
      wrapProgram $out/bin/wallpaper-manager \
        --prefix PATH : "$out/bin:${lib.makeBinPath runtimeDeps}" \
        ${envFlags}

      runHook postInstall
    '';

  meta = {
    description = "Wallpaper picker and manager for Hyprland";
    license = lib.licenses.mit;
    mainProgram = "wallpaper-manager";
  };
}
