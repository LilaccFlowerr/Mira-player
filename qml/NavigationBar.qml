import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
// Material 3 navigation bar for phone-sized windows: icon in a pill when active, label below.
Rectangle {
    id: root
    property string current: "home"
    signal activated(string key)
    implicitHeight: 72
    radius: 24; color: Theme.panel
    readonly property var items: [
        {key: "home", label: "Home", icon: "home"},
        {key: "search", label: "Search", icon: "search"},
        {key: "liked", label: "Liked", icon: "heart"},
        {key: "playlists", label: "Playlists", icon: "library"},
        {key: "settings", label: "Settings", icon: "settings"}
    ]
    RowLayout {
        anchors.fill: parent; anchors.margins: 6; spacing: 0
        Repeater {
            model: root.items
            delegate: AbstractButton {
                id: item
                required property var modelData
                readonly property bool active: root.current === modelData.key
                Layout.fillWidth: true; Layout.fillHeight: true
                focusPolicy: Qt.TabFocus
                onClicked: root.activated(modelData.key)
                Accessible.name: modelData.label
                contentItem: ColumnLayout {
                    spacing: 4
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: item.active ? 56 : 40; Layout.preferredHeight: 32; radius: 16
                        color: item.active ? Theme.container : item.pressed ? Theme.hover : "transparent"
                        border.width: item.visualFocus ? 2 : 0; border.color: Theme.primary
                        Behavior on Layout.preferredWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 160 } }
                        Icon { anchors.centerIn: parent; width: 22; height: 22; name: item.modelData.icon; color: item.active ? Theme.primary : Theme.muted }
                    }
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: item.modelData.label; font.pixelSize: 11; font.bold: item.active
                        color: item.active ? Theme.text : Theme.muted
                    }
                }
                background: Item {}
            }
        }
    }
}
