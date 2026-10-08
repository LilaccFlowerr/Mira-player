#pragma once
#include <QObject>
#include <QTcpServer>
#include <QTimer>
#include <QJsonObject>
class OAuth;
class QWebEnginePage;
class QWebEngineProfile;

// The only object exposed to the dedicated SDK page. Never registered in QML.
class PlaybackBridge : public QObject {
    Q_OBJECT
public:
    explicit PlaybackBridge(QObject *parent):QObject(parent){}
    Q_INVOKABLE void requestToken(int request) { emit tokenRequested(request); }
    Q_INVOKABLE void report(QString event, QJsonObject data) { emit reported(event,data); }
signals:
    void tokenRequested(int request);
    void tokenReady(int request,QString token);
    void reported(QString event,QJsonObject data);
};
class WebPlayback : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString status READ status NOTIFY changed)
    Q_PROPERTY(bool busy READ busy NOTIFY changed)
    Q_PROPERTY(bool ready READ ready NOTIFY changed)
public:
    explicit WebPlayback(OAuth *auth,QObject *parent=nullptr);
    ~WebPlayback() override;
    QString status()const{return info;}
    bool busy()const{return connecting;}
    bool ready()const{return !device.isEmpty();}
    void control(QString action,int value);
    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void diagnose();
signals:
    void changed();
    void deviceChanged(QString id);
    void localRequested();
    void playbackState(QJsonObject state);
private:
    OAuth *auth;
    QWebEngineProfile *profile=nullptr;
    QWebEnginePage *page=nullptr;
    QTcpServer server;
    QTimer deadline;
    QString info="Listen on this computer with Spotify Premium.",device,route;
    bool connecting=false,diagnostic=false;
    int generation=0;
    void openPlayer(bool checkOnly);
    void release();
    void fail(QString message);
};
