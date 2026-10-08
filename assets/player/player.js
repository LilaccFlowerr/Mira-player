/* Tokens live only in callbacks in this off-the-record page. Never log or persist them. */
"use strict";
new QWebChannel(qt.webChannelTransport, channel => {
    const bridge = channel.objects.bridge;
    const pending = new Map();
    let serial = 0;
    let player;
    const report = (event, data = {}) => bridge.report(event, data);
    bridge.tokenReady.connect((id, token) => {
        const callback = pending.get(id);
        pending.delete(id);
        if (callback && token) callback(token);
        else if (callback) report("authentication_error");
    });
    if (!window.isSecureContext || !navigator.requestMediaKeySystemAccess) {
        report("drm");
        return;
    }
    if (document.body.dataset.diagnostic === "yes") {
        navigator.requestMediaKeySystemAccess("com.widevine.alpha", [{
            initDataTypes: ["cenc"],
            audioCapabilities: [{contentType: 'audio/mp4; codecs="mp4a.40.2"'}],
            persistentState: "not-allowed", distinctiveIdentifier: "not-allowed",
            sessionTypes: ["temporary"]
        }]).then(() => report("drm_available")).catch(() => report("drm"));
        return;
    }
    window.onSpotifyWebPlaybackSDKReady = () => {
        player = new Spotify.Player({
            name: document.title + " · This computer",
            volume: 0.5,
            getOAuthToken: callback => {
                const id = ++serial;
                pending.set(id, callback);
                bridge.requestToken(id);
            }
        });
        for (const event of ["initialization_error", "authentication_error", "account_error", "playback_error", "autoplay_failed"])
            player.addListener(event, () => report(event));
        player.addListener("ready", ({device_id}) => report("ready", {device_id}));
        player.addListener("not_ready", () => report("not_ready"));
        player.addListener("player_state_changed", state => {
            if (state) player.getVolume().then(volume => report("state", {...state, volume})).catch(() => report("state", state));
            else report("state", {});
        });
        window.miraControl = (action, value) => {
            let operation;
            if (action === "pause") operation = player.pause();
            else if (action === "resume") operation = player.resume();
            else if (action === "next") operation = player.nextTrack();
            else if (action === "previous") operation = player.previousTrack();
            else if (action === "volume") operation = player.setVolume(value / 100);
            else if (action === "seek") operation = player.seek(value);
            if (operation) operation.then(async () => {
                const state = await player.getCurrentState();
                if (state) report("state", {...state, volume: await player.getVolume()});
            }).catch(() => report("playback_error"));
        };
        player.connect().then(ok => { if (!ok) report("connection_error"); }).catch(() => report("connection_error"));
    };
    const script = document.createElement("script");
    script.src = "https://sdk.scdn.co/spotify-player.js";
    script.onerror = () => report("connection_error");
    document.head.appendChild(script);
    window.addEventListener("pagehide", () => { pending.clear(); if (player) player.disconnect(); });
});
