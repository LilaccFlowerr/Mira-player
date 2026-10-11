import QtQuick
// Smooth mouse-wheel scrolling for a Flickable or ListView. Touchpads and touch screens already scroll smoothly,
// so only wheel mice are handled here. Add it as a child of the scrolling item (or of its ScrollView).
Item {
    id: root
    required property Flickable flick
    // Pixels moved per wheel unit (one notch is 120 units).
    property real step: 1.1
    property real goal: 0
    parent: flick; anchors.fill: parent; z: 100
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse
        orientation: Qt.Vertical
        onWheel: event => {
            const f = root.flick
            const low = f.originY - f.topMargin
            const high = Math.max(low, f.originY + f.contentHeight + f.bottomMargin - f.height)
            // Several notches in a row add up to one longer glide instead of restarting from the current position.
            const start = glide.running ? root.goal : f.contentY
            root.goal = Math.max(low, Math.min(high, start - event.angleDelta.y * root.step))
            glide.stop(); glide.from = f.contentY; glide.to = root.goal; glide.start()
        }
    }
    NumberAnimation { id: glide; target: root.flick; property: "contentY"; duration: 280; easing.type: Easing.OutCubic }
    // Dragging, flicking or the scroll bar take over from the glide.
    Connections { target: root.flick; function onMovementStarted() { glide.stop() } }
}
