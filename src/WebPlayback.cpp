#include "WebPlayback.h"
#include "OAuth.h"
#include "AppConfig.h"
#include <QWebEnginePage>
#include <QWebEngineProfile>
#include <QWebEngineSettings>
#include <QWebEnginePermission>
#include <QWebEngineUrlRequestInterceptor>
#include <QWebEngineUrlRequestInfo>
#include <QWebChannel>
#include <QTcpSocket>
#include <QFile>
#include <QPointer>
#include <QUuid>
#include <QRegularExpression>
#include <memory>

namespace {
bool spotifyHost(const QString &host){
    for(const auto &domain: {QString("spotify.com"),QString("scdn.co"),QString("spotifycdn.com")})
        if(host==domain || host.endsWith("."+domain))return true;
    return false;
}
class SdkRequests final: public QWebEngineUrlRequestInterceptor {
public:
    QUrl origin;
    explicit SdkRequests(QUrl url,QObject *parent):QWebEngineUrlRequestInterceptor(parent),origin(url){}
    void interceptRequest(QWebEngineUrlRequestInfo &r)override{
        const auto u=r.requestUrl();
        bool local=u.scheme()=="http" && u.host()==origin.host() && u.port()==origin.port() && u.path().startsWith(origin.path());
        bool remote=(u.scheme()=="https" || u.scheme()=="wss") && spotifyHost(u.host()) && u.port(443)==443;
        bool media=u.scheme()=="blob" || u.scheme()=="data";
        if(!u.userInfo().isEmpty() || !(local||remote||media))r.block(true);
    }
};
class SdkPage final:public QWebEnginePage {
public:
    QUrl entry;
    SdkPage(QWebEngineProfile *profile,QObject *parent):QWebEnginePage(profile,parent){}
protected:
    bool acceptNavigationRequest(const QUrl &url,NavigationType,bool main)override{
        return main ? url==entry : url.scheme()=="https" && spotifyHost(url.host());
    }
    QWebEnginePage *createWindow(WebWindowType)override{return nullptr;}
    void javaScriptConsoleMessage(JavaScriptConsoleMessageLevel,const QString&,int,const QString&)override{}
};
}
WebPlayback::WebPlayback(OAuth *a,QObject *parent):QObject(parent),auth(a){
    deadline.setSingleShot(true);deadline.setInterval(45000);
    connect(&deadline,&QTimer::timeout,this,[this]{fail("The local player is not responding. Check your internet connection, Widevine and audio codecs, then try again.");});
    connect(auth,&OAuth::disconnected,this,&WebPlayback::stop);
    connect(&server,&QTcpServer::newConnection,this,[this]{
        while(server.hasPendingConnections()){
            auto *socket=server.nextPendingConnection();
            auto buffer=std::make_shared<QByteArray>();
            connect(socket,&QTcpSocket::disconnected,socket,&QObject::deleteLater);
            QTimer::singleShot(5000,socket,[socket]{socket->disconnectFromHost();});
            connect(socket,&QTcpSocket::readyRead,this,[this,socket,buffer]{
                *buffer+=socket->readAll();
                if(buffer->size()>8192){socket->disconnectFromHost();return;}
                if(!buffer->contains("\r\n\r\n"))return;
                const auto parts=buffer->left(buffer->indexOf("\r\n")).split(' ');
                QByteArray body,type="text/plain";
                if(parts.size()==3 && parts[0]=="GET"){
                    const QString path=QString::fromLatin1(parts[1]);
                    QString resource;
                    if(path==route+"/"){resource=":/assets/player/index.html";type="text/html; charset=utf-8";}
                    if(path==route+"/player.js"){resource=":/assets/player/player.js";type="application/javascript";}
                    if(path==route+"/qwebchannel.js"){resource=":/qtwebchannel/qwebchannel.js";type="application/javascript";}
                    QFile file(resource);if(!resource.isEmpty()&&file.open(QIODevice::ReadOnly))body=file.readAll();
                    if(path==route+"/"){body.replace("MIRA_PLAYER_NAME",QString(AppConfig::name).toHtmlEscaped().toUtf8());body.replace("CHECK_ONLY",diagnostic?"yes":"no");}
                }
                const auto code=body.isEmpty()?"404 Not Found":"200 OK";
                socket->write(QByteArray("HTTP/1.1 ")+code+"\r\nContent-Type: "+type+"\r\nCache-Control: no-store\r\nX-Content-Type-Options: nosniff\r\nReferrer-Policy: no-referrer\r\nContent-Length: "+QByteArray::number(body.size())+"\r\nConnection: close\r\n\r\n"+body);
                socket->disconnectFromHost();
            });
        }
    });
}
WebPlayback::~WebPlayback(){release();}
void WebPlayback::release(){
    ++generation;deadline.stop();server.close();
    for(auto *socket:server.findChildren<QTcpSocket*>())socket->abort();
    // Destroying the page closes the SDK connection and all media immediately.
    delete page;page=nullptr;delete profile;profile=nullptr;
    connecting=false;device.clear();emit deviceChanged({});
}
void WebPlayback::stop(){release();info="Local player stopped.";emit changed();}
void WebPlayback::fail(QString message){
    // WebChannel callbacks may still be on the stack. Tear down on the next event turn.
    const int g=generation;
    QTimer::singleShot(0,this,[this,g,message]{if(g!=generation)return;release();info=message;emit changed();});
}
void WebPlayback::start(){openPlayer(false);}
void WebPlayback::diagnose(){openPlayer(true);}
void WebPlayback::openPlayer(bool checkOnly){
    if(connecting||ready())return;
    if(!checkOnly && !auth->connected()){info="Connect Spotify first. Sign in again if you have not granted streaming permission yet.";emit changed();return;}
    if(!checkOnly)emit localRequested();
    release();diagnostic=checkOnly;
    if(!server.listen(QHostAddress::LocalHost,0)){fail("The local player could not open its loopback address.");return;}
    route="/"+QUuid::createUuid().toString(QUuid::Id128);
    const QUrl entry(QString("http://127.0.0.1:%1%2/").arg(server.serverPort()).arg(route));
    profile=new QWebEngineProfile(this); // Off-the-record: no persistent storage or cookies.
    profile->setHttpCacheType(QWebEngineProfile::MemoryHttpCache);
    profile->setPersistentCookiesPolicy(QWebEngineProfile::NoPersistentCookies);
    auto origin=entry;origin.setPath(route+"/");
    profile->setUrlRequestInterceptor(new SdkRequests(origin,profile));
    auto *sdkPage=new SdkPage(profile,this);page=sdkPage;sdkPage->entry=entry;
    page->settings()->setAttribute(QWebEngineSettings::PlaybackRequiresUserGesture,false);
    page->settings()->setAttribute(QWebEngineSettings::JavascriptCanOpenWindows,false);
    page->settings()->setAttribute(QWebEngineSettings::LocalContentCanAccessFileUrls,false);
    connect(page,&QWebEnginePage::permissionRequested,this,[](QWebEnginePermission permission){permission.deny();});
    const int g=generation;
    connect(page,&QWebEnginePage::loadFinished,this,[this,g](bool ok){if(g==generation&&!ok)fail("The local player page could not load.");});
    connect(page,&QWebEnginePage::renderProcessTerminated,this,[this,g](auto,int){if(g==generation)fail("The audio engine stopped. Start the local player again.");});
    auto *channel=new QWebChannel(page);auto *bridge=new PlaybackBridge(channel);
    channel->registerObject("bridge",bridge);page->setWebChannel(channel);
    connect(bridge,&PlaybackBridge::tokenRequested,this,[this,g,guard=QPointer<PlaybackBridge>(bridge)](int request){
        auth->authorize([this,g,guard,request](QByteArray token){
            if(g!=generation||!guard)return;
            emit guard->tokenReady(request,QString::fromUtf8(token));
        });
    });
    connect(bridge,&PlaybackBridge::reported,this,[this,g](QString event,QJsonObject data){
        if(g!=generation)return;
        if(event=="drm_available"){fail("Widevine and AAC are available. Connect Spotify and start the player to check your account.");}
        else if(event=="ready"){
            const auto id=data["device_id"].toString();
            if(!QRegularExpression("^[A-Za-z0-9_-]{1,256}$").match(id).hasMatch())return;
            deadline.stop();connecting=false;device=id;info="Ready to play on this computer.";emit deviceChanged(device);emit changed();
        }else if(event=="state"){emit playbackState(data);}
        else if(event=="not_ready"){fail("The local player is offline. Check your internet connection and start it again.");}
        else if(event=="drm"||event=="initialization_error"){fail("Protected audio is not available. Install a compatible Widevine CDM and Qt WebEngine with AAC support. See docs/PLAYBACK.md.");}
        else if(event=="authentication_error"){fail("Spotify rejected the player token. Sign out and connect again to grant the streaming, email and profile scopes.");}
        else if(event=="account_error"){fail("Spotify Premium is required for the built-in player.");}
        else if(event=="autoplay_failed"||event=="playback_error"){info="Spotify could not start the audio. Press Play again; check Widevine, codecs and your account.";emit changed();}
        else if(event=="connection_error"){fail("Could not connect to the Spotify player. Check your internet connection and account access.");}
    });
    connecting=true;info=checkOnly?"Checking Widevine and audio codecs…":"Connecting the Spotify audio engine…";emit changed();deadline.start();page->load(entry);
}

void WebPlayback::control(QString action,int value){
    if(!page||!ready())return;
    if(!QStringList{"pause","resume","next","previous","volume","seek"}.contains(action))return;
    // Seek takes milliseconds; everything else is a 0-100 percentage.
    const int bounded=action=="seek"?qMax(0,value):qBound(0,value,100);
    page->runJavaScript(QString("window.miraControl('%1',%2)").arg(action).arg(bounded));
}
