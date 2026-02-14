import QtQuick

Item {
    id: root

    required property int thumbWidth
    required property int thumbHeight
    required property string filePath
    required property string fileName
    required property bool isSelected
    required property string accentColor
    required property string surfaceColor
    required property string textColor
    required property int rounding
    required property int itemPadding

    signal clicked()

    readonly property string displayName: {
        const idx = fileName.lastIndexOf(".");
        return idx > 0 ? fileName.substring(0, idx) : fileName;
    }

    property bool hovered: false

    readonly property real accentR: parseInt(accentColor.substring(1, 3), 16) / 255
    readonly property real accentG: parseInt(accentColor.substring(3, 5), 16) / 255
    readonly property real accentB: parseInt(accentColor.substring(5, 7), 16) / 255

    Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        radius: root.rounding / 2
        color: root.hovered
            ? Qt.rgba(root.accentR, root.accentG, root.accentB, 0.08)
            : "transparent"
        border.color: root.isSelected
            ? root.accentColor
            : (root.hovered
                ? Qt.rgba(root.accentR, root.accentG, root.accentB, 0.3)
                : "transparent")
        border.width: 2

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Rectangle {
            id: thumbContainer
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: root.itemPadding - 4
            width: root.thumbWidth
            height: root.thumbHeight
            radius: root.rounding / 3
            color: root.surfaceColor
            clip: true

            Image {
                id: thumbImage
                anchors.fill: parent
                source: "file://" + root.filePath
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true
                cache: true
                sourceSize.width: root.thumbWidth * 2
                sourceSize.height: root.thumbHeight * 2
                opacity: status === Image.Ready ? 1 : 0

                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            Text {
                anchors.centerIn: parent
                text: "\uD83D\uDDBC"
                font.pixelSize: 32
                visible: thumbImage.status !== Image.Ready
                opacity: 0.3
            }

            transform: Scale {
                origin.x: thumbContainer.width / 2
                origin.y: thumbContainer.height / 2
                xScale: root.hovered ? 1.03 : 1.0
                yScale: root.hovered ? 1.03 : 1.0

                Behavior on xScale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on yScale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }
        }

        Text {
            anchors.top: thumbContainer.bottom
            anchors.topMargin: 4
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.thumbWidth - 8
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: root.displayName
            color: root.textColor
            font.pixelSize: 12
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.hovered = true
            onExited: root.hovered = false
            onClicked: root.clicked()
        }
    }
}
