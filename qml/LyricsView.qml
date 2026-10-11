import QtQuick
import QtQuick.Controls
// Lyrics of the playing song: synced lines follow the music (click one to jump there), otherwise plain text.
Item {
    id: view
    property real position: 0
    readonly property string state: lyrics.state
    readonly property bool synced: lyrics.synced.length > 0
    readonly property int current: synced ? lyrics.lineAt(position) : -1
    // Follow the song smoothly, but leave the list alone for a few seconds after the user scrolled it.
    function follow() {
        if(!synced || current < 0 || userScroll.running || list.moving) return
        const item = list.itemAtIndex(current)
        if(!item) { list.positionViewAtIndex(current, ListView.Center); return }
        glide.stop()
        glide.to = Math.max(list.originY - list.topMargin, Math.min(item.y + item.height / 2 - list.height / 2, list.originY + list.contentHeight + list.bottomMargin - list.height))
        glide.from = list.contentY
        glide.start()
    }
    onCurrentChanged: follow()
    Timer { id: userScroll; interval: 4000 }
    Label {
        anchors.centerIn: parent; width: parent.width - 32; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
        visible: view.state !== "found"; color: Theme.muted; textFormat: Text.PlainText
        text: view.state === "loading" ? "Loading lyrics…" : view.state === "notfound" ? "No lyrics found for this song." : view.state === "failed" ? "Could not reach the lyrics service. Check your connection." : ""
    }
    ListView {
        id: list
        anchors.fill: parent; clip: true; visible: view.state === "found" && view.synced
        model: view.synced ? lyrics.synced : []
        spacing: 4; topMargin: height / 2 - 20; bottomMargin: height / 2
        boundsBehavior: Flickable.StopAtBounds; flickDeceleration: 2500; maximumFlickVelocity: 3500
        NumberAnimation { id: glide; target: list; property: "contentY"; duration: 450; easing.type: Easing.OutCubic }
        onMovementStarted: { glide.stop(); userScroll.restart() }
        onMovementEnded: userScroll.restart()
        SmoothScroll { flick: list; onGoalChanged: { glide.stop(); userScroll.restart() } }
        ScrollBar.vertical: ScrollBar {}
        delegate: ItemDelegate {
            required property var modelData
            required property int index
            readonly property bool active: index === view.current
            width: ListView.view.width; padding: 8
            background: Rectangle { radius: Theme.r(12); color: parent.hovered ? Theme.elevated : "transparent"; opacity: 0.8 }
            contentItem: Label {
                text: modelData.text.length ? modelData.text : "♪"; textFormat: Text.PlainText; wrapMode: Text.WordWrap
                font.pixelSize: Theme.fs(active ? 24 : 21); font.bold: true
                color: active ? Theme.text : Theme.muted; opacity: active ? 1 : 0.7
                horizontalAlignment: Text.AlignHCenter
                Behavior on color { ColorAnimation { duration: 180 } }
                Behavior on opacity { NumberAnimation { duration: 180 } }
            }
            onClicked: spotify.seek(modelData.time)
            Accessible.name: modelData.text
        }
    }
    Flickable {
        id: plainFlick
        anchors.fill: parent; clip: true; visible: view.state === "found" && !view.synced
        contentWidth: width; contentHeight: plain.implicitHeight + 24; boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}
        SmoothScroll { flick: plainFlick }
        Label { id: plain; width: parent.width - 16; x: 8; y: 12; text: lyrics.plain; textFormat: Text.PlainText; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter; color: Theme.text; font.pixelSize: Theme.fs(18); lineHeight: 1.3 }
    }
}
