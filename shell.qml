import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

ShellRoot {
    id: root

    readonly property string bgColor: Quickshell.env("WP_BG") || "#0f1117"
    readonly property string surfaceColor: Quickshell.env("WP_SURFACE") || "#191b21"
    readonly property string surfaceAltColor: Quickshell.env("WP_SURFACE_ALT") || "#13141a"
    readonly property string accentColor: Quickshell.env("WP_ACCENT") || "#d47fa6"
    readonly property string accent2Color: Quickshell.env("WP_ACCENT2") || "#e3b17a"
    readonly property string textColor: Quickshell.env("WP_TEXT") || "#e6e3e8"
    readonly property string mutedColor: Quickshell.env("WP_MUTED") || "#b3adb9"
    readonly property string borderColor: Quickshell.env("WP_BORDER") || "#2a2d36"
    readonly property string shadowColor: Quickshell.env("WP_SHADOW") || "#08090d"
    readonly property int rounding: parseInt(Quickshell.env("WP_ROUNDING") || "10")
    readonly property string wallpaperDir: {
        let dir = Quickshell.env("WP_DIR") || (Quickshell.env("HOME") + "/Pictures/Wallpapers");
        return dir.replace(/^~/, Quickshell.env("HOME"));
    }

    readonly property string focusedMonitor: Quickshell.env("WP_MONITOR") || (Hyprland.focusedMonitor?.name ?? "")

    PanelWindow {
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        aboveWindows: true
        focusable: true
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "wallpaper-picker"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        MouseArea {
            anchors.fill: parent
            onClicked: Qt.quit()
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.85, 1400)
            height: Math.min(parent.height * 0.85, 900)
            radius: root.rounding
            color: root.bgColor
            border.color: root.borderColor
            border.width: 1
            clip: true

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
            }

            WallpaperGrid {
                anchors.fill: parent
                anchors.margins: 6
                wallpaperDir: root.wallpaperDir
                focusedMonitor: root.focusedMonitor
                accentColor: root.accentColor
                surfaceColor: root.surfaceColor
                textColor: root.textColor
                mutedColor: root.mutedColor
                rounding: root.rounding
                focus: true
            }
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) Qt.quit();
        }
    }
}
