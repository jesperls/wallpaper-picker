pragma ComponentBehavior: Bound

import Quickshell.Io
import QtQuick
import QtQuick.Controls
import Qt.labs.folderlistmodel

GridView {
    id: gridView

    required property string wallpaperDir
    required property string focusedMonitor
    required property string accentColor
    required property string surfaceColor
    required property string textColor
    required property string mutedColor
    required property int rounding

    readonly property int thumbWidth: 280
    readonly property int thumbHeight: 160
    readonly property int itemPadding: 12

    readonly property int baseItemWidth: thumbWidth + itemPadding * 2
    readonly property int columns: Math.max(1, Math.floor(width / baseItemWidth))

    cellWidth: width / columns
    cellHeight: thumbHeight + 30 + itemPadding * 2
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    model: FolderListModel {
        folder: "file://" + gridView.wallpaperDir
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp"]
        showDirs: false
        showDotAndDotDot: false
        sortField: FolderListModel.Name
    }

    delegate: WallpaperItem {
        required property int index
        required property var model

        width: gridView.cellWidth
        height: gridView.cellHeight
        thumbWidth: gridView.thumbWidth
        thumbHeight: gridView.thumbHeight
        filePath: gridView.wallpaperDir + "/" + model.fileName
        fileName: model.fileName
        isSelected: gridView.currentIndex === index
        accentColor: gridView.accentColor
        surfaceColor: gridView.surfaceColor
        textColor: gridView.textColor
        rounding: gridView.rounding
        itemPadding: gridView.itemPadding

        onClicked: {
            gridView.currentIndex = index;
            let mon = gridView.focusedMonitor;
            if (!mon) return;
            setProc.command = ["wallpaper-manager", "set", mon, filePath];
            setProc.running = true;
        }
    }

    Process {
        id: setProc
        onExited: () => { Qt.quit(); }
    }

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        contentItem: Rectangle {
            implicitWidth: 6
            radius: 3
            color: gridView.mutedColor
            opacity: 0.4
        }
    }

    Keys.onEscapePressed: Qt.quit()
    Keys.onUpPressed: moveCurrentIndexUp()
    Keys.onDownPressed: moveCurrentIndexDown()
    Keys.onLeftPressed: moveCurrentIndexLeft()
    Keys.onRightPressed: moveCurrentIndexRight()
    Keys.onReturnPressed: { if (currentItem) currentItem.clicked(); }
}
