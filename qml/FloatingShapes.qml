import QtQuick
// Soft shapes that drift and turn slowly behind other content. They only move while running is true.
Item {
    id: root
    property bool running: true
    property color color: Theme.primary
    property real shapeOpacity: 0.1
    clip: true
    Repeater {
        model: [
            {v: 0, size: 0.26, x: 0.05, y: 0.14, dx: 0.06, dy: 0.08, drift: 38000, spin: 140000},
            {v: 3, size: 0.22, x: 0.76, y: 0.62, dx: -0.07, dy: -0.07, drift: 44000, spin: -160000}
        ]
        delegate: ShapeArt {
            id: shape
            required property var modelData
            property real phase: 0
            width: Math.min(root.width, root.height) * modelData.size; height: width
            x: root.width * (modelData.x + modelData.dx * phase); y: root.height * (modelData.y + modelData.dy * phase)
            variant: modelData.v; color: root.color; opacity: root.shapeOpacity
            SequentialAnimation on phase {
                running: root.running && root.visible; loops: Animation.Infinite
                NumberAnimation { to: 1; duration: shape.modelData.drift; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0; duration: shape.modelData.drift; easing.type: Easing.InOutSine }
            }
            RotationAnimation on turn { running: root.running && root.visible; loops: Animation.Infinite; from: 0; to: shape.modelData.spin > 0 ? 360 : -360; duration: Math.abs(shape.modelData.spin) }
        }
    }
}
