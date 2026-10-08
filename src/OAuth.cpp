#include "OAuth.h"
#include "AppConfig.h"
#include <QCryptographicHash>
#include <QRandomGenerator>
#include <QDesktopServices>
#include <QUrlQuery>
#include <QTcpSocket>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
namespace {
QByteArray randomString(){QByteArray b(32,0);for(auto &c:b)c=char(QRandomGenerator::system()->generate()&255);return b.toBase64(QByteArray::Base64UrlEncoding|QByteArray::OmitTrailingEquals);}
}
OAuth::OAuth(Preferences *p,QObject *parent,bool restore):QObject(parent),prefs(p) {
    network.setTransferTimeout(15000);
    connect(&server,&QTcpServer::newConnection,this,&OAuth::acceptCallback);
    timeout.setSingleShot(true); timeout.setInterval(180000);
    connect(&timeout,&QTimer::timeout,this,[this]{server.close();state.clear();verifier.clear();finish(false,"Sign-in timed out. Try again.");});
    account=prefs->clientId();
    if(!restore || account.isEmpty() || !QSettings().value("restoreSession",false).toBool()) return;
    working=true; message="Opening the keyring…";
    const int g=generation;
    store.read(account,[this,g](bool ok,QByteArray token){
        if(g!=generation)return;
        working=false;
        if(!ok){message="Keyring unavailable. Sign in again for this session only.";emit changed();return;}
        refreshToken=token;
        if(token.isEmpty()){message="Not connected";emit changed();return;}
        authorize([](QByteArray){});
    });
}
void OAuth::login(){
    if(working || connected())return;
    account=prefs->clientId();
    if(!QRegularExpression("^[A-Za-z0-9]{32}$").match(account).hasMatch()){message="Enter a valid Spotify Client ID in Settings.";emit changed();return;}
    if(!server.listen(QHostAddress::LocalHost,43821)){message="OAuth port 43821 is in use. Close the other app and try again.";emit changed();return;}
    ++generation; verifier=randomString();state=randomString();working=true;timeout.start();
    QUrl url("https://accounts.spotify.com/authorize"); QUrlQuery q;
    q.addQueryItem("client_id",account);q.addQueryItem("response_type","code");q.addQueryItem("redirect_uri",AppConfig::redirect);
    q.addQueryItem("scope",AppConfig::scopes);q.addQueryItem("state",QString::fromLatin1(state));q.addQueryItem("code_challenge_method","S256");
    q.addQueryItem("code_challenge",QString::fromLatin1(QCryptographicHash::hash(verifier,QCryptographicHash::Sha256).toBase64(QByteArray::Base64UrlEncoding|QByteArray::OmitTrailingEquals)));
    url.setQuery(q);message="Finish granting access in your browser…";emit changed();
    if(!QDesktopServices::openUrl(url)){server.close();timeout.stop();finish(false,"The browser could not be opened.");}
}
void OAuth::acceptCallback(){
    while(server.hasPendingConnections()){
        auto *socket=server.nextPendingConnection();socket->setReadBufferSize(8192);
        const int g=generation;
        auto buffer=std::make_shared<QByteArray>();
        QTimer::singleShot(5000,socket,[socket]{socket->disconnectFromHost();});
        connect(socket,&QTcpSocket::disconnected,socket,&QObject::deleteLater);
        connect(socket,&QTcpSocket::readyRead,this,[this,socket,buffer,g]{
            buffer->append(socket->readAll());
            if(buffer->size()>8192){socket->disconnectFromHost();return;}
            if(!buffer->contains("\r\n\r\n"))return;
            const auto first=buffer->split('\n').value(0).trimmed().split(' ');
            QUrl url=QUrl::fromEncoded(first.value(1)); QUrlQuery q(url);
            const bool valid=g==generation && !state.isEmpty() && first.value(0)=="GET" && url.path()=="/callback" && q.queryItemValue("state").toLatin1()==state;
            const QByteArray body=valid?"Sign-in received. You can close this window.":"Invalid callback.";
            socket->write(QByteArray(valid?"HTTP/1.1 200 OK\r\n":"HTTP/1.1 400 Bad Request\r\n")+"Content-Type: text/plain; charset=utf-8\r\nCache-Control: no-store\r\nConnection: close\r\nContent-Length: "+QByteArray::number(body.size())+"\r\n\r\n"+body);
            socket->disconnectFromHost();
            if(!valid)return;
            state.clear();server.close();timeout.stop();
            if(q.hasQueryItem("error") || q.queryItemValue("code").isEmpty()){verifier.clear();finish(false,"Access was not granted.");return;}
            exchange({{"grant_type","authorization_code"},{"code",q.queryItemValue("code")},{"redirect_uri",AppConfig::redirect},{"code_verifier",QString::fromLatin1(verifier)}});
            verifier.clear();
        });
    }
}
void OAuth::exchange(const QList<QPair<QString,QString>> &fields){
    working=true;emit changed();
    QUrlQuery form;for(const auto &p:fields)form.addQueryItem(p.first,p.second);form.addQueryItem("client_id",account);
    QNetworkRequest req(QUrl("https://accounts.spotify.com/api/token"));
    req.setAttribute(QNetworkRequest::RedirectPolicyAttribute,QNetworkRequest::ManualRedirectPolicy);
    req.setHeader(QNetworkRequest::ContentTypeHeader,"application/x-www-form-urlencoded");
    auto *reply=network.post(req,form.query(QUrl::FullyEncoded).toUtf8());pending=reply;const int g=generation;
    connect(reply,&QNetworkReply::finished,this,[this,reply,g]{
        reply->deleteLater();if(g!=generation)return;
        const auto obj=QJsonDocument::fromJson(reply->readAll()).object();
        const int code=reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        if(reply->error()!=QNetworkReply::NoError || code!=200 || obj["access_token"].toString().isEmpty()){
            if(obj["error"].toString()=="invalid_grant"){logout();message="Access expired or was revoked. Sign in again.";emit changed();return;}
            finish(false,code==429?"OAuth rate limit reached. Try again later.":"Could not connect to Spotify. Check your network and OAuth configuration.");return;
        }
        if(obj.contains("scope")) {
            const auto granted=obj["scope"].toString().split(' ');
            for(const auto &required:QString::fromLatin1(AppConfig::scopes).split(' ')) {
                if(!granted.contains(required)){logout();message="Not all required permissions were granted. Connect again.";emit changed();return;}
            }
        }
        accessToken=obj["access_token"].toString().toUtf8();
        if(obj.contains("refresh_token"))refreshToken=obj["refresh_token"].toString().toUtf8();
        expires=QDateTime::currentDateTimeUtc().addSecs(qMax(1,obj["expires_in"].toInt(3600)-60));
        if(!refreshToken.isEmpty())store.write(account,refreshToken,[this,g](bool ok,QByteArray){if(g!=generation)return;QSettings().setValue("restoreSession",ok);if(!ok){message="Connected • this session only; secure storage unavailable";emit changed();}});
        finish(true,"Connected to Spotify");
    });
}
void OAuth::finish(bool ok,QString text){working=false;message=text;emit changed();const auto callbacks=std::exchange(waiting,{});for(const auto &cb:callbacks)cb(ok?accessToken:QByteArray{});}
void OAuth::authorize(std::function<void(QByteArray)> cb,bool force){
    if(!force && !accessToken.isEmpty() && expires>QDateTime::currentDateTimeUtc()){cb(accessToken);return;}
    if(refreshToken.isEmpty()){cb({});return;}
    waiting.append(cb);if(working)return;
    exchange({{"grant_type","refresh_token"},{"refresh_token",QString::fromUtf8(refreshToken)}});
}
void OAuth::logout(){
    ++generation;QSettings().setValue("restoreSession",false);server.close();timeout.stop();
    if(pending)pending->abort();
    state.clear();verifier.clear();accessToken.clear();refreshToken.clear();
    emit disconnected();finish(false,"Not connected");
    if(!account.isEmpty()) {const int g=generation;store.remove(account,[this,g](bool ok,QByteArray){if(g==generation && !ok){message="Signed out. The keyring entry could not be removed; delete the Mira entry there and revoke access at spotify.com/account/apps.";emit changed();}});}
}
