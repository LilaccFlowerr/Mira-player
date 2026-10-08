import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
Button {
    id: control
    property string symbol: ""
    property bool filled: false
    property bool tonal: false
    property bool selected: false
    property bool compact: false
    property color ink: filled ? Theme.onPrimary : selected ? Theme.primary : Theme.text
    property string hint: text
    implicitHeight: compact ? 36 : 44
    implicitWidth: text.length ? Math.ceil(labelMetric.advanceWidth) + (symbol.length ? 29 : 0) + 32 : implicitHeight
    TextMetrics { id: labelMetric; text: control.text; font: control.font }
    topInset: 0; bottomInset: 0; leftInset: 0; rightInset: 0
    leftPadding: text.length ? 16 : 10; rightPadding: text.length ? 16 : 10; topPadding: 10; bottomPadding: 10
    hoverEnabled: true
    opacity: enabled ? 1 : 0.38
    scale: down ? 0.96 : 1
    Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
    background: Rectangle {
        radius: control.down ? 12 : height / 2
        color: control.filled ? Theme.primary : control.selected ? Theme.container : control.hovered ? Theme.hover : control.tonal ? Theme.elevated : "transparent"
        border.width: control.activeFocus ? 2 : 0; border.color: Theme.primary
        Behavior on color { ColorAnimation { duration: 160 } }
        Behavior on radius { NumberAnimation { duration: 160 } }
    }
    contentItem: Item {
        Icon {
            visible: control.symbol !== ""; name: control.symbol; color: control.ink
            width: 20; height: 20; anchors.verticalCenter: parent.verticalCenter
            x: control.text.length ? 0 : (parent.width-width)/2
        }
        Text {
            visible: control.text.length > 0; text: control.text; color: control.ink; font: control.font
            anchors.fill: parent; anchors.leftMargin: control.symbol.length ? 29 : 0
            elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter
        }
    }
    Accessible.name: hint
    ToolTip.visible: hovered && hint.length > 0 && text.length === 0
    ToolTip.text: hint
    ToolTip.delay: 650
}
