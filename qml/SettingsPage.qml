import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
ScrollView {
    id: page; clip: true; contentWidth: availableWidth
    ColumnLayout {
        width: page.availableWidth; spacing: 18
        Label { text: "Settings"; font.pixelSize: 30; font.bold: true; Layout.fillWidth: true; wrapMode: Text.WordWrap }
        Surface {
            Layout.fillWidth: true
            ColumnLayout {
                anchors.fill: parent; spacing: 12
                Label { text: "Appearance"; font.pixelSize: 22; font.bold: true; color: Theme.text }
                RowLayout {
                    spacing: 10
                    Repeater {
                        model: ["Lavender", "Sage", "Peach"]
                        delegate: ActionButton {
                            required property int index
                            required property string modelData
                            text: modelData; selected: prefs.accent===index; tonal: true
                            onClicked: prefs.accent=index
                        }
                    }
                }
                ActionButton { text: prefs.dark ? "Light theme" : "Dark theme"; symbol: prefs.dark?"sun":"moon"; tonal: true; onClicked: prefs.dark=!prefs.dark }
            }
        }
        Surface {
            Layout.fillWidth: true
            ColumnLayout {
                anchors.fill: parent; spacing: 12
                Label { text: "Connect Spotify"; font.pixelSize: 22; font.bold: true }
                Label { text: "Create a personal Developer app and register exactly this redirect URI:\nhttp://127.0.0.1:43821/callback"; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                TextField { id: client; text: prefs.clientId; Layout.fillWidth: true; placeholderText: "Spotify Client ID (no client secret)"; enabled: !auth.connected && !auth.busy; selectByMouse: true; Accessible.name: "Spotify Client ID"; onEditingFinished: prefs.clientId = text }
                Label { text: "SPOTIFY_CLIENT_ID takes precedence over this field. The Client ID is public; never enter a client secret."; Layout.fillWidth: true; wrapMode: Text.WordWrap; font.pixelSize: 12; opacity: 0.7 }
                Label { text: auth.status; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                Flow {
                    Layout.fillWidth: true; spacing: 8
                    Button { text: "Connect Spotify"; highlighted: true
                            background: Rectangle { implicitWidth: 140; implicitHeight: 42; radius: 21; color: parent.enabled ? (prefs.dark ? "#c9b7fa" : "#695092") : (prefs.dark ? "#48434f" : "#ded9e3"); border.width: parent.visualFocus ? 2 : 0; border.color: prefs.dark ? "#ffffff" : "#251a36" }
                            contentItem: Text { text: parent.text; font: parent.font; color: prefs.dark ? "#251a36" : "#ffffff"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
 enabled: !auth.connected && !auth.busy; onClicked: { prefs.clientId=client.text; auth.login() } }
                    Button { text: auth.busy ? "Cancel" : "Sign out and clear tokens"; enabled: auth.connected || auth.busy; onClicked: auth.logout() }
                    Button { text: "Developer dashboard ↗"; flat: true; onClicked: Qt.openUrlExternally("https://developer.spotify.com/dashboard") }
                }
                Label { text: "Requires Premium and access for your account in Development Mode. Select Web Playback SDK in your Developer app. The built-in player uses Widevine and suitable audio codecs; start it with the device button at the bottom. Other Spotify devices remain available. Sign in again after updating from 0.2 for the extra SDK scopes."; Layout.fillWidth: true; wrapMode: Text.WordWrap; opacity: 0.7 }
            }
        }
        Surface {
            Layout.fillWidth: true
            ColumnLayout {
                anchors.fill: parent; spacing: 12
                Label { text: "Built-in audio player"; font.pixelSize: 22; font.bold: true }
                Label { text: localPlayer.status; Layout.fillWidth: true; wrapMode: Text.WordWrap; textFormat: Text.PlainText }
                Flow {
                    Layout.fillWidth: true; spacing: 8
                    ActionButton { text: localPlayer.ready ? "Stop player" : "Listen on this computer"; filled: true; enabled: auth.connected && !localPlayer.busy; onClicked: localPlayer.ready ? localPlayer.stop() : localPlayer.start() }
                    ActionButton { text: "Check audio support"; tonal: true; enabled: !localPlayer.busy && !localPlayer.ready; onClicked: localPlayer.diagnose() }
                }
                Switch {
                    text: "Use this computer automatically: start the built-in player after connecting and make it the active Spotify device (unless music is playing elsewhere)"
                    checked: prefs.autoStartPlayer; onToggled: prefs.autoStartPlayer = checked
                    Layout.fillWidth: true
                }
            }
        }
        Surface {
            Layout.fillWidth: true
            ColumnLayout {
                anchors.fill: parent; spacing: 12
                Label { text: "Privacy"; font.pixelSize: 22; font.bold: true }
                Label { text: "Only your theme, accent colour, window size, session length, mood, player start-up choice and Client ID are stored locally as settings. Refresh tokens go to the system keyring. Without a keyring the connection only lasts while the app is open.\n\nSearches and controls go directly to Spotify. Music data stays in memory only temporarily. The built-in Web Playback SDK processes audio and account data through Spotify. The SDK also requires email and profile permission; Mira does not store that data. Your Spotify user id is read into memory only to play your whole Liked songs collection. The browser engine keeps only temporary session data. No analytics, listening history, derived statistics or listening profiles. On Linux the current track is shared with your desktop's media controls (MPRIS) on the local session bus only. The mood choice only changes this workspace.\n\nSigning out also stops the built-in audio and clears local tokens and loaded content. Also revoke access in your Spotify account. Your browser may stay signed in to Spotify."; Layout.fillWidth: true; wrapMode: Text.WordWrap; opacity: 0.85 }
                Flow {
                    Layout.fillWidth: true; spacing: 8
                    Button { text: "Revoke access at Spotify ↗"; onClicked: Qt.openUrlExternally("https://www.spotify.com/account/apps/") }
                    Button { text: "Clear local preferences"; onClicked: { prefs.reset(); focusSession.reset() } }
                }
            }
        }
        Surface {
            Layout.fillWidth: true
            ColumnLayout {
                anchors.fill: parent; spacing: 12
                Label { text: "About " + appName; font.pixelSize: 22; font.bold: true }
                Label { text: "Version " + appVersion + " · MIT\nAn independent music companion with an optional session timer. Not developed, endorsed or sponsored by Spotify. Spotify content is provided by Spotify; all rights remain with their owners.\n\nBuilt with Qt 6 including WebEngine/WebChannel (LGPLv3 and Chromium licences, dynamically linked) and M3Shapes by soramanew (Apache-2.0). Original design and app icon.\n\nThis development build does not use the Spotify logo, by request. The official attribution guidelines do require a logo or icon alongside content. This must be resolved with Spotify before public distribution."; Layout.fillWidth: true; wrapMode: Text.WordWrap; opacity: 0.85 }
                Flow {
                    Layout.fillWidth: true; spacing: 8
                    Button { text: "Spotify Developer Policy ↗"; flat: true; onClicked: Qt.openUrlExternally("https://developer.spotify.com/policy") }
                    Button { text: "Qt licences ↗"; flat: true; onClicked: Qt.openUrlExternally("https://doc.qt.io/qt-6/licensing.html") }
                }
                Label { text: "Keyboard: Tab / Shift+Tab moves between controls; Enter or Space activates them. Space (outside a control) plays or pauses. Ctrl+← / Ctrl+→ previous/next track · Shift+← / Shift+→ seek 10 s · Ctrl+↑ / Ctrl+↓ volume · Ctrl+M mute · Ctrl+S shuffle · Ctrl+R repeat · Ctrl+D devices · Ctrl+P large player · Ctrl+K search (Esc clears) · Ctrl+F filter liked songs/playlist · Ctrl+1 Home · Ctrl+2 Liked songs · Ctrl+3 Settings. With the progress bar focused, ← / → seek 5 s."; Layout.fillWidth: true; wrapMode: Text.WordWrap; font.pixelSize: 12; opacity: 0.65 }
            }
        }
    }
}
