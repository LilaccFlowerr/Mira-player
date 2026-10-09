# Local verification — 2026-10-08

Actually produced:

- `build/mira`: Linux x86_64 Release binary, GCC 16.2.1, Qt 6.11.2.
- `dist/mira-0.4.0-Linux.rpm`: native Fedora/RPM package with launcher, own icon, AppStream metadata, documentation and licences.
- `dist/mira-0.4.0-source.tar.gz`: own code plus vendored M3Shapes source and build configuration.

Performed: CMake configuration, C++/QML compilation, app start-up, screenshots through the real Qt interface with software rendering, dark/light and compact size, shared-library check, RPM contents/dependencies, desktop-file validator and JSON/YAML syntax check. No test suites run. Hardware rendering could not be confirmed in this headless environment; the interface has its own radially drawn shapes as a software fallback for the M3Shape decoration. The M3Shapes sources were compiled successfully.

AppStream still reports a missing homepage (there is no public project URL yet). A URL is deliberately not invented; fill it in before a public release. No functional QML start-up errors observed. The .desktop validator passes.

The sandbox has a read-only ccache/var/tmp environment. Used for the local build: `CCACHE_DISABLE=1`; for packaging: `cpack --config build/CPackConfig.cmake -D 'CPACK_RPM_SPEC_MORE_DEFINE=%define _tmppath /tmp' -B dist`. These are environment workarounds, not requirements on normal native machines.

Not verified live: Spotify OAuth/API with user credentials, a secure keyring round trip with a real token, Windows/macOS compilation and installers, signing/notarisation. The native CI jobs and scripts exist but were not run here. See RELEASE.md and SOURCES.md for the remaining distribution conditions.

Optional local UI preview without a test framework:

```sh
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software XDG_CONFIG_HOME=/tmp/mira-preview ./scripts/run-local.sh --capture /tmp/mira.png --page 0
```

Use `--compact` for 640×680, `--page 1` for the library and `--page 2` for settings. Use an empty configuration directory and no Spotify credentials for public screenshots.

## Revision 0.2

The music interface was rebuilt around a sidebar, global search bar, playlist cards, track lists and a fixed player. Focus moved to an optional pop-up. Own Canvas icons, M3Shapes with software fallback, three tonal accent palettes, hover/press transitions and light/dark. Caelestia was used only as a visual reference.

The revised app was recompiled and started as a real QML app. Home (dark, 1320×860), library (light, 640×680) and settings were checked visually. No test suites or live Spotify account actions were run. Covers and track lists use API data; no fabricated Spotify results were added to fill screenshots.

## Revision 0.3 — Web Playback SDK

Qt WebEngine/Core/Quick, WebChannel and Positioning were added. The C++ audio component uses a temporary browser profile and the official SDK. New SDK scopes, local device selection, direct SDK control, logout teardown and a built-in Widevine/AAC diagnosis were implemented. Windows/macOS/Linux CI dependencies were updated.

The 0.3 sources were compiled locally. The real QML interface was started again and checked visually on Home and Settings. The WebEngine diagnosis was actually run without credentials or an SDK network request and reported: **protected audio not available**. Fedora's Qt configuration lists proprietary codecs as enabled; no CDM was found in the standard locations checked. So **no audible Spotify playback has been verified**. A successful compile does not confirm Spotify/Qt browser compatibility.

System-wide installation of the extra Qt packages required a sudo password. Official Fedora x86_64 RPMs were therefore downloaded and unpacked locally under `/tmp/luwte-qt-webengine`; the system installation stayed intact. `scripts/run-local.sh` uses the matching libraries, helper and resources from this CMake configuration. For permanent use install the requirements from the README. Widevine was not downloaded or bundled; Chromium sandboxing was not disabled.

## Revision 0.4 — player, MPRIS and English

- Wavy Material 3 Expressive progress line with click/drag/keyboard seeking; shuffle, repeat, mute and an inline volume slider; transfer of playback when choosing another device; now-playing highlight, window title, copy-link menu item, snackbar feedback, remembered window size, optional automatic start of the built-in player and keyboard shortcuts.
- Playback requests no longer share the page-loading lock, so controls stay usable while lists load and periodic refreshes no longer rebuild visible lists. Remote playback refreshes at the end of each track.
- MPRIS 2.2 (`org.mpris.MediaPlayer2.mira`) on Linux via Qt DBus.
- The whole interface, all messages and the documentation are now in English. Stored Dutch mood names from earlier builds are mapped to the English ones.

Verified here: the 0.4 sources compile without warnings from the project code; the real app starts offscreen without QML errors; Home (dark), library (light, compact) and settings (compact) were captured again for `docs/screenshots/`. The wavy progress component was rendered on its own in a QML harness (playing, paused, focused with thumb, empty). With the app running on the real session bus, `busctl` showed the MPRIS service with Identity `Mira`, DesktopEntry `io.github.mira`, PlaybackStatus `Stopped`, NoTrack metadata, and accepted `PlayPause` and a `Volume` write (both no-ops without a Spotify connection).

Not verified: MPRIS metadata/controls during real playback, seeking/shuffle/repeat/transfer against the live Spotify API, and the media widget in an actual KDE/GNOME desktop, because no Spotify credentials or audible playback were available. Windows SMTC and macOS Now Playing are not implemented.

## Rename to Mira (0.4.0)

The app was renamed from "Luwte" to **Mira**: display name, binary `mira`, app id `io.github.mira`, desktop file, AppStream metadata, MPRIS bus name `org.mpris.MediaPlayer2.mira`, QML module, package names and a new icon. On first start Mira copies settings from the old `Luwte` QSettings location when it has none of its own (verified with an isolated config directory: theme, accent and Client ID carried over). On first read it also moves a refresh token stored under the old keyring id `io.github.luwte` to `io.github.mira`; this keyring move was not exercised with a real token here. The RPM declares `Obsoletes: luwte`, so installing it replaces an installed Luwte package. Earlier artefacts in `dist/` keep their old `luwte-*` names.

## Revision 0.4.1 — liked songs and automatic device

Liked songs is pinned first on Home, loads 50 per page and has Play, Shuffle and a local filter (Ctrl+F, also in playlists). Starting a track from a list now keeps playing: playlists use the playlist context + offset, Liked songs uses the `spotify:user:<id>:collection` context + offset (user id from `/me`, memory only; falls back to the loaded songs if Spotify refuses the context), search results use `uris` + offset. The built-in player starts automatically by default and, once ready, becomes the active Spotify device through a paused transfer when nothing is playing elsewhere. Player controls (pause, skip, seek, volume, shuffle, repeat) now target the device that is actually playing rather than the one selected for new playback. Verified: compile and offscreen start on the Liked songs page. Not verified against the live Spotify API.

## Revision 0.4.2 — icon

New app icon: a CAVA-style audio visualiser (nine bottom-aligned bars) in off-white on a neutral charcoal rounded square. Original drawing; generated as SVG and exported to PNG, ICO and ICNS. Checked at 512 px and 64 px.

## Revision 0.4.3 — focus rings

Buttons, cards and track rows show their focus ring only for keyboard navigation (`visualFocus`), not after a mouse click, and `ActionButton` no longer takes focus on click (`focusPolicy: Qt.TabFocus`), so Space keeps toggling playback after clicking a button. Verified: compile and offscreen start.
Playlist covers from `*.spotifycdn.com` (uploaded covers, mosaics, mixes, blends) were rejected by the image host check and fell back to a shape; that host is now allowed alongside `*.scdn.co`. An open playlist without any cover shows a 2×2 mosaic of its first four album covers; the Material shape remains the fallback when there is no art at all. Not verified against live Spotify data.
The indeterminate loading bar on the music page is replaced by a Material 3 Expressive loading indicator that morphs through 17 MaterialShapes (adapted from the MIT-licensed Nebula shell by the same author; Canvas shapes in software rendering). The morph itself could not be viewed here because this environment has no GPU rendering.

## Revision 0.4.4 — player view and polish

Large "Now playing" view (cover, blurred cover backdrop with GPU rendering, wavy progress, all controls; Ctrl+P, Esc closes). Rounded covers everywhere (MultiEffect mask; square in software rendering) decoded at display size. Fades between pages and views, hover scale on covers, right-click menu on songs with Add to queue (`POST /me/player/queue`) and Search artist. Home shows the current track or a time-of-day greeting; marketing-style copy was replaced with plain labels. Verified: compile, offscreen start of all pages, and an offscreen capture of the player view (software rendering, so without blur and rounded masks). Not verified against live Spotify.

## Revision 0.5.0 — Android basis and phone layout

- Android build (arm64-v8a, Qt 6.8.3, NDK r26b) in the GitHub workflow: WebEngine, the Web Playback SDK and MPRIS are left out (`src/WebPlaybackStub.cpp` explains that playback goes through the Spotify app), OpenSSL comes from KDAB's pinned android_openssl package, tokens are stored in the app's private data directory (Android Keystore is a follow-up), and the APK is zipaligned and signed with `apksigner`, using the `ANDROID_KEYSTORE_BASE64`/`ANDROID_KEYSTORE_PASSWORD` secrets when set and a throwaway key otherwise. The workflow fails if the generated manifest lacks the native library name. Sign-in reuses the loopback redirect; Android suspends the app while the browser is in front, so the user switches back to Mira to finish.
- Phone layout (width under 600 px, always on Android): bottom navigation bar, compact player row with a thin wavy progress line that opens the large player view, smaller margins and hero, two-column grids, filter field on its own row, slimmer track rows, Session timer button in Settings, and the Android back button steps back through views before closing the app. `--phone` opens a 412×892 window for previews.
- Verified here: desktop compile and offscreen start; phone-size previews of Home, Liked songs, Settings and the large player view. Not verified: the Android build itself (no Android SDK/NDK in this environment; it runs in GitHub Actions), and anything on a real phone.

## Revision 0.5.1 — play on the phone

On Android Mira selects the Spotify app on the phone (device type `Smartphone`) by default and never falls back to a laptop or speaker on its own. Without such a device, Play opens the Spotify app (`spotify:` URL) and keeps the request for up to a minute; when Mira becomes active again it refreshes the devices and starts the request on the phone. The device picker gets an "Open Spotify on this phone" button. The Android-only code paths were syntax-checked locally against the desktop Qt headers; not verified on a phone. True background playback without switching apps needs Spotify's App Remote SDK (next step).
Also in 0.5.1: Android's status and navigation bars take the app's background colour (light or dark icons to match) through a small JNI helper (`src/SystemBars.cpp`, no-op on desktop) instead of Qt's default blue; the device picker becomes a full-width bottom sheet on phones; `--size WxH` opens any window size for previews. Layout checked at 360×780 (Home, Liked songs, Settings, session timer, device picker). The JNI code could not be compiled here (no Android headers) and is untested on a phone.

## Revision 0.5.2 — phone layout fixes

Compact player bar: 90 px high with the wavy line below the cover and title instead of overlapping them. Home: playlist cards use uniform column widths and top alignment, and the title no longer widens its column (long names elide instead of overlapping the neighbour). Large player view: the volume row fills the width instead of a fixed 220 px, so nothing overflows or shifts right on a phone; smaller title and spacing under 600 px. Search field text is vertically centred; Android uses Roboto so system font fallback covers emoji and CJK. Not rendered or tested here (no Qt in this environment); check on the phone.

## Revision 0.5.3 — tap to play

Phone track lists: one tap on a song plays it, the three-dots button (or a long press on the row) opens the menu, anchored under the button; the dots button is wider for easier tapping. Desktop keeps double click to play. Not rendered or tested here (no Qt in this environment); check on the phone.
