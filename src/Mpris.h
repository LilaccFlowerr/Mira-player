#pragma once
#include <QObject>
#include <QDBusAbstractAdaptor>
#include <QDBusObjectPath>
#include <QVariantMap>
class SpotifyApi;

// MPRIS 2.2 on the session bus, so desktop media widgets, lock screens and media keys
// can show and control what Mira plays. Only current playback metadata is exposed.
class Mpris : public QObject {
    Q_OBJECT
public:
    explicit Mpris(SpotifyApi *spotify,QObject *parent=nullptr);
    ~Mpris() override;
    SpotifyApi *spotify;
    QVariantMap playerProperties()const;
    QVariantMap metadata()const;
    QString playbackStatus()const;
    bool can(const QString &action)const;
signals:
    void raiseRequested();
    void quitRequested();
private:
    QString service;
    QVariantMap published;
    void sync();
};

class MprisRoot : public QDBusAbstractAdaptor {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface","org.mpris.MediaPlayer2")
    Q_PROPERTY(bool CanQuit READ canQuit)
    Q_PROPERTY(bool CanRaise READ canRaise)
    Q_PROPERTY(bool HasTrackList READ hasTrackList)
    Q_PROPERTY(QString Identity READ identity)
    Q_PROPERTY(QString DesktopEntry READ desktopEntry)
    Q_PROPERTY(QStringList SupportedUriSchemes READ none)
    Q_PROPERTY(QStringList SupportedMimeTypes READ none)
public:
    explicit MprisRoot(Mpris *owner):QDBusAbstractAdaptor(owner),owner(owner){}
    bool canQuit()const{return true;} bool canRaise()const{return true;} bool hasTrackList()const{return false;}
    QString identity()const; QString desktopEntry()const;
    QStringList none()const{return {};}
public slots:
    void Raise(){emit owner->raiseRequested();}
    void Quit(){emit owner->quitRequested();}
private:
    Mpris *owner;
};

class MprisPlayer : public QDBusAbstractAdaptor {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface","org.mpris.MediaPlayer2.Player")
    Q_PROPERTY(QString PlaybackStatus READ playbackStatus)
    Q_PROPERTY(QString LoopStatus READ loopStatus WRITE setLoopStatus)
    Q_PROPERTY(double Rate READ rate WRITE setRate)
    Q_PROPERTY(bool Shuffle READ shuffle WRITE setShuffle)
    Q_PROPERTY(QVariantMap Metadata READ metadata)
    Q_PROPERTY(double Volume READ volume WRITE setVolume)
    Q_PROPERTY(qlonglong Position READ position)
    Q_PROPERTY(double MinimumRate READ rate)
    Q_PROPERTY(double MaximumRate READ rate)
    Q_PROPERTY(bool CanGoNext READ canGoNext)
    Q_PROPERTY(bool CanGoPrevious READ canGoPrevious)
    Q_PROPERTY(bool CanPlay READ canPlay)
    Q_PROPERTY(bool CanPause READ canPause)
    Q_PROPERTY(bool CanSeek READ canSeek)
    Q_PROPERTY(bool CanControl READ canControl)
public:
    explicit MprisPlayer(Mpris *owner);
    QString playbackStatus()const{return owner->playbackStatus();}
    QString loopStatus()const; void setLoopStatus(const QString &status);
    double rate()const{return 1.0;} void setRate(double){}
    bool shuffle()const; void setShuffle(bool enabled);
    QVariantMap metadata()const{return owner->metadata();}
    double volume()const; void setVolume(double volume);
    qlonglong position()const;
    bool canGoNext()const{return owner->can("skipping_next");}
    bool canGoPrevious()const{return owner->can("skipping_prev");}
    bool canPlay()const{return owner->can("resuming");}
    bool canPause()const{return owner->can("pausing");}
    bool canSeek()const{return owner->can("seeking");}
    bool canControl()const{return true;}
public slots:
    void Next(); void Previous(); void Pause(); void PlayPause(); void Stop(); void Play();
    void Seek(qlonglong offset);
    void SetPosition(const QDBusObjectPath &track,qlonglong position);
    void OpenUri(const QString &){}
signals:
    void Seeked(qlonglong position);
private:
    Mpris *owner;
};
