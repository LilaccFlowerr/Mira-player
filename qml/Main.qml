import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtCore
ApplicationWindow {
    id: window
    width: 1320; height: 860; minimumWidth: 360; minimumHeight: 560
    visible: true
    title: spotify.playback.uri ? spotify.playback.name + " · " + spotify.playback.subtitle + " — " + appName : appName
    Material.theme: prefs.dark ? Material.Dark : Material.Light
    Material.accent: Theme.primary; Material.primary: Theme.primary
    Material.foreground: Theme.text; Material.background: Theme.panel
    color: Theme.base
    font.family: prefs.fontStyle === 1 ? (Qt.platform.os === "windows" || Qt.platform.os === "osx" ? "Georgia" : "Noto Serif")
               : prefs.fontStyle === 2 ? (Qt.platform.os === "windows" ? "Consolas" : Qt.platform.os === "osx" ? "Menlo" : "Monospace")
               : Qt.platform.os === "windows" ? "Segoe UI" : Qt.platform.os === "android" ? "Roboto" : "Noto Sans"
    font.pixelSize: Theme.fs(14)
    property int activePage: initialPage === 2 ? 1 : 0
    property bool narrow: width < 980
    // Phone layout: bottom navigation instead of the sidebar, compact player. Always on Android.
    readonly property bool phone: Qt.platform.os === "android" || width < 600
    readonly property string navKey: activePage===1 ? "settings" : (music.mode===1 || music.mode===5) ? "search" : music.mode===2 ? "liked" : (music.mode===3||music.mode===4) ? "playlists" : "home"
    // Android's back button: step back through the app before leaving it.
    function goBack() {
        if(nowPlaying.opened){nowPlaying.close();return true}
        if(activePage===1){activePage=0;return true}
        if(music.mode===4){navigate(3);return true}
        if(music.mode!==0){navigate(0);return true}
        return false
    }
    onClosing: close => { if(Qt.platform.os==="android" && goBack())close.accepted=false }
    // Android's status and navigation bars follow the app background instead of Qt's default blue.
    readonly property color barColor: Theme.base
    onBarColorChanged: systemBars.apply(Theme.base, prefs.dark)
    Component.onCompleted: systemBars.apply(Theme.base, prefs.dark)
    property bool initialized: false
    property bool devicesRequested: false
    // Space toggles playback unless the user is typing or moved to a control with the keyboard,
    // where Space must keep activating that control. Focus left behind by a mouse click does not count.
    readonly property var focusTarget: window.activeFocusItem
    readonly property bool typing: !!focusTarget && (focusTarget.cursorPosition !== undefined || focusTarget.focusReason === Qt.TabFocusReason || focusTarget.focusReason === Qt.BacktabFocusReason)
    function navigate(mode) { activePage=0; music.mode=mode; if(auth.connected&&!spotify.busy){if(mode===2)spotify.library();if(mode===3)spotify.playlists()} }
    function openArtist(artist) { if(!auth.connected || !artist || !artist.id)return; nowPlaying.close(); activePage=0; music.openArtist(artist) }
    function searchFor(term) { prefs.rememberSearch(term); activePage=0; search.text=term; music.searchTerm=term; music.mode=1; if(auth.connected&&!spotify.busy)spotify.search(term) }
    Settings {
        category: "window"
        property alias width: window.width
        property alias height: window.height
    }
    Connections {
        target: auth
        function onChanged() {
            if(!auth.connected){window.initialized=false;window.devicesRequested=false}
            else if(!auth.busy && !window.initialized) {
                window.initialized=true;spotify.playlists()
                if(prefs.autoStartPlayer && !localPlayer.ready && !localPlayer.busy)localPlayer.start()
            }
        }
    }
    Connections {
        target: spotify
        function onChanged() {
            if(window.initialized && auth.connected && !spotify.busy && !window.devicesRequested) {
                window.devicesRequested=true
                spotify.refreshPlayer()
            }
        }
        function onNotify(text) { snackbar.show(text) }
    }
    ColumnLayout {
        anchors.fill: parent; anchors.margins: window.phone ? 8 : 14; spacing: window.phone ? 8 : 12
        RowLayout {
            Layout.fillWidth: true; Layout.preferredHeight: window.phone ? 48 : 56; spacing: window.phone ? 8 : 16
            RowLayout {
                Layout.preferredWidth: window.phone ? 40 : window.narrow ? 66 : 220; spacing: 10
                Image { source: "qrc:/assets/mira.png"; Layout.preferredWidth: window.phone ? 36 : 40; Layout.preferredHeight: Layout.preferredWidth }
                Label { visible: !window.narrow; text: appName.toLowerCase(); font.pixelSize: Theme.fs(27); font.bold: true; font.letterSpacing: -1; color: Theme.text }
            }
            Rectangle {
                Layout.fillWidth: true; Layout.maximumWidth: 620; Layout.preferredHeight: window.phone ? 44 : 48; radius: height/2; color: Theme.elevated
                border.width: search.activeFocus ? 2 : 0; border.color: Theme.primary
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: window.phone ? 14 : 17; anchors.rightMargin: window.phone ? 4 : 10; spacing: window.phone ? 8 : 12
                    Icon { name: "search"; color: Theme.muted }
                    TextField {
                        id: search; Layout.fillWidth: true; placeholderText: window.width < 780 ? "Search music" : "What do you want to listen to?"; color: Theme.text; placeholderTextColor: Theme.muted
                        selectByMouse: true; background: Item {} leftPadding: 0; rightPadding: 0; topPadding: 0; bottomPadding: 0; verticalAlignment: TextInput.AlignVCenter; Layout.alignment: Qt.AlignVCenter
                        onAccepted: {if(text.trim().length)window.searchFor(text.trim())}
                        Keys.onEscapePressed: { if(text.length)text=""; else focus=false }
                        Accessible.name: "Search music on Spotify"
                    }
                    ActionButton { symbol: "close"; compact: true; hint: "Clear search"; visible: search.text.length>0; onClicked: {search.text="";search.forceActiveFocus()} }
                    Label { text: "Ctrl K"; visible: window.width > 1000 && search.text.length===0; color: Theme.muted; font.pixelSize: Theme.fs(11) }
                    ActionButton { symbol: search.text.length ? "arrow" : "search"; compact: true; hint: "Search"; enabled: !spotify.busy; onClicked: {if(search.text.trim().length)window.searchFor(search.text.trim());else{window.navigate(1);search.forceActiveFocus()}} }
                }
            }
            Item { Layout.fillWidth: true; visible: window.width > 1000 }
            ActionButton { visible: !window.phone; symbol: prefs.dark ? "sun" : "moon"; hint: "Light or dark theme"; onClicked: prefs.dark=!prefs.dark }
            ActionButton { visible: !window.phone || !auth.connected; text: window.width > 800 ? (auth.connected ? "Connected" : "Connect") : ""; symbol: auth.connected ? "check" : "plus"; tonal: auth.connected; filled: !auth.connected; hint: "Set up the Spotify connection"; onClicked: window.activePage=1 }
        }
        RowLayout {
            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 12
            Rectangle {
                visible: !window.phone
                Layout.preferredWidth: window.narrow ? 68 : 224; Layout.fillHeight: true; radius: Theme.r(24); color: Theme.panel
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 12; spacing: 6
                    ActionButton { text: window.narrow ? "" : "Home"; symbol: "home"; hint: "Home (Ctrl+1)"; Layout.fillWidth: true; selected: window.activePage===0 && music.mode===0; onClicked: window.navigate(0) }
                    ActionButton { text: window.narrow ? "" : "Search"; symbol: "search"; hint: "Search (Ctrl+K)"; Layout.fillWidth: true; selected: window.activePage===0 && music.mode===1; onClicked: {window.navigate(1);search.forceActiveFocus()} }
                    Rectangle { Layout.fillWidth: true; Layout.topMargin: 14; Layout.bottomMargin: 10; height: 1; color: Theme.outline; opacity: 0.6 }
                    RowLayout {
                        visible: !window.narrow; Layout.fillWidth: true; Layout.bottomMargin: 6
                        Label { text: "YOUR LIBRARY"; font.pixelSize: Theme.fs(10); font.letterSpacing: 1.4; color: Theme.muted; Layout.fillWidth: true }
                        ActionButton { symbol: "refresh"; compact: true; hint: "Refresh playlists"; enabled: auth.connected&&!spotify.busy; onClicked: window.navigate(3) }
                    }
                    ActionButton { text: window.narrow ? "" : "Liked songs"; symbol: "heart"; hint: "Saved songs (Ctrl+2)"; Layout.fillWidth: true; selected: window.activePage===0 && music.mode===2; onClicked: window.navigate(2) }
                    ActionButton { text: window.narrow ? "" : "Playlists"; symbol: "library"; hint: "Playlists"; Layout.fillWidth: true; selected: window.activePage===0 && (music.mode===3||music.mode===4); onClicked: window.navigate(3) }
                    ListView {
                        id: sidebarList
                        visible: !window.narrow; Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 6
                        model: spotify.playlistItems
                        SmoothScroll { flick: sidebarList }
                        delegate: ItemDelegate {
                            required property var modelData
                            width: ListView.view.width; height: 60; padding: 6
                            background: Rectangle { radius: Theme.r(14); color: parent.hovered ? Theme.elevated : "transparent"; border.width: parent.visualFocus?1:0; border.color: Theme.primary }
                            contentItem: RowLayout {
                                spacing: 10
                                CoverArt { source: modelData.cover; Layout.preferredWidth: 42; Layout.preferredHeight: 42 }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 3
                                    Label { text: modelData.name; color: Theme.text; Layout.fillWidth: true; elide: Text.ElideRight; font.pixelSize: Theme.fs(12); textFormat: Text.PlainText }
                                    Label { text: "Playlist · Spotify"; color: Theme.muted; font.pixelSize: Theme.fs(10) }
                                }
                            }
                            onClicked: {window.activePage=0;music.openPlaylist(modelData)}
                            Accessible.name: "Open playlist " + modelData.name
                        }
                        Label { anchors.fill: parent; anchors.margins: 8; anchors.topMargin: 24; visible: spotify.playlistItems.length===0; text: auth.connected ? "No playlists loaded.\nUse the refresh button above." : "Connect Spotify to see\nyour playlists here."; color: Theme.muted; font.pixelSize: Theme.fs(12); wrapMode: Text.WordWrap; lineHeight: 1.4 }
                    }
                    Item { visible: window.narrow; Layout.fillHeight: true }
                    ActionButton { text: window.narrow ? "" : "Settings"; symbol: "settings"; hint: "Settings and about (Ctrl+3)"; selected: window.activePage===1; Layout.fillWidth: true; onClicked: window.activePage=1 }
                    Label { visible: !window.narrow; text: "Independent Spotify companion"; color: Theme.muted; font.pixelSize: Theme.fs(9); Layout.topMargin: 8; Layout.alignment: Qt.AlignHCenter }
                }
            }
            Rectangle {
                Layout.fillWidth: true; Layout.fillHeight: true; radius: Theme.r(window.phone ? 20 : 28); color: Theme.panel; clip: true
                StackLayout {
                    id: pages
                    anchors.fill: parent; anchors.margins: window.phone ? 14 : window.width < 780 ? 18 : 28; currentIndex: window.activePage
                    onCurrentIndexChanged: pageFade.restart()
                    NumberAnimation { id: pageFade; target: pages; property: "opacity"; from: 0.4; to: 1; duration: 200; easing.type: Easing.OutCubic }
                    MusicPage { id: music; mode: initialPage===1 ? 2 : 0; onConfigure: window.activePage=1; onPlayerRequested: nowPlaying.open(); onSongInfoRequested: track=>songInfo.openFor(track); onArtistRequested: artist=>window.openArtist(artist); onSearchRequested: term=>window.searchFor(term); onNavigateRequested: mode=>window.navigate(mode) }
                    SettingsPage { phone: window.phone; }
                }
            }
        }
        PlayerBar { id: playerBar; Layout.fillWidth: true; compact: window.phone; onConfigure: window.activePage=1; onExpandRequested: nowPlaying.open() }
        NavigationBar {
            id: navBar
            visible: window.phone; Layout.fillWidth: true
            current: window.navKey
            onActivated: key => {
                if(key==="home")window.navigate(0)
                else if(key==="search"){window.navigate(1);search.forceActiveFocus()}
                else if(key==="liked")window.navigate(2)
                else if(key==="playlists")window.navigate(3)
                else window.activePage=1
            }
        }
    }
    NowPlaying { id: nowPlaying; bar: playerBar; onInfoRequested: track=>songInfo.openFor(track); onArtistRequested: artist=>window.openArtist(artist) }
    SongInfo { id: songInfo; onSearchRequested: term=>window.searchFor(term); onArtistRequested: artist=>window.openArtist(artist) }
    Rectangle {
        id: snackbar
        property string text: ""
        function show(message) { text=message; opacity=1; hideTimer.restart() }
        parent: Overlay.overlay; z: 10
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height - playerBar.height - (window.phone ? navBar.height + 8 : 0) - height - 36
        width: Math.min(560, parent.width - 48); height: snackLabel.implicitHeight + 28; radius: Theme.r(14)
        color: prefs.dark ? "#e6e0e9" : "#322f35"
        opacity: 0; visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180 } }
        Label { id: snackLabel; anchors.fill: parent; anchors.margins: 14; text: snackbar.text; color: prefs.dark ? "#322f35" : "#f5eff7"; wrapMode: Text.WordWrap; textFormat: Text.PlainText; verticalAlignment: Text.AlignVCenter }
        Timer { id: hideTimer; interval: 4000; onTriggered: snackbar.opacity=0 }
        TapHandler { onTapped: snackbar.opacity=0 }
        Accessible.role: Accessible.AlertMessage; Accessible.name: text
    }
    Shortcut { sequence: "Ctrl+K"; onActivated: search.forceActiveFocus() }
    Shortcut { sequence: "Ctrl+F"; onActivated: { if(window.activePage===0 && (music.mode===2||music.mode===4))music.focusFilter(); else search.forceActiveFocus() } }
    Shortcut { sequence: "Ctrl+1"; onActivated: window.navigate(0) }
    Shortcut { sequence: "Ctrl+2"; onActivated: window.navigate(2) }
    Shortcut { sequence: "Ctrl+3"; onActivated: window.activePage=1 }
    Shortcut { sequence: "Space"; enabled: !window.typing && auth.connected && !!spotify.deviceId; onActivated: spotify.togglePlayback() }
    Shortcut { sequence: "Ctrl+Right"; onActivated: spotify.command("next") }
    Shortcut { sequence: "Ctrl+Left"; onActivated: spotify.command("previous") }
    Shortcut { sequence: "Shift+Right"; enabled: !window.typing; onActivated: spotify.seek(spotify.position()+10000) }
    Shortcut { sequence: "Shift+Left"; enabled: !window.typing; onActivated: spotify.seek(spotify.position()-10000) }
    Shortcut { sequence: "Ctrl+Up"; onActivated: playerBar.changeVolume(10) }
    Shortcut { sequence: "Ctrl+Down"; onActivated: playerBar.changeVolume(-10) }
    Shortcut { sequence: "Ctrl+M"; onActivated: playerBar.toggleMute() }
    Shortcut { sequence: "Ctrl+S"; onActivated: spotify.setShuffle(!spotify.playback.shuffle) }
    Shortcut { sequence: "Ctrl+R"; onActivated: playerBar.cycleRepeat() }
    Shortcut { sequence: "Ctrl+D"; onActivated: playerBar.openDevices() }
    Shortcut { sequence: "Ctrl+P"; onActivated: nowPlaying.opened ? nowPlaying.close() : nowPlaying.open() }
}
