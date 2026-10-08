#pragma once
#include <QObject>
#include <QNetworkAccessManager>
#include <QJsonObject>
#include <QVariantList>
#include <QElapsedTimer>
#include "OAuth.h"
class SpotifyApi : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool busy READ busy NOTIFY changed)
    Q_PROPERTY(QString message READ message NOTIFY changed)
    Q_PROPERTY(QString state READ state NOTIFY changed)
    // Content has its own signal so playback/status updates never rebuild the visible lists.
    Q_PROPERTY(QVariantList items READ items NOTIFY contentChanged)
    Q_PROPERTY(QVariantList devices READ devices NOTIFY changed)
    Q_PROPERTY(QVariantMap playback READ playback NOTIFY playbackChanged)
    Q_PROPERTY(QVariantList playlistItems READ playlistItems NOTIFY contentChanged)
    Q_PROPERTY(bool hasMore READ hasMore NOTIFY contentChanged)
    Q_PROPERTY(QString collection READ collection NOTIFY contentChanged)
    Q_PROPERTY(QString deviceId READ deviceId WRITE setDeviceId NOTIFY changed)
public:
    explicit SpotifyApi(OAuth *auth,QObject *parent=nullptr);
    bool busy()const{return loading;} QString message()const{return info;} QString state()const{return status;}
    QVariantList playlistItems()const{return playlistRows;}
    QVariantList items()const{return rows;} QVariantList devices()const{return deviceRows;} QVariantMap playback()const{return player;}
    bool hasMore()const{return !next.isEmpty();} QString collection()const{return kind;}
    QString deviceId()const{return selectedDevice;} void setDeviceId(QString id);
    bool connected()const{return auth->connected();}
    // Interpolated playback position in milliseconds, clamped to the track duration.
    Q_INVOKABLE qint64 position()const;
    void prepareLocalPlayback();
    void setLocalDevice(QString id);
    void updateLocalPlayback(QJsonObject state);
    Q_INVOKABLE void search(QString term); Q_INVOKABLE void library(); Q_INVOKABLE void playlists();
    Q_INVOKABLE void playlist(QString id); Q_INVOKABLE void more();
    Q_INVOKABLE void refreshPlayer(bool includeDevices=true);
    Q_INVOKABLE void setVolume(int percent); Q_INVOKABLE void play(QString uri=QString());
    Q_INVOKABLE void command(QString command); Q_INVOKABLE void save(QString uri,bool remove=false);
    Q_INVOKABLE void togglePlayback();
    // Play a list (liked songs, search results) starting at index, so the following tracks keep playing.
    Q_INVOKABLE void playFrom(QStringList uris,int index);
    // Play a playlist starting at one of its tracks.
    Q_INVOKABLE void playInContext(QString context,QString uri);
    // Play the whole Liked songs collection from a track (or shuffled), falling back to the loaded list.
    Q_INVOKABLE void playLiked(QStringList uris,int index,bool shuffle=false);
    Q_INVOKABLE void queue(QString uri);
    // Android: start the Spotify app so this phone shows up as a playback device.
    Q_INVOKABLE void openSpotifyApp();
    Q_INVOKABLE void seek(qint64 ms);
    Q_INVOKABLE void setShuffle(bool enabled);
    Q_INVOKABLE void setRepeat(QString mode);
    Q_INVOKABLE void openSpotify(QString url);
    Q_INVOKABLE void retry();
signals:
    void localControl(QString action,int value); void changed(); void contentChanged(); void playbackChanged();
    void seeked(qint64 ms);
    // Short user-facing feedback for actions that happen outside the current page (snackbar).
    void notify(QString text);
private:
    OAuth *auth; QNetworkAccessManager network;
    bool loading=false,preferLocal=false; QString status="idle",info="Connect Spotify to choose music for your session.";
    QVariantList rows,deviceRows,playlistRows; QVariantMap player; QString localDevice; QString next,kind,selectedDevice,lastPath,lastKey,nextKey; bool lastAppend=false;
    QTimer poll,trackEnd; int pollTicks=0;
    QElapsedTimer clock,noticeClock; QString lastNotice;
    QDateTime blockedUntil; int generation=0;
    QString userId; // Only used to address the Liked songs collection; kept in memory.
    using Callback=std::function<void(QJsonObject)>;
    using ErrorCallback=std::function<void()>;
    // Background requests (playback state and controls) do not block or replace page loading.
    // onError, when given, replaces the error message for HTTP failures (not for rate limits).
    void request(QByteArray method,QString path,QJsonObject body,Callback cb,bool background=false,bool retried=false,ErrorCallback onError={});
    void load(QString path,QString key,bool append=false);
    void fail(QString state,QString message,bool background=false);
    void publish(QVariantMap state,bool seekedNow=false);
    QVariantMap current()const;
    void announce(QString text);
    void refreshSoon();
    bool allowed(QString action)const;
    QString target(QString path,QList<QPair<QString,QString>> query={},QString device={})const;
    // The device whose playback is shown in the player bar; controls go there, new playback goes to the selected device.
    QString controlDevice()const;
    bool localActive()const;
    void startPlayback(QJsonObject body);
    void activateLocal();
    // Returns true when there is no device yet and the request was deferred (Android) or refused.
    bool needDevice(std::function<void()> retry);
    std::function<void()> pendingPlay; QTimer pendingExpiry;
    static QVariantMap item(QJsonObject object);
};
