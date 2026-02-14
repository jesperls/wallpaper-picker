pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import Qt.labs.folderlistmodel

GridView {
    id: gridView

    required property string searchText
    required property string wallpaperDir
    required property string bgColor
    required property string surfaceColor
    required property string accentColor
    required property string textColor
    required property string mutedColor
    required property string borderColor
    required property int rounding

    readonly property int thumbWidth: 280
    readonly property int thumbHeight: 160
    readonly property int itemPadding: 12
    readonly property int totalItemWidth: thumbWidth + itemPadding * 2
    readonly property int totalItemHeight: thumbHeight + 30 + itemPadding * 2

    cellWidth: totalItemWidth
    cellHeight: totalItemHeight

    clip: true
    boundsBehavior: Flickable.StopAtBounds

    // Use FolderListModel to scan for image files
    FolderListModel {
        id: folderModel

        folder: "file://" + gridView.wallpaperDir
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp"]
        showDirs: false
        showDotAndDotDot: false
        sortField: FolderListModel.Name
    }

    // Filtered model based on search
    model: filteredModel

    ListModel {
        id: filteredModel
    }

    // Re-filter when search text or source model changes
    onSearchTextChanged: filterModel()
    Connections {
        target: folderModel
        function onCountChanged() { gridView.filterModel() }
    }

    function filterModel(): void {
        filteredModel.clear();
        const query = searchText.toLowerCase();
        for (let i = 0; i < folderModel.count; i++) {
            const name = folderModel.get(i, "fileName");
            const url = folderModel.get(i, "fileURL").toString();
            // Convert file:// URL to absolute path for hyprpaper
            const path = url.replace(/^file:\/\//, "");
            if (!query || name.toLowerCase().includes(query)) {
                filteredModel.append({ fileName: name, filePath: path, fileUrl: url });
            }
        }
    }

    // Initial population when folder loads
    Component.onCompleted: {
        Qt.callLater(filterModel);
    }

    delegate: WallpaperItem {
        required property int index
        required property var model

        width: gridView.totalItemWidth
        height: gridView.totalItemHeight
        thumbWidth: gridView.thumbWidth
        thumbHeight: gridView.thumbHeight
        filePath: model.filePath ?? ""
        fileUrl: model.fileUrl ?? ""
        fileName: model.fileName ?? ""
        isSelected: gridView.currentIndex === index
        accentColor: gridView.accentColor
        surfaceColor: gridView.surfaceColor
        textColor: gridView.textColor
        rounding: gridView.rounding
        itemPadding: gridView.itemPadding

        onClicked: {
            gridView.currentIndex = index;
            preloadProc.command = ["hyprctl", "hyprpaper", "preload", filePath];
            setWallpaperProc.command = ["hyprctl", "hyprpaper", "wallpaper", "," + filePath];
            preloadProc.running = true;
        }
    }

    // Hyprpaper IPC processes — chain: preload → set wallpaper → unload unused → quit
    Process {
        id: preloadProc
        onExited: (exitCode, exitStatus) => {
            setWallpaperProc.running = true;
        }
    }

    Process {
        id: setWallpaperProc
        onExited: (exitCode, exitStatus) => {
            unloadProc.running = true;
        }
    }

    Process {
        id: unloadProc
        command: ["hyprctl", "hyprpaper", "unload", "unused"]
        onExited: (exitCode, exitStatus) => {
            Qt.quit();
        }
    }

    // Scroll bar
    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        contentItem: Rectangle {
            implicitWidth: 6
            radius: 3
            color: gridView.mutedColor
            opacity: 0.4
        }
    }

    // Keyboard navigation
    Keys.onUpPressed: moveCurrentIndexUp()
    Keys.onDownPressed: moveCurrentIndexDown()
    Keys.onLeftPressed: moveCurrentIndexLeft()
    Keys.onRightPressed: moveCurrentIndexRight()
    Keys.onReturnPressed: {
        if (currentItem) {
            currentItem.clicked();
        }
    }
}
