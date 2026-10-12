import QtQuick
// Album cover that fades into the next one when the song changes.
Item {
    id: root
    property string source: ""
    property int variant: 3
    property real radius: Math.round(width * 0.107 * Theme.cornerScale)
    // Two layers: the visible one fades out while the other fades in with the new cover.
    property bool useA: true
    property string shown: ""
    onSourceChanged: {
        if(source === shown) return
        shown = source
        const incoming = useA ? coverB : coverA
        incoming.source = source
        useA = !useA
    }
    Component.onCompleted: { coverA.source = source; shown = source }
    CoverArt { id: coverA; anchors.fill: parent; variant: root.variant; radius: root.radius; opacity: root.useA ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 300 } } }
    CoverArt { id: coverB; anchors.fill: parent; variant: root.variant; radius: root.radius; opacity: root.useA ? 0 : 1; Behavior on opacity { NumberAnimation { duration: 300 } } }
}
