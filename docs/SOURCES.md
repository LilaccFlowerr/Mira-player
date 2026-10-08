# Official documentation reviewed 2026-10-08

Implementation decisions use current endpoint references. The February migration tutorial's JSON library example conflicts with the current endpoint reference: this app follows the reference and sends `uris` as a query parameter.

- Policy: https://developer.spotify.com/policy — independent value, no profiles or derived metrics, disconnect/delete, attribution. Logo prohibition in the project request conflicts with Spotify's required icon/logo attribution. Textual attribution and links are implemented; **this is not a claim of Spotify policy approval and public distribution requires resolving this conflict with Spotify**.
- Design: https://developer.spotify.com/documentation/design — metadata links, unmodified artwork, action restrictions.
- PKCE: https://developer.spotify.com/documentation/web-api/tutorials/code-pkce-flow
- Redirect URI: https://developer.spotify.com/documentation/web-api/concepts/redirect_uri
- Scopes: https://developer.spotify.com/documentation/web-api/concepts/scopes
- February migration: https://developer.spotify.com/documentation/web-api/tutorials/february-2026-migration-guide
- July update (takes precedence on app limits): https://developer.spotify.com/documentation/web-api/references/changes/july-2026 — up to 25 Client IDs, shared developer-account quotas, QUOTA_EXCEEDED.
- Development access: https://developer.spotify.com/documentation/web-api/concepts/quota-modes — Premium owner, authorized-user restrictions, new apps restricted endpoints. Access can differ per developer app.
- Search: https://developer.spotify.com/documentation/web-api/reference/search — at most 10 results per request in new development mode.
- Saved tracks: https://developer.spotify.com/documentation/web-api/reference/get-users-saved-tracks
- Library writes: https://developer.spotify.com/documentation/web-api/reference/save-library-items
- Playlists: https://developer.spotify.com/documentation/web-api/reference/get-a-list-of-current-users-playlists
- Playlist contents: https://developer.spotify.com/documentation/web-api/reference/get-playlists-items — `/items`, ownership/collaboration restrictions.
- Playback: https://developer.spotify.com/documentation/web-api/reference/start-a-users-playback — Premium, existing devices; API does not supply audio. As of 0.3, in-app audio uses the Web Playback SDK in Qt WebEngine; see PLAYBACK.md.
- Qt licensing: https://doc.qt.io/qt-6/licensing.html and https://www.qt.io/development/open-source-lgpl-obligations
- M3Shapes: https://github.com/soramanew/m3shapes ; source/license checked at the pinned commit in THIRD_PARTY_NOTICES.md. Upstream requires Qt 6.8 and C++20, matching this project's minimum; native compilation verifies local compatibility.

## Visual revision 0.2

- Caelestia Shell: https://github.com/caelestia-dots/shell and https://caelestiashell.com — reviewed as a visual reference for tonal panels, rounded components and compact media controls. GPL-3.0; no code or assets copied. All new QML, vector icons and software shapes are original implementations.
- Device volume: https://developer.spotify.com/documentation/web-api/reference/set-volume-for-users-playback — uses the existing playback write scope, only when supports_volume is set.
- The interface is now music-focused. This is not a claim of permission to replace Spotify's core experience; Developer Policy III.11 and the earlier attribution issue remain relevant before distribution.

## Built-in playback (0.3, checked 8 October 2026)

See [PLAYBACK.md](PLAYBACK.md) for current official SDK, browser and Qt sources. `streaming`, `user-read-email` and `user-read-private` were added following Spotify's SDK how-to. Widevine is not shipped with Qt. Qt WebEngine is not named explicitly by Spotify as a browser; compatibility is not guaranteed.

## Player controls and desktop integration (0.4)

- Seek: https://developer.spotify.com/documentation/web-api/reference/seek-to-position-in-currently-playing-track ; built-in player: `Spotify.Player#seek` in the SDK reference.
- Shuffle: https://developer.spotify.com/documentation/web-api/reference/toggle-shuffle-for-users-playback ; repeat: https://developer.spotify.com/documentation/web-api/reference/set-repeat-mode-on-users-playback ; both use `user-modify-playback-state` and are also used for the built-in player's device.
- Transfer playback: https://developer.spotify.com/documentation/web-api/reference/transfer-a-users-playback
- MPRIS D-Bus Interface Specification 2.2: https://specifications.freedesktop.org/mpris-spec/latest/ — root and Player interfaces; no TrackList or Playlists interface.
- Wavy progress: visual behaviour follows the Material 3 Expressive progress indicator guidance (https://m3.material.io/components/progress-indicators); the drawing is an original Canvas implementation.
