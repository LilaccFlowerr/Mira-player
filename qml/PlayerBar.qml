import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
Rectangle {
    id: root
    signal configure()
    radius: 28; color: Theme.elevated
    implicitHeight: 112
    readonly property var track: spotify.playback
    readonly property var restrictions: track.disallows || ({})
    readonly property bool available: auth.connected && !!spotify.deviceId
    readonly property bool hasTrack: !!track.uri
    readonly property bool volumeAvailable: available && spotify.devices.some(d=>d.id===spotify.deviceId && d.supportsVolume)
    property real position: 0
    property int volumeBeforeMute: 50
    function time(ms) { let s=Math.floor(ms/1000); return Math.floor(s/60)+":"+(s%60).toString().padStart(2,"0") }
    function openDevices() { devicesPopup.open(); if(auth.connected)spotify.refreshPlayer() }
    function changeVolume(delta) { if(root.volumeAvailable)spotify.setVolume(Math.max(0,Math.min(100,(root.track.volume||0)+delta))) }
    function toggleMute() {
        if((root.track.volume||0)>0){root.volumeBeforeMute=root.track.volume;spotify.setVolume(0)}
        else spotify.setVolume(root.volumeBeforeMute||50)
    }
    function cycleRepeat() { spotify.setRepeat(root.track.repeat==="off"||!root.track.repeat ? "context" : root.track.repeat==="context" ? "track" : "off") }
    Connections { target: spotify; function onPlaybackChanged() { root.position = spotify.position() } }
    FrameAnimation { running: !!root.track.playing && root.visible; onTriggered: root.position = spotify.position() }
    RowLayout {
        anchors.fill: parent; anchors.margins: 16; spacing: root.width < 850 ? 10 : 18
        CoverArt { source: root.track.cover || ""; Layout.preferredWidth: 72; Layout.preferredHeight: 72; variant: 3 }
        ColumnLayout {
            Layout.preferredWidth: root.width > 1050 ? 235 : root.width < 850 ? 120 : 155; Layout.maximumWidth: 260; spacing: 5
            Label { text: root.hasTrack ? root.track.name : "Nothing playing yet"; font.bold: true; color: Theme.text; Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText }
            Label { text: root.hasTrack ? root.track.subtitle : "Pick something to play"; color: Theme.muted; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText }
            Label {
                text: root.hasTrack ? (root.track.device ? "On " + root.track.device + "  ·  Spotify ↗" : "Via Spotify  ↗") : "Play here or on a Spotify device"
                color: Theme.primary; font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText
            }
            TapHandler { onTapped: { if(root.track.url)spotify.openSpotify(root.track.url) } }
        }
        ColumnLayout {
            Layout.fillWidth: true; spacing: 2
            RowLayout {
                Layout.alignment: Qt.AlignHCenter; spacing: root.width < 850 ? 2 : 8
                ActionButton {
                    symbol: "shuffle"; compact: true; selected: !!root.track.shuffle
                    hint: root.track.shuffle ? "Shuffle on (Ctrl+S)" : "Shuffle off (Ctrl+S)"
                    enabled: root.available && root.hasTrack && !root.restrictions.toggling_shuffle
                    onClicked: spotify.setShuffle(!root.track.shuffle)
                }
                ActionButton { symbol: "previous"; hint: "Previous track (Ctrl+←)"; enabled: root.available && !root.track.restricted && !root.restrictions.skipping_prev; onClicked: spotify.command("previous") }
                ActionButton { symbol: root.track.playing ? "pause" : "play"; hint: root.track.playing ? "Pause (Space)" : "Play (Space)"; filled: true; implicitWidth: 60; implicitHeight: 48; enabled: root.available && !root.track.restricted && !(root.track.playing ? root.restrictions.pausing : root.restrictions.resuming); onClicked: spotify.togglePlayback() }
                ActionButton { symbol: "next"; hint: "Next track (Ctrl+→)"; enabled: root.available && !root.track.restricted && !root.restrictions.skipping_next; onClicked: spotify.command("next") }
                ActionButton {
                    symbol: root.track.repeat==="track" ? "repeatOne" : "repeat"; compact: true; selected: !!root.track.repeat && root.track.repeat!=="off"
                    hint: root.track.repeat==="track" ? "Repeat this track (Ctrl+R)" : root.track.repeat==="context" ? "Repeat all (Ctrl+R)" : "Repeat off (Ctrl+R)"
                    enabled: root.available && root.hasTrack
                    onClicked: root.cycleRepeat()
                }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 10
                Label { text: root.time(wave.shown); font.pixelSize: 10; color: Theme.muted; font.features: ({"tnum": 1}); Layout.minimumWidth: 30; horizontalAlignment: Text.AlignRight }
                WavyProgress {
                    id: wave
                    Layout.fillWidth: true
                    position: root.position; duration: root.track.duration || 0
                    playing: !!root.track.playing
                    seekable: root.available && root.hasTrack && !root.track.restricted && !root.restrictions.seeking
                    onSeekRequested: ms => spotify.seek(Math.round(ms))
                }
                Label { text: root.time(root.track.duration || 0); font.pixelSize: 10; color: Theme.muted; font.features: ({"tnum": 1}); Layout.minimumWidth: 30 }
            }
        }
        RowLayout {
            spacing: 4
            ActionButton {
                symbol: (root.track.volume||0)===0 && root.hasTrack ? "mute" : "volume"; compact: true; visible: root.width > 1000
                hint: (root.track.volume||0)===0 ? "Unmute" : "Mute"; enabled: root.volumeAvailable; onClicked: root.toggleMute()
            }
            Slider {
                id: volume
                visible: root.width > 1000; Layout.preferredWidth: 110
                from: 0; to: 100; stepSize: 1; wheelEnabled: true
                value: root.track.volume || 0
                enabled: root.volumeAvailable
                // The built-in player follows the slider live; remote devices get one request after a short pause.
                onMoved: commit.restart()
                Timer { id: commit; interval: 150; onTriggered: spotify.setVolume(Math.round(volume.value)) }
                Accessible.name: "Volume"
                ToolTip.visible: hovered || pressed; ToolTip.text: Math.round(value) + "%"; ToolTip.delay: pressed ? 0 : 650
            }
            ActionButton { symbol: "plus"; hint: "Save track"; visible: root.width > 1000; enabled: root.available && (root.track.uri || "").startsWith("spotify:track:"); onClicked: spotify.save(root.track.uri) }
            ActionButton { id: deviceButton; symbol: "device"; hint: "Choose playback device (Ctrl+D)"; selected: devicesPopup.opened; onClicked: root.openDevices() }
            ActionButton { symbol: "refresh"; hint: "Refresh playback status"; visible: root.width > 1180; enabled: auth.connected; onClicked: spotify.refreshPlayer() }
        }
    }
    Popup {
        id: devicesPopup
        parent: Overlay.overlay
        x: Math.max(12,parent.width-width-24); y: Math.max(12,parent.height-height-root.height-24)
        width: Math.min(360,parent.width-32); padding: 22
        background: Rectangle { color: Theme.elevated; radius: 24; border.color: Theme.outline }
        contentItem: ColumnLayout {
            spacing: 14
            Label { text: "Where do you want to listen?"; font.pixelSize: 20; font.bold: true; color: Theme.text }
            Label { text: localPlayer.status; color: Theme.muted; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            ActionButton { text: localPlayer.ready ? "Stop local player" : localPlayer.busy ? "Connecting player…" : "Listen on this computer"; symbol: "play"; filled: true; Layout.fillWidth: true; enabled: auth.connected && !localPlayer.busy; onClicked: localPlayer.ready ? localPlayer.stop() : localPlayer.start() }
            ComboBox {
                Layout.fillWidth: true; model: spotify.devices; textRole: "name"; valueRole: "id"
                currentIndex: spotify.devices.findIndex(d=>d.id===spotify.deviceId)
                displayText: count ? currentText : "No device available"
                onActivated: spotify.deviceId=currentValue
                Accessible.name: "Playback device"
            }
            RowLayout {
                Layout.fillWidth: true
                ActionButton { symbol: (root.track.volume||0)===0 && root.hasTrack ? "mute" : "volume"; compact: true; hint: "Mute or unmute"; enabled: root.volumeAvailable; onClicked: root.toggleMute() }
                Slider {
                    id: popupVolume
                    Layout.fillWidth: true; from: 0; to: 100; stepSize: 1; wheelEnabled: true
                    value: root.track.volume || 0
                    enabled: root.volumeAvailable
                    onMoved: popupCommit.restart()
                    Timer { id: popupCommit; interval: 350; onTriggered: spotify.setVolume(Math.round(popupVolume.value)) }
                    Accessible.name: "Device volume"
                }
            }
            ActionButton { text: auth.connected ? "Refresh devices" : "Connect Spotify"; symbol: auth.connected ? "refresh" : "arrow"; tonal: true; Layout.fillWidth: true; onClicked: {if(auth.connected)spotify.refreshPlayer();else{devicesPopup.close();root.configure()}} }
        }
    }
}
