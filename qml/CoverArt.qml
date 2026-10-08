import QtQuick
Item {
    id: root
    property string source: ""
    property int variant: 0
    property color tint: Theme.container
    implicitWidth: 56; implicitHeight: 56
    Rectangle { anchors.fill: parent; radius: 12; color: root.tint; visible: image.status !== Image.Ready }
    ShapeArt { anchors.centerIn: parent; width: parent.width * 0.65; height: width; variant: root.variant; color: Theme.primary; opacity: 0.7; visible: image.status !== Image.Ready }
    Image { id: image; anchors.fill: parent; source: root.source; fillMode: Image.PreserveAspectFit; asynchronous: true; cache: false }
}
