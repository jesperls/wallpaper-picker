import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ShellRoot {
    id: root

    // Theme colors from environment (injected by Nix wrapper)
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
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        // Semi-transparent backdrop
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.5)

            MouseArea {
                anchors.fill: parent
                onClicked: Qt.quit()
            }
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

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 0
                spacing: 0

                // Search bar
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    color: "transparent"

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 10
                        anchors.bottomMargin: 4
                        radius: root.rounding / 2
                        color: root.surfaceColor

                        TextInput {
                            id: searchInput
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            verticalAlignment: TextInput.AlignVCenter
                            color: root.textColor
                            font.pixelSize: 14
                            font.family: "Noto Sans"
                            clip: true
                            focus: true

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "Search wallpapers…"
                                color: root.mutedColor
                                font: searchInput.font
                                visible: !searchInput.text && !searchInput.activeFocus
                            }
                        }
                    }
                }

                // Wallpaper grid
                WallpaperGrid {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 6
                    searchText: searchInput.text
                    wallpaperDir: root.wallpaperDir
                    bgColor: root.bgColor
                    surfaceColor: root.surfaceColor
                    accentColor: root.accentColor
                    textColor: root.textColor
                    mutedColor: root.mutedColor
                    borderColor: root.borderColor
                    rounding: root.rounding
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
