import QtQuick
import QtQuick.Effects
Item {
    id: root
    property string source: ""
    property int variant: 0
    property color tint: Theme.container
    property real radius: Math.max(6, Math.min(width, height) * 0.12)
    readonly property bool ready: image.status === Image.Ready
    readonly property bool hardware: GraphicsInfo.api !== GraphicsInfo.Software
    implicitWidth: 56; implicitHeight: 56
    Rectangle { anchors.fill: parent; radius: root.radius; color: root.tint; visible: !root.ready }
    ShapeArt { anchors.centerIn: parent; width: parent.width * 0.65; height: width; variant: root.variant; color: Theme.primary; opacity: 0.7; visible: !root.ready }
    Image {
        id: image
        anchors.fill: parent; source: root.source
        fillMode: Image.PreserveAspectCrop; asynchronous: true
        // Decode at the size it is shown (rounded up to steps of 64 px) instead of Spotify's full 640 px art.
        sourceSize: Qt.size(Math.ceil(Math.max(64, root.width * 2) / 64) * 64, Math.ceil(Math.max(64, root.height * 2) / 64) * 64)
        // With GPU rendering the rounded copy below is shown instead.
        visible: root.ready && !root.hardware
        opacity: root.ready ? 1 : 0
    }
    MultiEffect {
        anchors.fill: image; source: image
        visible: root.ready && root.hardware
        maskEnabled: true; maskSource: mask
        maskThresholdMin: 0.5; maskSpreadAtMin: 1.0
        opacity: root.ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180 } }
    }
    Item {
        id: mask
        anchors.fill: parent; visible: false; layer.enabled: root.hardware; layer.smooth: true
        Rectangle { anchors.fill: parent; radius: root.radius; color: "black" }
    }
}
