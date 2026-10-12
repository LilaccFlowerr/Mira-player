import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
// One song in a track list. The page it sits in supplies the context (what is playing, how to play from here).
ItemDelegate {
    id: trackRow
    required property var page
    required property var modelData
    required property int index
    // Which list this row belongs to; the page decides what "play from here" means for it.
    property string source: "main"
    function playHere() { page.playRowFrom(source, index) }
    readonly property bool current: !!modelData.uri && modelData.uri===spotify.playback.uri
    Layout.fillWidth: true; implicitHeight: page.compact ? 64 : 72; padding: page.compact ? 6 : 10; hoverEnabled: true
    background: Rectangle { radius: Theme.r(16); color: trackRow.hovered||trackRow.visualFocus ? Theme.elevated : trackRow.current ? Theme.container : "transparent"; border.width: trackRow.visualFocus?1:0; border.color: Theme.primary }
    contentItem: RowLayout {
        spacing: 12
        ActionButton {
            text: trackRow.hovered || trackRow.current ? "" : String(trackRow.index+1)
            symbol: trackRow.hovered ? (trackRow.current && spotify.playback.playing ? "pause" : "play") : trackRow.current ? "bars" : ""
            ink: trackRow.current ? Theme.primary : Theme.text
            implicitWidth: 30; compact: true; hint: (trackRow.current && spotify.playback.playing ? "Pause " : "Play ") + modelData.name; enabled: page.canPlay
            onClicked: trackRow.current ? spotify.togglePlayback() : trackRow.playHere()
        }
        CoverArt { source: modelData.cover; Layout.preferredWidth: 46; Layout.preferredHeight: 46 }
        ColumnLayout {
            Layout.fillWidth: true; spacing: 5
            Label { text: modelData.name; color: trackRow.current ? Theme.primary : Theme.text; font.bold: true; Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText }
            Label { text: (modelData.explicit ? "[E]  " : "") + modelData.subtitle; color: Theme.muted; font.pixelSize: Theme.fs(12); Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText }
        }
        Label { text: modelData.album; color: Theme.muted; Layout.preferredWidth: page.width*0.22; elide: Text.ElideRight; visible: page.width>800; font.pixelSize: Theme.fs(12); textFormat: Text.PlainText }
        Label { visible: !page.compact; text: page.duration(modelData.duration); color: Theme.muted; font.pixelSize: Theme.fs(11); Layout.preferredWidth: 38 }
        ActionButton { visible: !page.compact; symbol: "plus"; hint: "Save to Spotify"; compact: true; onClicked: spotify.save(modelData.uri) }
        ActionButton { id: moreButton; symbol: "more"; hint: "More actions for " + modelData.name; compact: true; implicitWidth: 44; onClicked: trackMenu.popup(moreButton, 0, moreButton.height) }
    }
    // Phone: one tap on the song plays it, only the three dots open the menu. Desktop: double click.
    onClicked: {if(page.compact && page.canPlay)trackRow.playHere()}
    onDoubleClicked: {if(!page.compact && page.canPlay)trackRow.playHere()}
    // Right click opens the menu on desktop only: on a touch screen Qt reports a tap as a click here too.
    TapHandler { enabled: !page.compact; acceptedButtons: Qt.RightButton; onTapped: trackMenu.popup() }
    Menu {
        id: trackMenu
        MenuItem { text: "Open in Spotify ↗"; onTriggered: spotify.openSpotify(modelData.url) }
        MenuItem { text: "Play from here"; enabled: page.canPlay; onTriggered: trackRow.playHere() }
        MenuItem { text: "Play only this song"; enabled: page.canPlay; onTriggered: spotify.play(modelData.uri) }
        MenuItem { text: "Add to queue"; enabled: page.canPlay; onTriggered: spotify.queue(modelData.uri) }
        MenuItem { text: "About this song"; enabled: (modelData.uri || "").startsWith("spotify:track:"); onTriggered: page.songInfoRequested(modelData) }
        MenuItem { text: "Go to artist"; enabled: !!(modelData.artistIds && modelData.artistIds.length && modelData.artistIds[0]); onTriggered: page.artistRequested({id: modelData.artistIds[0], name: modelData.artists[0], cover: ""}) }
        MenuItem { text: "Search artist"; enabled: !!(modelData.artists && modelData.artists.length); onTriggered: page.searchRequested(modelData.artists[0]) }
        MenuSeparator {}
        MenuItem { text: "Save to library"; onTriggered: spotify.save(modelData.uri) }
        MenuItem { text: "Copy Spotify link"; enabled: !!modelData.url; onTriggered: page.copyText(modelData.url) }
        MenuItem { text: "Remove from library…"; visible: page.mode===2; height: visible?implicitHeight:0; onTriggered: page.askRemove(modelData.uri) }
    }
}
