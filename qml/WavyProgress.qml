import QtQuick
// Material 3 Expressive wavy progress: the played part waves while music plays and settles
// into a flat line when paused. Click, drag or use the arrow keys to seek.
Item {
    id: root
    property real position: 0
    property real duration: 0
    property bool playing: false
    property bool seekable: false
    property color color: Theme.primary
    property color trackColor: Theme.outline
    signal seekRequested(real ms)
    readonly property bool dragging: area.pressed
    readonly property real shown: dragging ? dragValue : position
    property real dragValue: 0
    property real phase: 0
    property real amplitude: playing ? 3 : 0
    readonly property bool showThumb: seekable && (area.containsMouse || dragging || activeFocus)
    readonly property real fraction: duration > 0 ? Math.max(0, Math.min(1, shown / duration)) : 0
    implicitHeight: 24
    activeFocusOnTab: seekable
    Behavior on amplitude { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
    onFractionChanged: canvas.requestPaint()
    onAmplitudeChanged: canvas.requestPaint()
    onPhaseChanged: canvas.requestPaint()
    onShowThumbChanged: canvas.requestPaint()
    onColorChanged: canvas.requestPaint()
    onTrackColorChanged: canvas.requestPaint()
    FrameAnimation {
        running: root.amplitude > 0 && root.visible
        onTriggered: root.phase = (root.phase + frameTime * 4.2) % (Math.PI * 2)
    }
    Canvas {
        id: canvas
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const c = getContext("2d"); c.reset()
            const stroke = 4, cap = stroke / 2, mid = height / 2, wavelength = 34
            const start = cap, end = width - cap
            const head = start + (end - start) * root.fraction
            const gap = root.showThumb ? 7 : 8
            c.lineWidth = stroke; c.lineCap = "round"; c.lineJoin = "round"
            const activeEnd = head - (root.showThumb ? gap : 0)
            if (activeEnd > start + 0.5) {
                c.strokeStyle = root.color; c.beginPath()
                for (let x = start; x <= activeEnd; x += 1) {
                    // Taper into the head so the wave meets the thumb or the flat track smoothly.
                    const taper = Math.min(1, (activeEnd - x) / 12)
                    const y = mid + root.amplitude * taper * Math.sin(2 * Math.PI * x / wavelength - root.phase)
                    if (x === start) c.moveTo(x, y); else c.lineTo(x, y)
                }
                c.lineTo(activeEnd, mid); c.stroke()
            }
            const restStart = head + gap + (root.fraction > 0 ? 0 : -gap)
            if (restStart < end) {
                c.strokeStyle = root.trackColor; c.beginPath(); c.moveTo(restStart, mid); c.lineTo(end, mid); c.stroke()
                // Stop indicator at the end of the track.
                c.fillStyle = root.color; c.beginPath(); c.arc(end, mid, 2, 0, Math.PI * 2); c.fill()
            }
            if (root.showThumb) {
                c.fillStyle = root.color; c.beginPath(); c.roundedRect(head - 2, mid - 9, 4, 18, 2, 2); c.fill()
            }
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent; anchors.topMargin: -6; anchors.bottomMargin: -6
        enabled: root.seekable; hoverEnabled: true
        cursorShape: root.seekable ? Qt.PointingHandCursor : Qt.ArrowCursor
        function valueAt(x) { return Math.max(0, Math.min(1, (x - 2) / Math.max(1, width - 4))) * root.duration }
        onPressed: mouse => root.dragValue = valueAt(mouse.x)
        onPositionChanged: mouse => { if (pressed) root.dragValue = valueAt(mouse.x) }
        onReleased: mouse => root.seekRequested(valueAt(mouse.x))
    }
    Keys.onLeftPressed: root.seekRequested(Math.max(0, root.position - 5000))
    Keys.onRightPressed: root.seekRequested(Math.min(root.duration, root.position + 5000))
    Accessible.role: Accessible.Slider
    Accessible.name: "Playback position"
}
