import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ShellRoot {
    id: root

    // Theme colors
    readonly property string bgColor: Quickshell.env("WP_BG") || "#0f1117"
    readonly property string surfaceColor: Quickshell.env("WP_SURFACE") || "#191b21"
    readonly property string accentColor: Quickshell.env("WP_ACCENT") || "#d47fa6"
    readonly property string textColor: Quickshell.env("WP_TEXT") || "#e6e3e8"
    readonly property string mutedColor: Quickshell.env("WP_MUTED") || "#b3adb9"
    readonly property string borderColor: Quickshell.env("WP_BORDER") || "#2a2d36"
    readonly property int rounding: parseInt(Quickshell.env("WP_ROUNDING") || "10")
    readonly property string wallpaperDir: {
        let dir = Quickshell.env("WP_DIR") || (Quickshell.env("HOME") + "/Pictures/Wallpapers");
        return dir.replace(/^~/, Quickshell.env("HOME"));
    }

    PanelWindow {
        id: pickerWindow

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        exclusionMode: ExclusionMode.Ignore
        aboveWindows: true
        focusable: true
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "wallpaper-picker"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive // Exclusive focus to capture Escape

        // Click outside to close (transparent background, no dimming)
        MouseArea {
            anchors.fill: parent
            onClicked: Qt.quit()
        }

        // Center the picker dialog
        Rectangle {
            id: dialog
            anchors.centerIn: parent
            width: 1100
            height: 700
            radius: root.rounding
            color: root.bgColor
            border.color: root.borderColor
            border.width: 1
            clip: true

            // Prevent clicks on the dialog from closing the window
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {} // Swallow clicks
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 0
                spacing: 0

                // Header / Debug info
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    color: "transparent"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Scanning: " + root.wallpaperDir
                        color: root.mutedColor
                        font.pixelSize: 12
                    }
                }

                // Wallpaper grid
                WallpaperGrid {
                    id: grid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 6
                    wallpaperDir: root.wallpaperDir
                    bgColor: root.bgColor
                    surfaceColor: root.surfaceColor
                    accentColor: root.accentColor
                    textColor: root.textColor
                    mutedColor: root.mutedColor
                    borderColor: root.borderColor
                    rounding: root.rounding
                    focus: true // Give grid focus for keyboard nav
                }
            }
        }

        // Keyboard handling
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                Qt.quit();
            }
        }
    }
}
