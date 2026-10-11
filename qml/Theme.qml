pragma Singleton
import QtQuick
QtObject {
    // Settings: corner roundness (sharp / default / extra round) and text size (small / default / large).
    readonly property real cornerScale: [0.35, 1, 1.4][prefs.roundness]
    readonly property real textScale: [0.9, 1, 1.15][prefs.textSize]
    function r(n) { return Math.round(n * cornerScale) }
    function fs(n) { return Math.round(n * textScale) }
    readonly property bool black: prefs.dark && prefs.trueBlack
    // Every theme: name, swatch and ten colours per mode, in the order
    // base, panel, elevated, hover, text, muted, primary, onPrimary, container, outline.
    readonly property var themes: [
        { name: "Lavender", swatch: "#d0bcff",
          dark: ["#111015","#1b191f","#252229","#302b35","#eee7f0","#a99fad","#d0bcff","#2e223b","#3e3056","#3d3643"],
          light: ["#eee9f1","#faf7fc","#eee8f2","#e4dce9","#211b26","#716675","#6b4ea0","#ffffff","#e8dcfb","#d6cbdc"] },
        { name: "Sage", swatch: "#acd5bd",
          dark: ["#111015","#1b191f","#252229","#302b35","#eee7f0","#a99fad","#acd5bd","#2e223b","#2d4437","#3d3643"],
          light: ["#eee9f1","#faf7fc","#eee8f2","#e4dce9","#211b26","#716675","#34684d","#ffffff","#d6eddd","#d6cbdc"] },
        { name: "Peach", swatch: "#efbaa2",
          dark: ["#111015","#1b191f","#252229","#302b35","#eee7f0","#a99fad","#efbaa2","#2e223b","#4a352b","#3d3643"],
          light: ["#eee9f1","#faf7fc","#eee8f2","#e4dce9","#211b26","#716675","#885239","#ffffff","#f8ded1","#d6cbdc"] },
        { name: "Ocean", swatch: "#9ecbff",
          dark: ["#0e1218","#161b23","#1f2630","#2a3340","#e6edf5","#9aa7b8","#9ecbff","#0a2540","#243b57","#35435a"],
          light: ["#e8eef5","#f6f9fc","#e5ecf4","#d9e3ee","#16202b","#5d6b7c","#2a6aa8","#ffffff","#d3e5f8","#c3d2e2"] },
        { name: "Rose", swatch: "#ffb1c8",
          dark: ["#171014","#21171c","#2d2026","#3a2a32","#f3e6ea","#b79ea7","#ffb1c8","#4a1226","#5a2a3b","#4a343d"],
          light: ["#f6e9ee","#fdf6f8","#f5e6eb","#ecd7de","#2a1a20","#7a5f69","#9c3a5b","#ffffff","#fbd9e3","#e3c9d2"] },
        { name: "Amber", swatch: "#f2c14e",
          dark: ["#16130d","#1f1b13","#2a251a","#363022","#f0e8d6","#b0a68c","#f2c14e","#3b2a00","#4d3d12","#443d2a"],
          light: ["#f3eddc","#fbf8ee","#f1eada","#e7dfc8","#241f12","#74694d","#8a6200","#ffffff","#f6e4b0","#dcd2b4"] },
        { name: "Crimson", swatch: "#ff8a80",
          dark: ["#150e0e","#1f1515","#2b1d1d","#382626","#f2e4e2","#b79c99","#ff8a80","#4a0c08","#5a2320","#4a3330"],
          light: ["#f6e8e6","#fdf5f4","#f4e4e2","#ebd6d3","#2a1716","#7a5d5a","#a52a22","#ffffff","#fbd5d1","#e2c6c3"] },
        { name: "Forest", swatch: "#8fd6a5",
          dark: ["#0e1410","#151d17","#1e2921","#28352c","#e3eee6","#93a898","#8fd6a5","#06301a","#21432c","#32473a"],
          light: ["#e6f0e8","#f5faf6","#e4efe6","#d7e6da","#15201a","#576b5d","#2b7a46","#ffffff","#cfeed8","#c2d6c7"] },
        { name: "Graphite", swatch: "#d4d4d8",
          dark: ["#0f0f10","#18181a","#232326","#2e2e32","#ececec","#a0a0a6","#d4d4d8","#1c1c1f","#38383d","#3a3a3f"],
          light: ["#ececee","#f8f8f9","#ececef","#e0e0e4","#1b1b1d","#6b6b72","#45454c","#ffffff","#dcdce0","#cfcfd4"] }
    ]
    readonly property var colors: themes[Math.min(prefs.accent, themes.length - 1)][prefs.dark ? "dark" : "light"]
    readonly property color base: black ? "#000000" : colors[0]
    readonly property color panel: black ? "#0b0a0c" : colors[1]
    readonly property color elevated: black ? "#17151a" : colors[2]
    readonly property color hover: black ? "#221f26" : colors[3]
    readonly property color text: colors[4]
    readonly property color muted: colors[5]
    readonly property color primary: colors[6]
    readonly property color onPrimary: colors[7]
    readonly property color container: colors[8]
    readonly property color outline: colors[9]
    readonly property color error: prefs.dark ? "#ffb4ab" : "#9c2929"
}
