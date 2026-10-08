import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
Pane {
    padding: width < 420 ? 16 : 24
    background: Rectangle { radius: 24; color: Theme.elevated; border.color: "transparent" }
}
