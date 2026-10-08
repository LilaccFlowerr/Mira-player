#pragma once
#include <QObject>
#include <QTcpServer>
#include <QTimer>
#include <QNetworkAccessManager>
#include <QPointer>
#include <QNetworkReply>
#include <QDateTime>
#include <functional>
#include "TokenStore.h"
#include "Preferences.h"
class OAuth : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool connected READ connected NOTIFY changed)
    Q_PROPERTY(bool busy READ busy NOTIFY changed)
    Q_PROPERTY(QString status READ status NOTIFY changed)
public:
    OAuth(Preferences *preferences,QObject *parent=nullptr,bool restore=true);
    bool connected() const{return !refreshToken.isEmpty() || !accessToken.isEmpty();}
    bool busy() const{return working;}
    QString status() const{return message;}
    Q_INVOKABLE void login(); Q_INVOKABLE void logout();
    void authorize(std::function<void(QByteArray)> callback, bool force=false);
signals: void changed(); void disconnected();
private:
    Preferences *prefs; TokenStore store; QTcpServer server; QTimer timeout;
    QNetworkAccessManager network; QPointer<QNetworkReply> pending;
    QByteArray accessToken,refreshToken,verifier,state;
    QString account,message="Not connected"; QDateTime expires;
    bool working=false; int generation=0;
    QList<std::function<void(QByteArray)>> waiting;
    void exchange(const QList<QPair<QString,QString>> &fields);
    void finish(bool ok,QString text); void acceptCallback();
};
