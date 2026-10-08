import QtQuick
import M3Shapes
// Material 3 Expressive loading indicator: one shape that keeps morphing into the next.
// Adapted from LoadingIndicator.qml in LilaccFlowerr's Nebula shell (MIT).
Item {
    id: root

    property bool running: false
    // Wait a moment before appearing so quick loads do not flash the indicator.
    property int delay: 150
    property bool shown: false
    property bool contained: true
    property int interval: 500
    property color color: Theme.primary
    property color containerColor: Theme.container
    property int index: 0

    readonly property var shapes: [
        MaterialShape.Circle,
        MaterialShape.Square,
        MaterialShape.SemiCircle,
        MaterialShape.Oval,
        MaterialShape.Pill,
        MaterialShape.Triangle,
        MaterialShape.Diamond,
        MaterialShape.Pentagon,
        MaterialShape.Gem,
        MaterialShape.Sunny,
        MaterialShape.VerySunny,
        MaterialShape.Cookie4Sided,
        MaterialShape.Cookie6Sided,
        MaterialShape.Clover4Leaf,
        MaterialShape.SoftBurst,
        MaterialShape.Flower,
        MaterialShape.Puffy
    ]

    implicitWidth: 48
    implicitHeight: 48
    visible: opacity > 0
    opacity: shown ? 1 : 0

    Behavior on opacity {
        NumberAnimation { duration: 150 }
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.containerColor
        visible: root.contained
    }

    MaterialShape {
        anchors.centerIn: parent
        width: parent.width / 2
        height: parent.height / 2
        visible: GraphicsInfo.api !== GraphicsInfo.Software
        shape: root.shapes[root.index]
        color: root.color
        animationDuration: 300
        animationEasing.type: Easing.BezierSpline
        animationEasing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1]
    }

    // Software rendering cannot draw MaterialShape; cycle the Canvas shapes instead.
    ShapeArt {
        anchors.centerIn: parent
        width: parent.width / 2
        height: parent.height / 2
        visible: GraphicsInfo.api === GraphicsInfo.Software
        variant: root.index % 4
        color: root.color
        turn: root.index * 45
        Behavior on turn { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    }

    onRunningChanged: if (!running) shown = false

    Timer {
        interval: root.delay
        running: root.running && !root.shown
        onTriggered: root.shown = true
    }

    Timer {
        interval: root.interval
        repeat: true
        triggeredOnStart: true
        running: root.shown
        onTriggered: root.index = (root.index + 1) % root.shapes.length
    }

    Accessible.role: Accessible.ProgressBar
    Accessible.name: "Loading"
}
