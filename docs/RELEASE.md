# Releases

Native builds: Windows on windows-2022 (MSVC), macOS on macos-14 (Clang), RPM in a Fedora container on a Linux runner. The workflow runs manually; it uploads CI artefacts and does not publish a GitHub Release. Version/name: `cmake/AppIdentity.cmake`. No cross-compilation, no test suites.

## Unsigned development builds

```sh
cmake --preset release
cmake --build --preset release --parallel 2
cpack --config build/CPackConfig.cmake -B dist
```

Windows requires NSIS on PATH; Qt's deploy script calls windeployqt with the QML imports and bundles Qt/plug-ins and the MSVC runtime. CPack produces an .exe installer. macOS uses macdeployqt via Qt's deploy script, bundles the QML/Qt frameworks into mira.app and creates a DragNDrop .dmg. `cmake --install build --prefix stage` produces the standalone .app. Linux CPack/RPM uses the shared distribution Qt; Qt is not copied into the RPM. RPM auto-requires and explicit Qt/libsecret requirements select suitable system packages (Qt DBus, used for MPRIS, is part of `qt6-qtbase`). An RPM built on Fedora 44 is not automatically compatible with older RHEL/SUSE versions; build natively against their suitable Qt >=6.8 repositories.

## Configurable CI secrets

Windows: `WINDOWS_PFX_BASE64`, `WINDOWS_PFX_PASSWORD`. An imported code-signing certificate signs the program before packaging and the NSIS installer afterwards with SHA-256 and a timestamp. Without both secrets you get unsigned development builds. Never commit certificates.

macOS: `MACOS_P12_BASE64`, `MACOS_P12_PASSWORD`, `MACOS_SIGN_IDENTITY` (Developer ID Application), `APPLE_ID`, `APPLE_APP_PASSWORD`, `APPLE_TEAM_ID`. The job uses a temporary keychain, macdeployqt signing with hardened runtime, notarises the app as a zip and the dmg, and staples both. Without signing secrets it stays an unsigned development build; without notarisation secrets nothing is notarised. Gatekeeper/SmartScreen may block unsigned builds. Use them only as deliberate local development artefacts. A certified Developer ID is required for public macOS distribution.

## Licences and publication

Use shared Qt libraries and keep them replaceable/relinkable; do not prohibit reverse engineering for debugging modified libraries. MIT code and the full M3Shapes sources are in this repository. Ship these sources, the CMake/build instructions, notices and LGPL/GPL texts alongside the binary. Collect all Qt third-party notices from the distribution actually used. The Windows/macOS job archives Qt's licence directory and downloads the complete corresponding Qt source (6.8.3) next to the installer. If the Qt version changes, the source URL and version must change together. On Linux the distribution repositories provide the shared Qt packages and source packages; do not silently bundle them into the RPM.

A release owner checks the artefacts, platform start-up, OAuth with their own test account, keyring storage/removal, devices, 401/403/429, accessibility, MPRIS behaviour in at least one desktop (KDE or GNOME) and signing before any public release. Also resolve the documented Spotify attribution conflict. The presence of a CI configuration does not prove that those native jobs have already run successfully.

## WebEngine from 0.3

All native jobs also install Qt WebEngine, WebChannel and their Positioning dependency. The Qt deploy tools must bundle `QtWebEngineProcess`, the Chromium resources/locales and shared libraries. Verify their presence and that the audio engine starts on each runner; a compiled executable alone does not prove this. The Qt source archive and notices now also cover Chromium/WebEngine. Widevine is not in the installers; the user must have a suitable, legitimately installed CDM. Document the codec build used and perform an audible SDK playback check with Premium before distribution.

On macOS, distribution outside the Mac App Store is intended. WebEngine has its own helper processes and specific hardened-runtime entitlements; macdeployqt must sign these helpers correctly too. Verify entitlements/notarisation of the complete package on macOS; that platform check has not been performed here yet.
