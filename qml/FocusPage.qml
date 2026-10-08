import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import M3Shapes
ScrollView {
    id: page
    signal chooseMusic()
    clip: true; contentWidth: availableWidth
    ColumnLayout {
        width: page.availableWidth; spacing: 14
        Label { text: "Focus"; font.pixelSize: page.width < 800 ? 32 : 40; font.bold: true; lineHeight: 1.1; Layout.fillWidth: true }
        Label { text: "Pick a length and start the timer. It does not touch your music."; opacity: 0.7; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        GridLayout {
            columns: page.width > 850 ? 2 : 1; Layout.fillWidth: true; columnSpacing: 20; rowSpacing: 20
            Surface {
                Layout.fillWidth: true; Layout.preferredWidth: 580; Layout.minimumHeight: 380; Layout.alignment: Qt.AlignTop
                ColumnLayout {
                    anchors.fill: parent; spacing: 14
                    RowLayout {
                        Label { text: "YOUR FOCUS SESSION"; font.letterSpacing: 2; font.pixelSize: 12; opacity: 0.7 }
                        Item { Layout.fillWidth: true }
                        Label { text: focusSession.running ? "In progress" : focusSession.finished ? "Done" : "At your own pace"; font.pixelSize: 12 }
                    }
                    Item {
                        Layout.fillWidth: true; Layout.preferredHeight: 185
                        Rectangle {
                            anchors.centerIn: parent; width: 185; height: 185; radius: 93
                            visible: GraphicsInfo.api === GraphicsInfo.Software
                            color: prefs.dark ? "#393145" : "#e8def5"
                        }
                        MaterialShape {
                            visible: GraphicsInfo.api !== GraphicsInfo.Software
                            anchors.centerIn: parent; width: 190; height: 185
                            shape: prefs.mood === "Calm" ? MaterialShape.Cookie6Sided : prefs.mood === "Bright" ? MaterialShape.Sunny : MaterialShape.Clover4Leaf
                            color: prefs.dark ? "#393145" : "#e8def5"
                            animationDuration: 0
                        }
                        Column {
                            anchors.centerIn: parent; spacing: 4
                            Label {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Math.floor(focusSession.remaining / 60).toString().padStart(2,"0") + ":" + (focusSession.remaining % 60).toString().padStart(2,"0")
                                font.pixelSize: 48; font.weight: Font.Medium
                                Accessible.name: "Remaining focus time " + text
                            }
                            Label { anchors.horizontalCenter: parent.horizontalCenter; text: focusSession.finished ? "Time is up" : "remaining"; opacity: 0.75 }
                        }
                    }
                    ProgressBar { Layout.fillWidth: true; value: 1 - focusSession.remaining / focusSession.total; Accessible.name: "Focus session progress" }
                    Flow {
                        Layout.fillWidth: true; spacing: 8
                        Button { text: focusSession.running ? "Pause focus" : focusSession.remaining < focusSession.total && !focusSession.finished ? "Continue" : "Start focus"; highlighted: true
                            background: Rectangle { implicitWidth: 140; implicitHeight: 42; radius: 21; color: parent.enabled ? (prefs.dark ? "#c9b7fa" : "#695092") : (prefs.dark ? "#48434f" : "#ded9e3"); border.width: parent.visualFocus ? 2 : 0; border.color: prefs.dark ? "#ffffff" : "#251a36" }
                            contentItem: Text { text: parent.text; font: parent.font; color: prefs.dark ? "#251a36" : "#ffffff"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
 onClicked: { if(focusSession.running) focusSession.pause(); else if(focusSession.remaining < focusSession.total && !focusSession.finished) focusSession.resume(); else focusSession.start(prefs.minutes) } }
                        Button { text: "Reset"; flat: true; onClicked: focusSession.reset() }
                    }
                    Label { text: "The timer does not control music and makes no sound when it ends."; font.pixelSize: 12; opacity: 0.65; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                }
            }
            Surface {
                Layout.fillWidth: true; Layout.preferredWidth: 350; Layout.alignment: Qt.AlignTop
                ColumnLayout {
                    anchors.fill: parent; spacing: 14
                    Label { text: "Mood"; font.pixelSize: 23; font.bold: true }
                    Label { text: "A mood for your workspace. No analysis or recommendations based on your music."; wrapMode: Text.WordWrap; opacity: 0.7; Layout.fillWidth: true }
                    Repeater {
                        model: [{name:"Calm",detail:"Slow down and stay with one task"},{name:"Bright",detail:"Fresh attention for a new idea"},{name:"Space",detail:"Think freely, without hurry"}]
                        delegate: RadioButton {
                            required property var modelData
                            implicitHeight: 44
                            text: modelData.name
                            checked: prefs.mood === modelData.name; Layout.fillWidth: true
                            onClicked: prefs.mood = modelData.name
                            ToolTip.visible: hovered
                            ToolTip.text: modelData.detail
                            Accessible.description: modelData.detail
                            font.pixelSize: 15
                        }
                    }
                    Label { text: "Time for yourself"; font.bold: true }
                    RowLayout {
                        SpinBox { from: 5; to: 120; stepSize: 5; value: prefs.minutes; onValueModified: prefs.minutes = value; Accessible.name: "Session length in minutes" }
                        Label { text: "minutes"; opacity: 0.7 }
                    }
                    Label { text: "A new length applies from your next session."; font.pixelSize: 12; wrapMode: Text.WordWrap; opacity: 0.65; Layout.fillWidth: true }
                    Button { text: "Back to music  →"; onClicked: page.chooseMusic(); Layout.fillWidth: true }
                }
            }
        }
    }
}
