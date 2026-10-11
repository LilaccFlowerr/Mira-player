import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
// Full-window view of the current track. Opens from the player bar (cover or title, or Ctrl+P); Esc closes it.
Popup {
    id: root
    required property var bar
    signal infoRequested(var track)
    readonly property var track: spotify.playback
    readonly property var restrictions: track.disallows || ({})
    readonly property bool hasTrack: !!track.uri
    property real position: 0
    readonly property bool compactView: width < 600
    // Lyrics replace the cover while the lyrics button is on.
    property bool showLyrics: false
    readonly property bool lyricsActive: showLyrics && prefs.lyrics && hasTrack
    readonly property real coverSize: Math.min(root.height * 0.42, root.width - 64, 420)
    function loadLyrics() {
        if(lyricsActive) lyrics.load(track.uri || "", track.name || "", (track.artists && track.artists.length) ? track.artists[0] : (track.subtitle || ""), track.album || "", track.duration || 0)
    }
    onLyricsActiveChanged: loadLyrics()
    onOpenedChanged: if(!opened) showLyrics = false
    readonly property string trackUri: track.uri || ""
    onTrackUriChanged: loadLyrics()
    parent: Overlay.overlay
    x: 0; y: 0; width: parent ? parent.width : 0; height: parent ? parent.height : 0
    modal: true; focus: true; padding: 0
    closePolicy: Popup.CloseOnEscape
    onOpened: position = spotify.position()
    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
        NumberAnimation { property: "scale"; from: 0.98; to: 1; duration: 260; easing.type: Easing.OutCubic }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 160; easing.type: Easing.InCubic }
    }
    Connections { target: spotify; enabled: root.visible; function onPlaybackChanged() { root.position = spotify.position() } }
    FrameAnimation { running: root.visible && !!root.track.playing; onTriggered: root.position = spotify.position() }
    background: Rectangle {
        id: backdropRoot
        // GraphicsInfo only works on items, so it is read here and not on the popup itself.
        readonly property bool hardware: GraphicsInfo.api !== GraphicsInfo.Software
        readonly property bool fancy: hardware && prefs.fancyPlayer
        color: Theme.base
        clip: true
        // Blurred cover behind everything; a scrim keeps text readable in both themes.
        Image {
            id: backdrop
            anchors.centerIn: parent
            width: Math.max(parent.width, parent.height) * 1.2; height: width
            source: root.track.cover || ""; sourceSize: Qt.size(128, 128)
            fillMode: Image.PreserveAspectCrop; asynchronous: true
            visible: false
        }
        MultiEffect {
            anchors.fill: backdrop; source: backdrop
            visible: backdropRoot.fancy && backdrop.status === Image.Ready
            blurEnabled: true; blur: 1.0; blurMax: 64; saturation: 0.35
            opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 400 } }
        }
        Rectangle { anchors.fill: parent; color: Theme.base; opacity: backdropRoot.fancy && backdrop.status === Image.Ready ? 0.68 : 1 }
        FloatingShapes {
            anchors.fill: parent; visible: backdropRoot.fancy
            running: root.visible && !!root.track.playing
            shapeOpacity: 0.07
        }
    }
    contentItem: Item {
        ActionButton {
            anchors.left: parent.left; anchors.top: parent.top; anchors.margins: 20
            symbol: "down"; tonal: true; hint: "Close (Esc)"; onClicked: root.close()
        }
        ColumnLayout {
            anchors.horizontalCenter: parent.horizontalCenter; anchors.verticalCenter: parent.verticalCenter
            width: Math.min(parent.width - (root.compactView ? 32 : 64), 620)
            spacing: root.compactView ? 14 : 18
            CoverArt {
                visible: !root.lyricsActive
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: root.coverSize; Layout.maximumWidth: root.width - 64; Layout.preferredHeight: Layout.preferredWidth
                source: root.track.cover || ""; variant: 3
            }
            LyricsView {
                visible: root.lyricsActive
                Layout.fillWidth: true; Layout.preferredHeight: Math.max(root.coverSize, 240)
                position: root.position
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 4
                Label { text: root.hasTrack ? root.track.name : "Nothing playing"; color: Theme.text; font.pixelSize: Theme.fs(root.compactView ? 24 : 28); font.bold: true; Layout.fillWidth: true; Layout.minimumWidth: 0; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; textFormat: Text.PlainText }
                Label { text: root.hasTrack ? root.track.subtitle : "Choose a song to start"; color: Theme.muted; font.pixelSize: Theme.fs(16); Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; textFormat: Text.PlainText }
                Label { visible: !!root.track.album; text: root.track.album || ""; color: Theme.muted; font.pixelSize: Theme.fs(12); opacity: 0.8; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; textFormat: Text.PlainText }
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                WavyProgress {
                    id: wave
                    Layout.fillWidth: true; implicitHeight: 28
                    position: root.position; duration: root.track.duration || 0
                    playing: !!root.track.playing
                    seekable: root.bar.available && root.hasTrack && !root.track.restricted && !root.restrictions.seeking
                    onSeekRequested: ms => spotify.seek(Math.round(ms))
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: root.bar.time(wave.shown); color: Theme.muted; font.pixelSize: Theme.fs(11); font.features: ({"tnum": 1}) }
                    Item { Layout.fillWidth: true }
                    Label { text: root.bar.time(root.track.duration || 0); color: Theme.muted; font.pixelSize: Theme.fs(11); font.features: ({"tnum": 1}) }
                }
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter; spacing: root.compactView ? 6 : 14
                ActionButton { symbol: "shuffle"; selected: !!root.track.shuffle; hint: "Shuffle (Ctrl+S)"; enabled: root.bar.available && root.hasTrack && !root.restrictions.toggling_shuffle; onClicked: spotify.setShuffle(!root.track.shuffle) }
                ActionButton { symbol: "previous"; hint: "Previous (Ctrl+←)"; enabled: root.bar.available && !root.track.restricted && !root.restrictions.skipping_prev; onClicked: spotify.command("previous") }
                ActionButton { symbol: root.track.playing ? "pause" : "play"; filled: true; implicitWidth: 76; implicitHeight: 60; hint: root.track.playing ? "Pause (Space)" : "Play (Space)"; enabled: root.bar.available && !root.track.restricted; onClicked: spotify.togglePlayback() }
                ActionButton { symbol: "next"; hint: "Next (Ctrl+→)"; enabled: root.bar.available && !root.track.restricted && !root.restrictions.skipping_next; onClicked: spotify.command("next") }
                ActionButton { symbol: root.track.repeat==="track" ? "repeatOne" : "repeat"; selected: !!root.track.repeat && root.track.repeat!=="off"; hint: "Repeat (Ctrl+R)"; enabled: root.bar.available && root.hasTrack; onClicked: root.bar.cycleRepeat() }
            }
            RowLayout {
                Layout.fillWidth: true; Layout.minimumWidth: 0; spacing: 8
                ActionButton { symbol: (root.track.volume||0)===0 && root.hasTrack ? "mute" : "volume"; compact: true; hint: "Mute (Ctrl+M)"; enabled: root.bar.volumeAvailable; onClicked: root.bar.toggleMute() }
                Slider {
                    id: volume
                    Layout.fillWidth: true; Layout.minimumWidth: 0; from: 0; to: 100; stepSize: 1; wheelEnabled: true
                    value: root.track.volume || 0; enabled: root.bar.volumeAvailable
                    onMoved: commit.restart()
                    Timer { id: commit; interval: 150; onTriggered: spotify.setVolume(Math.round(volume.value)) }
                    Accessible.name: "Volume"
                }
                ActionButton { symbol: "lyrics"; compact: true; visible: prefs.lyrics; selected: root.showLyrics; hint: root.showLyrics ? "Show the cover" : "Show lyrics"; enabled: root.hasTrack; onClicked: root.showLyrics = !root.showLyrics }
                ActionButton { symbol: "info"; compact: true; hint: "About this song"; enabled: root.hasTrack && (root.track.uri || "").startsWith("spotify:track:"); onClicked: { root.close(); root.infoRequested(root.track) } }
                ActionButton { symbol: "plus"; compact: true; hint: "Save to your library"; enabled: root.bar.available && (root.track.uri || "").startsWith("spotify:track:"); onClicked: spotify.save(root.track.uri) }
                ActionButton { symbol: "device"; compact: true; hint: "Devices (Ctrl+D)"; onClicked: { root.close(); root.bar.openDevices() } }
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                visible: root.hasTrack
                text: (root.track.device ? "Playing on " + root.track.device + "  ·  " : "") + "Open in Spotify ↗"
                color: Theme.primary; font.pixelSize: Theme.fs(12); textFormat: Text.PlainText
                TapHandler { onTapped: { if(root.track.url)spotify.openSpotify(root.track.url) } }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }
        }
    }
}
