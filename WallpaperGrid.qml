pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import Qt.labs.folderlistmodel

GridView {
    id: gridView

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

    // Use FolderListModel directly since we don't need filtering anymore
    model: FolderListModel {
        id: folderModel
        folder: "file://" + gridView.wallpaperDir
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp"]
        showDirs: false
        showDotAndDotDot: false
        sortField: FolderListModel.Name
    }

    delegate: WallpaperItem {
        required property int index
        required property var model
        width: gridView.totalItemWidth
        height: gridView.totalItemHeight
        thumbWidth: gridView.thumbWidth
        thumbHeight: gridView.thumbHeight
        
        // FolderListModel provides these roles directly
        filePath: {
             // FolderListModel usually returns file URL in filePath role or fileURL role depending on Qt version
             // Let's safe-guard. If model.fileURL exists, use it.
             let url = model.fileURL || ("file://" + gridView.wallpaperDir + "/" + model.fileName);
             return url.toString().replace(/^file:\/\//, "");
        }
        fileUrl: model.fileURL ? model.fileURL.toString() : ("file://" + gridView.wallpaperDir + "/" + model.fileName)
        fileName: model.fileName
        
        isSelected: gridView.currentIndex === index
        accentColor: gridView.accentColor
        surfaceColor: gridView.surfaceColor
        textColor: gridView.textColor
        rounding: gridView.rounding
        itemPadding: gridView.itemPadding

        onClicked: {
            gridView.currentIndex = index;
            
            // Gather all screen names
            let monitors = [];
            for (let i = 0; i < Quickshell.screens.length; i++) {
                monitors.push(Quickshell.screens[i].name);
            }
            
            console.log("Setting wallpaper for monitors:", monitors.join(", "));
            console.log("Image:", filePath);

            // Construct shell command chain
            // 1. Preload
            // 2. Set for each monitor
            // 3. Unload unused
            // 4. Quit
            
            let cmds = [`hyprctl hyprpaper preload "${filePath}"`];
            
            monitors.forEach(mon => {
                cmds.push(`hyprctl hyprpaper wallpaper "${mon},${filePath}"`);
            });
            
            // Unload unused is safe to run after setting
            cmds.push("hyprctl hyprpaper unload unused");
            
            // Run all in sh, use ; to ignore potential preload errors (e.g. already loaded)
            const fullCmd = cmds.join("; ");
            
            // Use Process to run the chain
            wallpaperProc.command = ["sh", "-c", fullCmd];
            wallpaperProc.running = true;
        }
    }

    Process {
        id: wallpaperProc
        onExited: (exitCode, exitStatus) => {
            console.log("Wallpaper set finished with code:", exitCode);
            if (exitCode === 0) Qt.quit();
             // Even if non-zero, we might want to quit if it was just a preload error, but let's keep it open or quit?
             // Actually, if it worked partially, we likely want to quit.
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
    Keys.onEscapePressed: Qt.quit()
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
