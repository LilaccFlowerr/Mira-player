import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
// Album, year and more songs by the artist of one song. Opened from the song menu and the large player.
Popup {
    id: root
    signal searchRequested(string term)
    signal artistRequested(var artist)
    property var track: ({})
    readonly property var info: spotify.songInfo.uri === track.uri ? spotify.songInfo : ({})
    readonly property bool ready: !!info.ready
    readonly property string artistName: info.artistName || (track.artists && track.artists.length ? track.artists[0] : "")
    function openFor(data) { track = data; spotify.loadSongInfo(data.uri, data.artists && data.artists.length ? data.artists[0] : ""); open() }
    onClosed: spotify.closeSongInfo()
    parent: Overlay.overlay; anchors.centerIn: parent
    width: Math.min(520, parent.width - 24); height: Math.min(implicitHeight, parent.height - 24)
    modal: true; padding: 20
    background: Rectangle { radius: Theme.r(28); color: Theme.panel; border.color: Theme.outline }
    contentItem: ScrollView {
        id: scroll; clip: true; contentWidth: availableWidth
        implicitHeight: body.implicitHeight
        SmoothScroll { flick: scroll.contentItem }
        ColumnLayout {
            id: body
            width: scroll.availableWidth; spacing: 16
            RowLayout {
                Layout.fillWidth: true; spacing: 14
                CoverArt { source: root.track.cover || ""; Layout.preferredWidth: 72; Layout.preferredHeight: 72 }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 3
                    Label { text: root.track.name || ""; font.pixelSize: Theme.fs(20); font.bold: true; color: Theme.text; Layout.fillWidth: true; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight; textFormat: Text.PlainText }
                    Label { text: root.track.subtitle || ""; color: Theme.muted; Layout.fillWidth: true; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight; textFormat: Text.PlainText }
                }
                ActionButton { symbol: "close"; compact: true; hint: "Close"; onClicked: root.close() }
            }
            Label { visible: !root.ready; text: "Loading…"; color: Theme.muted }
            // Album
            Rectangle {
                visible: root.ready && !!root.info.albumName; Layout.fillWidth: true; implicitHeight: albumRow.implicitHeight + 24; radius: Theme.r(18); color: Theme.elevated
                RowLayout {
                    id: albumRow; anchors.fill: parent; anchors.margins: 12; spacing: 14
                    CoverArt { source: root.info.albumCover || ""; Layout.preferredWidth: 56; Layout.preferredHeight: 56 }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 3
                        Label { text: root.info.albumName || ""; font.bold: true; color: Theme.text; Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText }
                        Label { text: [root.info.year, root.info.albumSongs > 0 ? root.info.albumSongs + " songs" : ""].filter(v => !!v).join(" · ") || "Album"; color: Theme.muted; font.pixelSize: Theme.fs(12) }
                    }
                    ActionButton { symbol: "play"; compact: true; hint: "Play album"; enabled: !!spotify.deviceId; onClicked: { spotify.play(root.info.albumUri); root.close() } }
                    ActionButton { symbol: "external"; compact: true; hint: "Open album in Spotify"; enabled: !!root.info.albumUrl; onClicked: spotify.openSpotify(root.info.albumUrl) }
                }
            }
            // More by the artist
            RowLayout {
                visible: root.ready && !!root.artistName; Layout.fillWidth: true
                Label { text: "More from " + root.artistName; font.bold: true; color: Theme.primary; Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText }
                ActionButton { text: "Artist page"; compact: true; onClicked: { if(root.info.artistId)root.artistRequested({id: root.info.artistId, name: root.artistName, cover: ""});else root.searchRequested(root.artistName); root.close() } }
                ActionButton { symbol: "external"; compact: true; visible: !!root.info.artistUrl; hint: "Open artist in Spotify"; onClicked: spotify.openSpotify(root.info.artistUrl) }
            }
            Repeater {
                model: root.ready && root.info.more ? root.info.more : []
                delegate: ItemDelegate {
                    required property var modelData
                    Layout.fillWidth: true; implicitHeight: 56; padding: 6; hoverEnabled: true
                    enabled: !!spotify.deviceId
                    background: Rectangle { radius: Theme.r(14); color: parent.hovered ? Theme.elevated : "transparent" }
                    contentItem: RowLayout {
                        spacing: 12
                        CoverArt { source: modelData.cover; Layout.preferredWidth: 42; Layout.preferredHeight: 42 }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 2
                            Label { text: modelData.name; color: Theme.text; Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText }
                            Label { text: modelData.album; color: Theme.muted; font.pixelSize: Theme.fs(12); Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText }
                        }
                    }
                    onClicked: { spotify.play(modelData.uri); root.close() }
                    Accessible.name: "Play " + modelData.name
                }
            }
        }
    }
}
