import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtCore
ApplicationWindow {
    id: window
    width: 1320; height: 860; minimumWidth: 640; minimumHeight: 620
    visible: true
    title: spotify.playback.uri ? spotify.playback.name + " · " + spotify.playback.subtitle + " — " + appName : appName + " — music, your way"
    Material.theme: prefs.dark ? Material.Dark : Material.Light
    Material.accent: Theme.primary; Material.primary: Theme.primary
    Material.foreground: Theme.text; Material.background: Theme.panel
    color: Theme.base
    font.family: Qt.platform.os === "windows" ? "Segoe UI" : "Noto Sans"
    font.pixelSize: 14
    property int activePage: initialPage === 2 ? 1 : 0
    property bool narrow: width < 980
    property bool initialized: false
    property bool devicesRequested: false
    // Space toggles playback unless the user is typing or moved to a control with the keyboard,
    // where Space must keep activating that control. Focus left behind by a mouse click does not count.
    readonly property var focusTarget: window.activeFocusItem
    readonly property bool typing: !!focusTarget && (focusTarget.cursorPosition !== undefined || focusTarget.focusReason === Qt.TabFocusReason || focusTarget.focusReason === Qt.BacktabFocusReason)
    function navigate(mode) { activePage=0; music.mode=mode; if(auth.connected&&!spotify.busy){if(mode===2)spotify.library();if(mode===3)spotify.playlists()} }
    function searchFor(term) { activePage=0; search.text=term; music.searchTerm=term; music.mode=1; if(auth.connected&&!spotify.busy)spotify.search(term) }
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
        anchors.fill: parent; anchors.margins: 14; spacing: 12
        RowLayout {
            Layout.fillWidth: true; Layout.preferredHeight: 56; spacing: 16
            RowLayout {
                Layout.preferredWidth: window.narrow ? 66 : 220; spacing: 10
                Image { source: "qrc:/assets/mira.png"; Layout.preferredWidth: 40; Layout.preferredHeight: 40 }
                Label { visible: !window.narrow; text: appName.toLowerCase(); font.pixelSize: 27; font.bold: true; font.letterSpacing: -1; color: Theme.text }
            }
            Rectangle {
                Layout.fillWidth: true; Layout.maximumWidth: 620; Layout.preferredHeight: 48; radius: 24; color: Theme.elevated
                border.width: search.activeFocus ? 2 : 0; border.color: Theme.primary
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 17; anchors.rightMargin: 10; spacing: 12
                    Icon { name: "search"; color: Theme.muted }
                    TextField {
                        id: search; Layout.fillWidth: true; placeholderText: window.width < 780 ? "Search music" : "What do you want to listen to?"; color: Theme.text; placeholderTextColor: Theme.muted
                        selectByMouse: true; background: Item {} leftPadding: 0; rightPadding: 0
                        onAccepted: {if(text.trim().length)window.searchFor(text.trim())}
                        Keys.onEscapePressed: { if(text.length)text=""; else focus=false }
                        Accessible.name: "Search music on Spotify"
                    }
                    ActionButton { symbol: "close"; compact: true; hint: "Clear search"; visible: search.text.length>0; onClicked: {search.text="";search.forceActiveFocus()} }
                    Label { text: "Ctrl K"; visible: window.width > 1000 && search.text.length===0; color: Theme.muted; font.pixelSize: 11 }
                    ActionButton { symbol: search.text.length ? "arrow" : "search"; compact: true; hint: "Search"; enabled: !spotify.busy; onClicked: {if(search.text.trim().length)window.searchFor(search.text.trim());else{window.navigate(1);search.forceActiveFocus()}} }
                }
            }
            Item { Layout.fillWidth: true; visible: window.width > 1000 }
            ActionButton { symbol: prefs.dark ? "sun" : "moon"; hint: "Light or dark theme"; onClicked: prefs.dark=!prefs.dark }
            ActionButton { text: window.width > 800 ? (auth.connected ? "Connected" : "Connect") : ""; symbol: auth.connected ? "check" : "plus"; tonal: auth.connected; filled: !auth.connected; hint: "Set up the Spotify connection"; onClicked: window.activePage=1 }
        }
        RowLayout {
            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 12
            Rectangle {
                Layout.preferredWidth: window.narrow ? 68 : 224; Layout.fillHeight: true; radius: 24; color: Theme.panel
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 12; spacing: 6
                    ActionButton { text: window.narrow ? "" : "Home"; symbol: "home"; hint: "Home (Ctrl+1)"; Layout.fillWidth: true; selected: window.activePage===0 && music.mode===0; onClicked: window.navigate(0) }
                    ActionButton { text: window.narrow ? "" : "Search"; symbol: "search"; hint: "Search (Ctrl+K)"; Layout.fillWidth: true; selected: window.activePage===0 && music.mode===1; onClicked: {window.navigate(1);search.forceActiveFocus()} }
                    Rectangle { Layout.fillWidth: true; Layout.topMargin: 14; Layout.bottomMargin: 10; height: 1; color: Theme.outline; opacity: 0.6 }
                    RowLayout {
                        visible: !window.narrow; Layout.fillWidth: true; Layout.bottomMargin: 6
                        Label { text: "YOUR LIBRARY"; font.pixelSize: 10; font.letterSpacing: 1.4; color: Theme.muted; Layout.fillWidth: true }
                        ActionButton { symbol: "refresh"; compact: true; hint: "Refresh playlists"; enabled: auth.connected&&!spotify.busy; onClicked: window.navigate(3) }
                    }
                    ActionButton { text: window.narrow ? "" : "Liked songs"; symbol: "heart"; hint: "Saved songs (Ctrl+2)"; Layout.fillWidth: true; selected: window.activePage===0 && music.mode===2; onClicked: window.navigate(2) }
                    ActionButton { text: window.narrow ? "" : "Playlists"; symbol: "library"; hint: "Playlists"; Layout.fillWidth: true; selected: window.activePage===0 && (music.mode===3||music.mode===4); onClicked: window.navigate(3) }
                    ListView {
                        visible: !window.narrow; Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 6
                        model: spotify.playlistItems
                        delegate: ItemDelegate {
                            required property var modelData
                            width: ListView.view.width; height: 60; padding: 6
                            background: Rectangle { radius: 14; color: parent.hovered ? Theme.elevated : "transparent"; border.width: parent.activeFocus?1:0; border.color: Theme.primary }
                            contentItem: RowLayout {
                                spacing: 10
                                CoverArt { source: modelData.cover; Layout.preferredWidth: 42; Layout.preferredHeight: 42 }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 3
                                    Label { text: modelData.name; color: Theme.text; Layout.fillWidth: true; elide: Text.ElideRight; font.pixelSize: 12; textFormat: Text.PlainText }
                                    Label { text: "Playlist · Spotify"; color: Theme.muted; font.pixelSize: 10 }
                                }
                            }
                            onClicked: {window.activePage=0;music.openPlaylist(modelData)}
                            Accessible.name: "Open playlist " + modelData.name
                        }
                        Label { anchors.fill: parent; anchors.margins: 8; anchors.topMargin: 24; visible: spotify.playlistItems.length===0; text: auth.connected ? "Your playlists show up here.\nRefresh your library." : "All your playlists,\nin one place.\n\nConnect Spotify to\nsee them here."; color: Theme.muted; font.pixelSize: 12; wrapMode: Text.WordWrap; lineHeight: 1.4 }
                    }
                    Item { visible: window.narrow; Layout.fillHeight: true }
                    ActionButton { text: window.narrow ? "" : "Session timer"; symbol: "timer"; hint: "Optional session timer"; Layout.fillWidth: true; onClicked: timerPopup.open() }
                    ActionButton { text: window.narrow ? "" : "Settings"; symbol: "settings"; hint: "Settings and about (Ctrl+3)"; selected: window.activePage===1; Layout.fillWidth: true; onClicked: window.activePage=1 }
                    Label { visible: !window.narrow; text: "Independent Spotify companion"; color: Theme.muted; font.pixelSize: 9; Layout.topMargin: 8; Layout.alignment: Qt.AlignHCenter }
                }
            }
            Rectangle {
                Layout.fillWidth: true; Layout.fillHeight: true; radius: 28; color: Theme.panel; clip: true
                StackLayout {
                    anchors.fill: parent; anchors.margins: window.width < 780 ? 18 : 28; currentIndex: window.activePage
                    MusicPage { id: music; mode: initialPage===1 ? 2 : 0; onConfigure: window.activePage=1; onSearchRequested: term=>window.searchFor(term); onNavigateRequested: mode=>window.navigate(mode) }
                    SettingsPage { }
                }
            }
        }
        PlayerBar { id: playerBar; Layout.fillWidth: true; onConfigure: window.activePage=1 }
    }
    Rectangle {
        id: snackbar
        property string text: ""
        function show(message) { text=message; opacity=1; hideTimer.restart() }
        parent: Overlay.overlay; z: 10
        anchors.horizontalCenter: parent.horizontalCenter; y: parent.height - playerBar.height - height - 36
        width: Math.min(560, parent.width - 48); height: snackLabel.implicitHeight + 28; radius: 14
        color: prefs.dark ? "#e6e0e9" : "#322f35"
        opacity: 0; visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180 } }
        Label { id: snackLabel; anchors.fill: parent; anchors.margins: 14; text: snackbar.text; color: prefs.dark ? "#322f35" : "#f5eff7"; wrapMode: Text.WordWrap; textFormat: Text.PlainText; verticalAlignment: Text.AlignVCenter }
        Timer { id: hideTimer; interval: 4000; onTriggered: snackbar.opacity=0 }
        TapHandler { onTapped: snackbar.opacity=0 }
        Accessible.role: Accessible.AlertMessage; Accessible.name: text
    }
    Popup {
        id: timerPopup; parent: Overlay.overlay; anchors.centerIn: parent
        width: Math.min(920,parent.width-32); height: Math.min(700,parent.height-32); modal: true; padding: 24
        background: Rectangle { radius: 28; color: Theme.panel; border.color: Theme.outline }
        ColumnLayout {
            anchors.fill: parent
            RowLayout { Layout.fillWidth: true; Label { text: "Session timer"; font.pixelSize: 20; color: Theme.text; Layout.fillWidth: true } ActionButton { symbol: "close"; hint: "Close"; onClicked: timerPopup.close() } }
            FocusPage { Layout.fillWidth: true; Layout.fillHeight: true; onChooseMusic: {timerPopup.close();window.navigate(0)} }
        }
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
}
