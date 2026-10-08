# Mira privacy

Mira is a personal, independent desktop app without its own external server, telemetry or analytics. The Web Playback SDK requires the streaming, email and profile scopes. Mira does not store an email address or profile; the SDK processes that data at Spotify.

When you sign in, the system browser opens Spotify. Spotify processes your sign-in under its own privacy terms. Through a temporary loopback listener the app receives only the OAuth code and checks a random state plus PKCE. Access tokens stay in process memory; refresh tokens go to Credential Manager, Keychain or Secret Service. There is no plaintext storage fallback. A missing or locked keyring results in session-only access and a visible message. The Client ID is not a secret.

Searches, requests for your saved tracks/playlists and explicit controls go directly to Spotify over HTTPS. To play your whole Liked songs collection, Mira reads your Spotify user id once per session (via `/me`, covered by the SDK's `user-read-private` scope); it is kept in memory only and nothing else from the profile is used. Album covers are loaded directly from Spotify's CDN. Metadata and images are not cached to disk. There are no recommendation models, listening profiles, derived statistics or exports of Spotify content. Mood and timer are independent of Spotify. Sessions are not logged or stored historically.

QSettings stores the Client ID, theme, accent colour, mood, duration, window size, the built-in player start-up choice and a restore flag. Signing out clears tokens from memory, requests keyring removal, blocks session restore and clears loaded Spotify content. A keyring failure is reported; in that case remove the item with application `io.github.mira` and your Client ID as account yourself. To revoke access completely: https://www.spotify.com/account/apps/ . Browser cookies stay in the browser. Clear local preferences separately in Settings.

Do not put tokens in bug reports, screenshots, network captures or logs. The app does not log tokens, codes or Spotify response bodies. There are no crash uploads. Close the app when you use a shared operating-system account.

While the app window is active, playback state is refreshed automatically at most once every 20 seconds (besides manual actions) and when a track ends; in the background this happens about once a minute, and only while a remote device is playing. On quota errors the app waits. The progress shown is temporary and is not stored as a statistic.

On Linux the current track (title, artists, album, cover URL, Spotify link, position, volume, shuffle/repeat) is published as an MPRIS player on your local D-Bus session bus, so your desktop's media controls can show and control it. Any program running in your desktop session can read that information, as with every other media player; nothing is sent over the network for this.

The optional built-in player uses a temporary loopback web server and an off-the-record browser profile. Only the official SDK receives an access token; never a refresh token. Cookies and browser cache stay temporarily in memory. Signing out stops the audio and destroys this profile. Spotify may process usage data itself through the SDK under its terms. See [PLAYBACK](PLAYBACK.md).
