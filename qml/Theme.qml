pragma Singleton
import QtQuick
QtObject {
    readonly property color base: prefs.dark ? "#111015" : "#eee9f1"
    readonly property color panel: prefs.dark ? "#1b191f" : "#faf7fc"
    readonly property color elevated: prefs.dark ? "#252229" : "#eee8f2"
    readonly property color hover: prefs.dark ? "#302b35" : "#e4dce9"
    readonly property color text: prefs.dark ? "#eee7f0" : "#211b26"
    readonly property color muted: prefs.dark ? "#a99fad" : "#716675"
    readonly property color primary: prefs.accent === 1 ? (prefs.dark ? "#acd5bd" : "#34684d") : prefs.accent === 2 ? (prefs.dark ? "#efbaa2" : "#885239") : (prefs.dark ? "#d0bcff" : "#6b4ea0")
    readonly property color onPrimary: prefs.dark ? "#2e223b" : "#ffffff"
    readonly property color container: prefs.accent === 1 ? (prefs.dark ? "#2d4437" : "#d6eddd") : prefs.accent === 2 ? (prefs.dark ? "#4a352b" : "#f8ded1") : (prefs.dark ? "#3e3056" : "#e8dcfb")
    readonly property color outline: prefs.dark ? "#3d3643" : "#d6cbdc"
    readonly property color error: prefs.dark ? "#ffb4ab" : "#9c2929"
}
