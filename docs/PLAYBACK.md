# Audio in Mira (0.3+)

Mira contains the official Spotify Web Playback SDK in a separate Qt WebEngine page. The SDK creates a local Spotify Connect device and decodes the protected audio stream inside the app. No other Spotify app needs to be open. The Web API starts tracks/playlists and controls remote devices; it does not supply audio itself. Local pause, resume, previous, next, seek and volume use the SDK directly; shuffle and repeat go through the Web API for every device.

## Getting started

1. Select **Web Playback SDK** in your own Spotify Developer app. Keep the same Client ID and the OAuth redirect `http://127.0.0.1:43821/callback`.
2. Use Spotify Premium and an account that has access to your Developer app.
3. After updating from 0.2, sign out and connect again. Besides the existing library and playback scopes the SDK requests `streaming`, `user-read-email` and `user-read-private`. Ticking API products in the dashboard does not replace this OAuth consent.
4. Choose **Listen on this computer** with the device button at the bottom, or use the same button in Settings. By default Mira starts the built-in player automatically after connecting (switch this off in Settings). As soon as Spotify reports the player as ready, Mira selects the local device and, if nothing is playing on another device, transfers your Spotify session to it (paused) so this computer becomes the active device. Music that is already playing elsewhere is never taken over automatically; you get a short notice instead. Then pick a track or playlist and press Play. Only connecting the player does not interrupt music on another device.
5. Volume, pause, previous, next and seek use the selected device. You can also choose another Spotify Connect device; if music is playing, it moves to the device you choose. Stop the built-in player explicitly or sign out to end local audio.

## Widevine and codecs

The embedded browser must support Encrypted Media Extensions, a compatible **Widevine CDM** and **AAC**. Qt does not ship Widevine. Use a legitimately installed CDM, for example from a supported Chrome installation; compatibility depends on the operating system, architecture and Chromium/CDM version. Mira does not download or distribute a CDM. Do not install arbitrary DRM binaries from unknown sources.

Qt searches standard locations. If automatic detection fails, Qt supports an explicit path:

```sh
# Example: replace this with the actual path to your own installed CDM.
QTWEBENGINE_CHROMIUM_FLAGS='--widevine-path=/absolute/path/libwidevinecdm.so' ./scripts/run-local.sh
```

Windows uses `widevinecdm.dll`, macOS `libwidevinecdm.dylib`; set the same environment variable before starting. Qt WebEngine must be built with proprietary codec support; adding a CDM alone does not fix a missing AAC decoder. The Fedora 44 Qt 6.11.2 build used here lists `webengine_proprietary_codecs` as enabled. Distribution packages and official Qt binaries may differ.

On Linux Mira appends `--disable-features=HardwareMediaKeyHandling,MediaSessionService` to `QTWEBENGINE_CHROMIUM_FLAGS` so the embedded Chromium does not publish a second media player next to Mira's own MPRIS entry. If you already pass your own `--disable-features`, Mira leaves the flags untouched.

In Settings, **Check audio support** verifies that the browser can access Widevine with AAC. This check does not load the Spotify SDK. You can also run it with `./scripts/run-local.sh --audio-check` (an active desktop session is required). A successful check confirms browser capability, not working Spotify account access or an audible stream.

Spotify documents support for regular desktop browsers, not specifically for Qt WebEngine. This integration is therefore experimental until sign-in and audible playback have been verified on the target platform. Mira does not change the browser identity, bypass DRM or disable the Chromium sandbox. When DRM/browser support is unsuitable an error appears; the app does not silently pick another playback device.

## Architecture and privacy

`src/WebPlayback` manages an off-the-record browser profile, a temporary HTTP listener on IPv4 loopback and a restricted WebChannel bridge. The random loopback path serves only built-in HTML/JS; there is no HTTP token endpoint. The profile keeps cookies/cache in memory only. External requests are limited to Spotify domains; navigation to other pages, pop-ups and browser permissions are refused. Autoplay is allowed only for this internal player profile after the user starts the player.

OAuth and token refresh stay in C++. Only short-lived access tokens reach the SDK via WebChannel; no refresh token, client secret or token in QML, HTML, URLs, files or logs. The SDK itself receives the necessary account rights and processes data under Spotify's terms. Signing out destroys the player page and the temporary profile, stops audio and removes the local device. The native interface receives only current playback metadata, without history or derived profiles.

## Sources

- [Spotify Web Playback SDK](https://developer.spotify.com/documentation/web-playback-sdk)
- [SDK reference and error states](https://developer.spotify.com/documentation/web-playback-sdk/reference)
- [Required SDK scopes](https://developer.spotify.com/documentation/web-playback-sdk/howtos/web-app-player)
- [Qt: DRM, Widevine and codecs](https://doc.qt.io/qt-6.8/qtwebengine-features.html)
- [Qt WebEngine platform notes](https://doc.qt.io/qt-6.8/qtwebengine-platform-notes.html)

Access to a Client ID or scopes is not a licence to publish. The existing conditions for independent design, Spotify attribution and non-commercial streaming still apply; see SOURCES and RELEASE.
