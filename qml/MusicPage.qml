import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
ScrollView {
    id: page
    signal configure()
    signal searchRequested(string term)
    signal navigateRequested(int mode)
    signal playerRequested()
    property int mode: 0
    property string searchTerm: ""
    property var selectedPlaylist: ({})
    readonly property bool matching: (mode===1 && spotify.collection==="search") || (mode===2 && spotify.collection==="library") || (mode===3 && spotify.collection==="playlists") || (mode===4 && spotify.collection==="playlist")
    readonly property var entries: mode===0 ? spotify.playlistItems : matching ? spotify.items : []
    readonly property bool failure: ["error","quota","offline"].indexOf(spotify.state)>=0
    readonly property bool trackList: mode===1 || mode===2 || mode===4
    // Phone-sized page: fewer columns and smaller decorations.
    readonly property bool compact: width < 600
    // On Android, Play also works without a device yet: Mira then opens the Spotify app on the phone.
    readonly property bool canPlay: !!spotify.deviceId || Qt.platform.os === "android"
    property string filter: ""
    // Songs shown in track lists after the local filter; only loaded songs are searched.
    readonly property var shown: {
        const term=filter.trim().toLowerCase()
        if(!trackList || !term.length)return entries
        return entries.filter(e=>[e.name,e.subtitle,e.album].some(v=>(v||"").toLowerCase().indexOf(term)>=0))
    }
    function playRow(index) {
        if(mode===4)spotify.playInContext(selectedPlaylist.uri, shown[index].uri)
        else if(mode===2)spotify.playLiked(shown.map(e=>e.uri), index)
        else spotify.playFrom(shown.map(e=>e.uri), index)
    }
    // Up to four different album covers from the open playlist, for playlists without their own cover.
    readonly property var mosaic: {
        if(mode!==4 || !matching)return []
        const seen=[]
        for(const e of entries){ if(e.cover && seen.indexOf(e.cover)<0)seen.push(e.cover); if(seen.length===4)break }
        return seen
    }
    function focusFilter() { if(mode===2||mode===4)filterField.forceActiveFocus() }
    function openPlaylist(data) { if(spotify.busy)return;selectedPlaylist=data;mode=4;spotify.playlist(data.id) }
    function duration(ms) {let s=Math.floor(ms/1000);return Math.floor(s/60)+":"+(s%60).toString().padStart(2,"0")}
    clip: true; contentWidth: availableWidth
    onModeChanged: { contentItem.contentY=0; filter=""; modeFade.restart() }
    property int hour: new Date().getHours()
    Timer { interval: 60000; repeat: true; running: page.visible; onTriggered: page.hour=new Date().getHours() }
    readonly property string greeting: hour<5 ? "Good night" : hour<12 ? "Good morning" : hour<18 ? "Good afternoon" : "Good evening"
    readonly property var nowPlaying: spotify.playback
    ColumnLayout {
        id: content
        width: page.availableWidth; spacing: 24
        transform: Translate { id: slide }
        ParallelAnimation {
            id: modeFade
            NumberAnimation { target: content; property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { target: slide; property: "y"; from: 10; to: 0; duration: 260; easing.type: Easing.OutCubic }
        }
        RowLayout {
            Layout.fillWidth: true
            ActionButton { symbol: "back"; hint: "Back"; compact: true; tonal: true; visible: page.mode!==0; onClicked: page.navigateRequested(page.mode===4?3:0) }
            Label { text: page.mode===0 ? "Your music" : page.mode===1 ? "Search" : "Your library"; color: Theme.muted; font.pixelSize: 12; Layout.fillWidth: true }
            Label { text: auth.connected ? "Spotify connected" : "Not connected"; color: Theme.muted; font.pixelSize: 11; visible: page.width>600 }
        }
        Rectangle {
            visible: page.mode===0; Layout.fillWidth: true; Layout.preferredHeight: page.compact ? 200 : page.width>660 ? 218 : 204
            radius: 26; color: Theme.container; clip: true
            Item {
                anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
                width: parent.width*0.38; visible: page.width>530
                ShapeArt {
                    width: 225; height: 225; anchors.centerIn: parent; variant: 3; color: Theme.primary
                    opacity: page.nowPlaying.uri ? 0.35 : 1
                    // Turns slowly while music plays.
                    RotationAnimation on turn { running: !!page.nowPlaying.playing && page.visible && page.mode===0; from: 0; to: 360; duration: 40000; loops: Animation.Infinite }
                }
                CoverArt {
                    visible: !!page.nowPlaying.uri; anchors.centerIn: parent; width: 132; height: 132
                    source: page.nowPlaying.cover || ""; variant: 3
                }
                Item {
                    visible: !page.nowPlaying.uri; anchors.fill: parent
                    Rectangle { width: 110; height: 110; radius: 55; color: Theme.container; anchors.centerIn: parent; border.color: Theme.onPrimary; border.width: 1 }
                    Rectangle { width: 65; height: 65; radius: 33; color: Theme.primary; anchors.centerIn: parent }
                    Rectangle { width: 14; height: 14; radius: 7; color: Theme.container; anchors.centerIn: parent }
                }
                ShapeArt { width: 44; height: 44; x: 5; y: 12; variant: 2; color: Theme.primary; opacity: 0.45 }
            }
            ColumnLayout {
                anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.margins: page.compact ? 20 : 26
                width: parent.width*(page.width>530?0.62:0.88); spacing: 10
                Label { text: page.nowPlaying.uri ? (page.nowPlaying.playing ? "NOW PLAYING" : "PAUSED") : page.greeting.toUpperCase(); color: Theme.primary; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.8 }
                Label {
                    text: page.nowPlaying.uri ? page.nowPlaying.name : !auth.connected ? "Connect Spotify\nto get started." : page.greeting + "."
                    font.pixelSize: page.compact ? 26 : page.width>700?38:30; font.bold: true; font.letterSpacing: -1; color: Theme.text; lineHeight: 0.95
                    Layout.fillWidth: true; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight; textFormat: Text.PlainText
                }
                Label {
                    visible: !!page.nowPlaying.uri || auth.connected
                    text: page.nowPlaying.uri ? page.nowPlaying.subtitle : "Pick something from your library or search above."
                    color: Theme.muted; Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText
                }
                Item { Layout.fillHeight: true }
                ActionButton {
                    text: page.nowPlaying.uri ? "Open player" : auth.connected ? "Liked songs" : "Connect Spotify"
                    symbol: page.nowPlaying.uri ? "arrow" : auth.connected ? "heart" : "arrow"; filled: true
                    onClicked: page.nowPlaying.uri ? page.playerRequested() : auth.connected ? page.navigateRequested(2) : page.configure()
                }
            }
        }
        ColumnLayout {
            visible: page.mode!==0; Layout.fillWidth: true; spacing: 12
            RowLayout {
                Layout.fillWidth: true; spacing: 20
                Item {
                    visible: page.mode===4; Layout.preferredWidth: page.width>650?126:84; Layout.preferredHeight: width
                    readonly property bool useMosaic: !page.selectedPlaylist.cover && page.mosaic.length===4
                    CoverArt { anchors.fill: parent; visible: !parent.useMosaic; source: page.selectedPlaylist.cover || page.mosaic[0] || "" }
                    Grid {
                        anchors.fill: parent; columns: 2; visible: parent.useMosaic
                        Repeater { model: parent.parent.useMosaic ? page.mosaic : []; delegate: CoverArt { required property string modelData; width: parent.width/2; height: width; source: modelData; radius: 4 } }
                    }
                }
                Rectangle {
                    visible: page.mode===2; Layout.preferredWidth: page.width>650?126:84; Layout.preferredHeight: width; radius: 24; color: Theme.container
                    ShapeArt { anchors.centerIn: parent; width: parent.width*0.8; height: width; variant: 3; color: Theme.primary; opacity: 0.25 }
                    Icon { anchors.centerIn: parent; width: 42; height: 42; name: "heart"; color: Theme.primary }
                }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 8
                    Label { text: page.mode===1 ? "SEARCH RESULTS" : page.mode===4 ? "PLAYLIST" : page.mode===2 ? "LIBRARY" : "PLAYLISTS"; font.pixelSize: 10; font.letterSpacing: 1.6; color: Theme.primary }
                    Label { text: page.mode===1 ? (page.searchTerm.length ? "‘"+page.searchTerm+"’" : "Search") : page.mode===2 ? "Liked songs" : page.mode===3 ? "Your playlists" : page.selectedPlaylist.name || "Playlist"; font.pixelSize: page.width>650?34:26; font.bold: true; font.letterSpacing: -0.7; color: Theme.text; Layout.fillWidth: true; wrapMode: Text.WordWrap; textFormat: Text.PlainText }
                    Label { text: page.mode===1 ? "Search above by song or artist." : page.mode===2 ? "Songs you saved on Spotify." : page.mode===3 ? "Playlists you own or follow." : (page.selectedPlaylist.subtitle || "Spotify"); color: Theme.muted; Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText }
                }
            }
            // On phones the filter moves to its own full-width row under the buttons.
            GridLayout {
                visible: page.mode===2 || page.mode===4; columnSpacing: 10; rowSpacing: 10; Layout.fillWidth: true
                columns: page.compact ? 3 : 4
                ActionButton {
                    symbol: "play"; text: "Play"; filled: true
                    enabled: auth.connected && page.canPlay && (page.mode===4 || page.shown.length>0)
                    onClicked: page.mode===4 ? spotify.play(page.selectedPlaylist.uri) : spotify.playLiked(page.shown.map(e=>e.uri), 0)
                }
                ActionButton { visible: page.mode===2; symbol: "shuffle"; text: "Shuffle"; tonal: true; enabled: auth.connected && page.canPlay && page.shown.length>0; onClicked: spotify.playLiked(page.shown.map(e=>e.uri), 0, true) }
                ActionButton { visible: page.mode===4; symbol: "external"; text: "Open in Spotify"; tonal: true; onClicked: spotify.openSpotify(page.selectedPlaylist.url) }
                Item { Layout.fillWidth: true }
                Rectangle {
                    Layout.columnSpan: page.compact ? 3 : 1; Layout.fillWidth: page.compact
                    Layout.preferredWidth: page.compact ? -1 : Math.min(280, page.width*0.4); Layout.preferredHeight: 40; radius: 20; color: Theme.elevated
                    border.width: filterField.activeFocus ? 2 : 0; border.color: Theme.primary
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 6; spacing: 8
                        Icon { name: "search"; color: Theme.muted; Layout.preferredWidth: 18; Layout.preferredHeight: 18 }
                        TextField {
                            id: filterField; Layout.fillWidth: true; text: page.filter; onTextEdited: page.filter=text
                            placeholderText: page.mode===2 ? "Find in liked songs" : "Find in playlist"; color: Theme.text; placeholderTextColor: Theme.muted
                            background: Item {} leftPadding: 0; rightPadding: 0; selectByMouse: true
                            Keys.onEscapePressed: { if(text.length)page.filter=""; else focus=false }
                            Accessible.name: "Filter loaded songs (Ctrl+F)"
                        }
                        ActionButton { symbol: "close"; compact: true; hint: "Clear filter"; visible: page.filter.length>0; onClicked: page.filter="" }
                    }
                }
            }
        }
        ColumnLayout {
            visible: page.mode===0 || (page.mode===1 && !page.searchTerm.length); Layout.fillWidth: true; spacing: 14
            RowLayout {
                Label { text: "Browse by genre"; font.pixelSize: 21; font.bold: true; color: Theme.text; Layout.fillWidth: true }
            }
            GridLayout {
                columns: page.width>650?4:2; Layout.fillWidth: true; columnSpacing: 12; rowSpacing: 12
                Repeater {
                    model: [{name:"Ambient",query:"ambient",sub:"Search",bg:"#343b33",ink:"#c3d6ad",shape:1},{name:"Electronic",query:"electronic",sub:"Search",bg:"#44313e",ink:"#efbad5",shape:2},{name:"Indie",query:"indie",sub:"Search",bg:"#40372f",ink:"#edc6a0",shape:0},{name:"Jazz",query:"jazz",sub:"Search",bg:"#303b48",ink:"#b6cdec",shape:3}]
                    delegate: AbstractButton {
                        id: quickCard
                        required property var modelData
                        Layout.fillWidth: true; Layout.preferredWidth: 160; implicitHeight: page.compact ? 108 : 152
                        hoverEnabled: true
                        background: Rectangle { radius: quickCard.hovered ? 20 : 24; color: modelData.bg; border.width: quickCard.visualFocus?2:0; border.color: modelData.ink; Behavior on radius {NumberAnimation{duration:180}} }
                        ShapeArt { width: page.compact ? 52 : 76; height: width; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 10; color: modelData.ink; variant: modelData.shape; turn: quickCard.hovered?25:0; Behavior on turn{NumberAnimation{duration:300;easing.type:Easing.OutCubic}} }
                        Column { anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 16; spacing: 5
                            Label { text: modelData.name; color: modelData.ink; font.pixelSize: 15; font.bold: true }
                            Label { text: modelData.sub; color: modelData.ink; opacity: 0.7; font.pixelSize: 11 }
                        }
                        onClicked: page.searchRequested(modelData.query)
                        Accessible.name: "Search for " + modelData.name
                    }
                }
            }
        }
        Rectangle {
            visible: page.failure; Layout.fillWidth: true; implicitHeight: errorRow.implicitHeight+24; radius: 16; color: Theme.elevated
            RowLayout {
                id: errorRow; anchors.fill: parent; anchors.margins: 12
                Label { text: spotify.message; color: Theme.error; Layout.fillWidth: true; wrapMode: Text.WordWrap; textFormat: Text.PlainText }
                ActionButton { symbol: "refresh"; hint: "Try again"; enabled: !spotify.busy&&auth.connected; onClicked: spotify.retry() }
            }
        }
        LoadingIndicator { running: spotify.busy; Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: 56; Layout.preferredHeight: 56; Accessible.name: "Loading music" }
        RowLayout {
            visible: page.mode===0 || page.entries.length>0; Layout.fillWidth: true
            Label { text: page.mode===0 ? "Your playlists" : page.mode===3 ? "In your library" : "Songs"; font.pixelSize: 21; font.bold: true; color: Theme.text; Layout.fillWidth: true }
            ActionButton { visible: page.mode===0; text: "See all"; symbol: "arrow"; compact: true; onClicked: page.navigateRequested(3) }
            Label { visible: page.mode!==0; text: page.shown.length!==page.entries.length ? page.shown.length + " of " + page.entries.length + " loaded" : page.entries.length + " loaded"; color: Theme.muted; font.pixelSize: 11 }
        }
        Rectangle {
            visible: page.entries.length===0 && !spotify.busy && !(page.mode===1&&!page.searchTerm.length)
            Layout.fillWidth: true; implicitHeight: 108; radius: 22; color: Theme.elevated
            RowLayout {
                anchors.fill: parent; anchors.margins: 20; spacing: 18
                ShapeArt { Layout.preferredWidth: 56; Layout.preferredHeight: 56; variant: 1; color: Theme.primary; opacity: 0.6 }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 6
                    Label { text: !auth.connected ? "Not connected" : page.matching ? "Nothing here" : "Nothing loaded yet"; color: Theme.text; font.pixelSize: 16; font.bold: true; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    Label { text: !auth.connected ? "Connect Spotify to see your songs and playlists." : page.matching ? "Spotify returned no items for this view." : "Open your library or search for a song."; color: Theme.muted; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                }
                ActionButton { symbol: auth.connected ? "refresh" : "arrow"; tonal: true; hint: auth.connected ? "Load" : "Connect"; onClicked: { if(!auth.connected)page.configure();else if(page.mode===1&&page.searchTerm.length)page.searchRequested(page.searchTerm);else page.navigateRequested(page.mode===0?3:page.mode) } }
            }
        }
        GridLayout {
            visible: page.mode===0 || page.mode===3; columns: Math.max(2,Math.floor(page.width/190)); uniformCellWidths: true; Layout.fillWidth: true; columnSpacing: 16; rowSpacing: 20
            // Liked songs always come first, like a pinned playlist.
            ColumnLayout {
                visible: auth.connected
                Layout.fillWidth: true; Layout.preferredWidth: 180; Layout.minimumWidth: 0; Layout.alignment: Qt.AlignTop; spacing: 8
                AbstractButton {
                    id: likedCard
                    Layout.fillWidth: true; Layout.preferredHeight: width; hoverEnabled: true
                    background: Rectangle { radius: likedCard.hovered ? 20 : 24; color: Theme.container; border.width: likedCard.visualFocus?2:0; border.color: Theme.primary; Behavior on radius {NumberAnimation{duration:180}} }
                    ShapeArt { anchors.centerIn: parent; width: parent.width*0.78; height: width; variant: 3; color: Theme.primary; opacity: 0.25; turn: likedCard.hovered?20:0; Behavior on turn{NumberAnimation{duration:300;easing.type:Easing.OutCubic}} }
                    Icon { anchors.centerIn: parent; width: parent.width*0.28; height: width; name: "heart"; color: Theme.primary }
                    onClicked: page.navigateRequested(2)
                    Accessible.name: "Open liked songs"
                }
                Label { text: "Liked songs"; color: Theme.text; font.bold: true; font.pixelSize: 14; Layout.fillWidth: true; elide: Text.ElideRight }
                Label { text: page.compact ? "Your saved tracks" : "Your saved tracks · Ctrl+2"; color: Theme.muted; font.pixelSize: 11; Layout.fillWidth: true; Layout.preferredHeight: 26; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
            }
            Repeater {
                model: (page.mode===0 || page.mode===3) ? page.entries : []
                delegate: ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true; Layout.preferredWidth: 180; Layout.minimumWidth: 0; Layout.alignment: Qt.AlignTop; spacing: 8
                    Item {
                        Layout.fillWidth: true; Layout.preferredHeight: width
                        CoverArt {
                            anchors.fill: parent; source: modelData.cover
                            scale: coverArea.containsMouse ? 1.03 : 1
                            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }
                        MouseArea { id: coverArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.openPlaylist(modelData) }
                        ActionButton { anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 8; symbol: "play"; filled: true; hint: "Play " + modelData.name; enabled: page.canPlay; onClicked: spotify.play(modelData.uri) }
                    }
                    Button {
                        text: modelData.name; Layout.fillWidth: true; Layout.minimumWidth: 0; implicitWidth: 0; implicitHeight: 24; padding: 0
                        background: Rectangle { radius: 6; color: "transparent"; border.width: parent.visualFocus?1:0; border.color: Theme.primary }
                        contentItem: Text { text: parent.text; width: parent.width; color: Theme.text; font.bold: true; font.pixelSize: 14; elide: Text.ElideRight; horizontalAlignment: Text.AlignLeft; verticalAlignment: Text.AlignVCenter; textFormat: Text.PlainText }
                        onClicked: page.openPlaylist(modelData)
                    }
                    ActionButton { text: "Spotify ↗"; compact: true; implicitHeight: 26; Layout.alignment: Qt.AlignLeft; ink: Theme.muted; onClicked: spotify.openSpotify(modelData.url) }
                }
            }
        }
        ColumnLayout {
            visible: page.trackList; Layout.fillWidth: true; spacing: 2
            RowLayout {
                visible: page.entries.length>0; Layout.fillWidth: true; Layout.leftMargin: 14; Layout.rightMargin: 14; Layout.bottomMargin: 8
                Label { text: "#"; color: Theme.muted; Layout.preferredWidth: 34; font.pixelSize: 11 }
                Label { text: "TITLE"; color: Theme.muted; Layout.fillWidth: true; font.pixelSize: 10; font.letterSpacing: 1 }
                Label { text: "ALBUM"; color: Theme.muted; Layout.preferredWidth: page.width*0.22; visible: page.width>800; font.pixelSize: 10; font.letterSpacing: 1 }
                Icon { visible: !page.compact; name: "timer"; color: Theme.muted; Layout.preferredWidth: 16; Layout.preferredHeight: 16 }
                Item { Layout.preferredWidth: page.compact ? 36 : 84 }
            }
            Repeater {
                model: page.trackList ? page.shown : []
                delegate: ItemDelegate {
                    id: trackRow
                    required property var modelData
                    required property int index
                    readonly property bool current: !!modelData.uri && modelData.uri===spotify.playback.uri
                    Layout.fillWidth: true; implicitHeight: page.compact ? 64 : 72; padding: page.compact ? 6 : 10; hoverEnabled: true
                    background: Rectangle { radius: 16; color: trackRow.hovered||trackRow.visualFocus ? Theme.elevated : trackRow.current ? Theme.container : "transparent"; border.width: trackRow.visualFocus?1:0; border.color: Theme.primary }
                    contentItem: RowLayout {
                        spacing: 12
                        ActionButton {
                            text: trackRow.hovered || trackRow.current ? "" : String(trackRow.index+1)
                            symbol: trackRow.hovered ? (trackRow.current && spotify.playback.playing ? "pause" : "play") : trackRow.current ? "bars" : ""
                            ink: trackRow.current ? Theme.primary : Theme.text
                            implicitWidth: 30; compact: true; hint: (trackRow.current && spotify.playback.playing ? "Pause " : "Play ") + modelData.name; enabled: page.canPlay
                            onClicked: trackRow.current ? spotify.togglePlayback() : page.playRow(trackRow.index)
                        }
                        CoverArt { source: modelData.cover; Layout.preferredWidth: 46; Layout.preferredHeight: 46 }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 5
                            Label { text: modelData.name; color: trackRow.current ? Theme.primary : Theme.text; font.bold: true; Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText }
                            Label { text: (modelData.explicit ? "[E]  " : "") + modelData.subtitle; color: Theme.muted; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText }
                        }
                        Label { text: modelData.album; color: Theme.muted; Layout.preferredWidth: page.width*0.22; elide: Text.ElideRight; visible: page.width>800; font.pixelSize: 12; textFormat: Text.PlainText }
                        Label { visible: !page.compact; text: page.duration(modelData.duration); color: Theme.muted; font.pixelSize: 11; Layout.preferredWidth: 38 }
                        ActionButton { visible: !page.compact; symbol: "plus"; hint: "Save to Spotify"; compact: true; onClicked: spotify.save(modelData.uri) }
                        ActionButton { id: moreButton; symbol: "more"; hint: "More actions for " + modelData.name; compact: true; implicitWidth: 44; onClicked: trackMenu.popup(moreButton, 0, moreButton.height) }
                    }
                    // Phone: one tap on the song plays it, the three dots (or a long press) open the menu. Desktop: double click.
                    onClicked: {if(page.compact && page.canPlay)page.playRow(trackRow.index)}
                    onDoubleClicked: {if(!page.compact && page.canPlay)page.playRow(trackRow.index)}
                    onPressAndHold: trackMenu.popup(moreButton, 0, moreButton.height)
                    TapHandler { acceptedButtons: Qt.RightButton; onTapped: trackMenu.popup() }
                    Menu {
                        id: trackMenu
                        MenuItem { text: "Open in Spotify ↗"; onTriggered: spotify.openSpotify(modelData.url) }
                        MenuItem { text: "Play from here"; enabled: page.canPlay; onTriggered: page.playRow(trackRow.index) }
                        MenuItem { text: "Play only this song"; enabled: page.canPlay; onTriggered: spotify.play(modelData.uri) }
                        MenuItem { text: "Add to queue"; enabled: page.canPlay; onTriggered: spotify.queue(modelData.uri) }
                        MenuItem { text: "Search artist"; enabled: !!(modelData.artists && modelData.artists.length); onTriggered: page.searchRequested(modelData.artists[0]) }
                        MenuSeparator {}
                        MenuItem { text: "Save to library"; onTriggered: spotify.save(modelData.uri) }
                        MenuItem { text: "Copy Spotify link"; enabled: !!modelData.url; onTriggered: { clipboard.text=modelData.url; clipboard.selectAll(); clipboard.copy() } }
                        MenuItem { text: "Remove from library…"; visible: page.mode===2; height: visible?implicitHeight:0; onTriggered: {removeDialog.uri=modelData.uri;removeDialog.open()} }
                    }
                }
            }
        }
        Label { visible: page.trackList && page.filter.length>0 && page.shown.length===0 && page.entries.length>0; text: "No loaded songs match ‘" + page.filter + "’." + (spotify.hasMore ? " Load more to search further." : ""); color: Theme.muted; Layout.fillWidth: true; wrapMode: Text.WordWrap; textFormat: Text.PlainText }
        ActionButton { visible: page.mode!==0&&page.matching&&spotify.hasMore; text: "Load more"; symbol: "plus"; tonal: true; enabled: !spotify.busy; onClicked: spotify.more(); Layout.alignment: Qt.AlignHCenter }
        Label { visible: page.entries.length>0; text: "Content provided by Spotify · open in Spotify for all features"; font.pixelSize: 10; color: Theme.muted; Layout.fillWidth: true; wrapMode: Text.WordWrap }
        Item { Layout.preferredHeight: 4 }
        // Invisible helper for "Copy Spotify link"; QML has no direct clipboard API.
        TextEdit { id: clipboard; visible: false }
    }
    Dialog { id: removeDialog; property string uri; title: "Remove from liked songs?"; modal: true; anchors.centerIn: Overlay.overlay; standardButtons: Dialog.Ok | Dialog.Cancel; onAccepted: spotify.save(uri,true) }
}
