#include "SpotifyApi.h"
#include <QJsonArray>
#include <QJsonDocument>
#include <QUrlQuery>
#include <QDesktopServices>
#include <QRegularExpression>
#include <QGuiApplication>
#include <QRandomGenerator>
#include <algorithm>
SpotifyApi::SpotifyApi(OAuth *a,QObject *p):QObject(p),auth(a){
    network.setTransferTimeout(15000);
    poll.setInterval(20000);
    connect(&poll,&QTimer::timeout,this,[this]{
        if(!auth->connected() || QDateTime::currentDateTimeUtc()<blockedUntil)return;
        const bool active=QGuiApplication::applicationState()==Qt::ApplicationActive;
        // In the background only remote playback is polled, and less often, so desktop media widgets stay fresh.
        const bool remote=player.value("playing").toBool() && player.value("deviceId").toString()!=localDevice;
        if(active || (remote && ++pollTicks%3==0)) refreshPlayer(false);
    });
    poll.start();
    trackEnd.setSingleShot(true);
    connect(&trackEnd,&QTimer::timeout,this,[this]{if(auth->connected())refreshPlayer(false);});
    connect(auth,&OAuth::disconnected,this,[this]{
        ++generation;for(auto *reply:network.findChildren<QNetworkReply*>())reply->abort();
        rows.clear();deviceRows.clear();playlistRows.clear();userId.clear();publish({});next.clear();selectedDevice.clear();localDevice.clear();
        preferLocal=false;loading=false;status="idle";info="Spotify is disconnected.";emit contentChanged();emit changed();
    });
}
void SpotifyApi::announce(QString text){
    // Repeated failures from polling should not flood the snackbar.
    if(text==lastNotice && noticeClock.isValid() && noticeClock.elapsed()<60000)return;
    lastNotice=text;noticeClock.start();emit notify(text);
}
void SpotifyApi::fail(QString s,QString m,bool background){
    info=m;
    if(background){emit changed();announce(m);return;}
    loading=false;status=s;emit changed();
}
void SpotifyApi::request(QByteArray method,QString path,QJsonObject body,Callback cb,bool background,bool retried,ErrorCallback onError){
    if(!background && loading && !retried)return;
    if(QDateTime::currentDateTimeUtc()<blockedUntil){fail("quota","Spotify rate limit reached. Try again after "+blockedUntil.toLocalTime().toString("HH:mm:ss")+".",background);return;}
    QUrl url(path.startsWith("https://")?path:"https://api.spotify.com/v1"+path);
    if(url.scheme()!="https" || url.host()!="api.spotify.com" || !url.path().startsWith("/v1/") || !url.userInfo().isEmpty() || url.port(443)!=443){fail("error","Rejected an invalid API address.",background);return;}
    if(!background){loading=true;status="loading";info="Loading from Spotify…";emit changed();}
    const int g=generation;
    auth->authorize([this,method,url,body,cb,background,retried,onError,g](QByteArray token){
        if(g!=generation)return;
        if(token.isEmpty()){fail("error","Sign in or restore the connection in Settings.",background);return;}
        QNetworkRequest req(url);req.setRawHeader("Authorization","Bearer "+token);
        req.setAttribute(QNetworkRequest::RedirectPolicyAttribute,QNetworkRequest::ManualRedirectPolicy);
        req.setHeader(QNetworkRequest::ContentTypeHeader,"application/json");
        auto *r=network.sendCustomRequest(req,method,body.isEmpty()?QByteArray{}:QJsonDocument(body).toJson(QJsonDocument::Compact));
        connect(r,&QNetworkReply::finished,this,[this,r,method,url,body,cb,background,retried,onError,g]{
            r->deleteLater();if(g!=generation)return;
            const int code=r->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
            const auto json=QJsonDocument::fromJson(r->readAll()).object();
            if(code==401 && !retried){auth->authorize([this,method,url,body,cb,background,onError,g](QByteArray t){if(g!=generation)return;if(t.isEmpty()){fail("error","Your sign-in has expired. Connect again.",background);return;}if(!background)loading=false;request(method,url.toString(),body,cb,background,true,onError);},true);return;}
            if(!background)loading=false;
            if(code==429){bool ok=false;int seconds=r->rawHeader("Retry-After").toInt(&ok);if(!ok)seconds=60;seconds=qBound(1,seconds,86400);blockedUntil=QDateTime::currentDateTimeUtc().addSecs(seconds);fail("quota",json["error"].toObject()["reason"].toString()=="QUOTA_EXCEEDED"?"Developer account quota reached. Try again later.":QString("Too many requests. Wait %1 seconds.").arg(seconds),background);return;}
            if(onError && code!=0 && (code<200 || code>=300)){onError();return;}
            if(code==403){fail("error","Spotify refused this action: check Premium, allowed users, scopes and device restrictions.",background);return;}
            if(code==404){fail("empty","Not available. Start the built-in player or activate another device; this content may also be inaccessible.",background);return;}
            if(code==0){fail("offline","Spotify is unreachable. Check your internet connection and try again.",background);return;}
            if(code<200 || code>=300 || r->error()!=QNetworkReply::NoError){fail("error",QString("Spotify request failed (HTTP %1). Try again.").arg(code),background);return;}
            if(background){cb(json);return;}
            status="ready";info="Updated";cb(json);emit changed();
        });
    });
}
QVariantMap SpotifyApi::item(QJsonObject o){
    QStringList names;for(const auto &a:o["artists"].toArray())names<<a.toObject()["name"].toString();
    if(names.isEmpty())names<<o["owner"].toObject()["display_name"].toString();
    auto album=o["album"].toObject();
    auto images=(o["type"].toString()=="playlist"?o:album)["images"].toArray();
    const QUrl image(images.isEmpty()?QString():images.first().toObject()["url"].toString());
    const QString cover=image.scheme()=="https" && (image.host()=="i.scdn.co" || image.host().endsWith(".scdn.co")) ? image.toString() : QString();
    return {{"cover",cover},{"album",album["name"].toString()},{"duration",o["duration_ms"].toInt()}, {"id",o["id"].toString()},{"name",o["name"].toString("Unavailable")},{"subtitle",names.join(", ")},{"artists",names},{"uri",o["uri"].toString()},{"url",o["external_urls"].toObject()["spotify"].toString()},{"type",o["type"].toString()},{"explicit",o["explicit"].toBool()}};
}
void SpotifyApi::load(QString path,QString key,bool append){
    if(loading)return;
    lastPath=path;lastKey=key;lastAppend=append;
    if(!append){rows.clear();next.clear();emit contentChanged();}
    request("GET",path,{},[this,key,append](QJsonObject obj){
        if(!key.isEmpty())obj=obj[key].toObject();
        if(!append)rows.clear();
        for(const auto &v:obj["items"].toArray()){
            auto o=v.toObject();if(o.contains("track"))o=o["track"].toObject();else if(o.contains("item"))o=o["item"].toObject();
            if(o.isEmpty() || o["is_local"].toBool() || !QStringList{"track","playlist"}.contains(o["type"].toString()))continue;
            rows.append(item(o));
        }
        if(kind=="playlists")playlistRows=rows;
        next=obj["next"].toString();nextKey=key;status=rows.isEmpty()?"empty":"ready";info=rows.isEmpty()?"No results. Try a different selection.":"Content provided by Spotify • open an item in Spotify for all features.";
        emit contentChanged();
    });
}
void SpotifyApi::search(QString term){if(loading||term.trimmed().isEmpty())return;kind="search";QUrlQuery q;q.addQueryItem("q",term.trimmed());q.addQueryItem("type","track");q.addQueryItem("limit","10");load("/search?"+q.query(QUrl::FullyEncoded),"tracks");}
void SpotifyApi::library(){if(loading)return;kind="library";load("/me/tracks?limit=50",{});}
void SpotifyApi::playlists(){if(loading)return;kind="playlists";load("/me/playlists?limit=20",{});}
void SpotifyApi::playlist(QString id){if(loading||!QRegularExpression("^[A-Za-z0-9]+$").match(id).hasMatch())return;kind="playlist";load("/playlists/"+id+"/items?limit=20",{});}
void SpotifyApi::more(){if(!next.isEmpty())load(next,nextKey,true);}
void SpotifyApi::retry(){if(!lastPath.isEmpty())load(lastPath,lastKey,lastAppend);else refreshPlayer();}
void SpotifyApi::setDeviceId(QString id){
    for(const auto &v:deviceRows)if(v.toMap()["id"]==id){
        selectedDevice=id;preferLocal=!localDevice.isEmpty()&&id==localDevice;emit changed();
        // Choosing another device while music plays moves the music along with it.
        if(player.value("playing").toBool() && player.value("deviceId").toString()!=id)
            request("PUT","/me/player",QJsonObject{{"device_ids",QJsonArray{id}},{"play",true}},[this](QJsonObject){announce("Playback moved to the selected device.");refreshSoon();},true);
        return;
    }
}
QString SpotifyApi::target(QString path,QList<QPair<QString,QString>> query,QString device)const{
    QUrlQuery q;for(const auto &item:query)q.addQueryItem(item.first,item.second);
    if(device.isEmpty())device=selectedDevice;
    if(!device.isEmpty())q.addQueryItem("device_id",device);
    return q.isEmpty()?path:path+"?"+q.query(QUrl::FullyEncoded);
}
qint64 SpotifyApi::position()const{
    if(player.isEmpty())return 0;
    qint64 ms=player.value("progress").toLongLong();
    if(player.value("playing").toBool() && clock.isValid())ms+=clock.elapsed();
    const qint64 duration=player.value("duration").toLongLong();
    return duration>0?qMin(ms,duration):ms;
}
QVariantMap SpotifyApi::current()const{auto state=player;if(!state.isEmpty())state["progress"]=position();return state;}
void SpotifyApi::publish(QVariantMap state,bool seekedNow){
    const bool sameTrack=!player.isEmpty() && !state.value("uri").toString().isEmpty() && state.value("uri")==player.value("uri");
    const qint64 expected=position();
    player=state;clock.start();
    emit playbackChanged();
    if(seekedNow || (sameTrack && qAbs(player.value("progress").toLongLong()-expected)>2500))emit seeked(position());
    // Remote devices do not push updates; fetch the next track as soon as this one ends.
    trackEnd.stop();
    const qint64 duration=player.value("duration").toLongLong();
    if(player.value("playing").toBool() && duration>0 && player.value("deviceId").toString()!=localDevice)
        trackEnd.start(int(qBound<qint64>(qint64(1000),duration-player.value("progress").toLongLong()+1500,qint64(3600000))));
}
void SpotifyApi::refreshSoon(){const int g=generation;QTimer::singleShot(800,this,[this,g]{if(g==generation&&auth->connected())refreshPlayer(false);});}
bool SpotifyApi::allowed(QString action)const{return !player.value("restricted").toBool() && !player.value("disallows").toMap().value(action).toBool();}
void SpotifyApi::refreshPlayer(bool includeDevices){
    request("GET","/me/player",{},[this,includeDevices](QJsonObject o){
        const auto track=o["item"].toObject();
        if(track.isEmpty()){
            // 204 No Content: nothing is active. The local SDK reports its own state, so keep that.
            if(localDevice.isEmpty() || selectedDevice!=localDevice)publish({});
        }else{
            const auto device=o["device"].toObject();
            auto state=item(track);state["playing"]=o["is_playing"].toBool();
            state["device"]=device["name"].toString();
            state["progress"]=o["progress_ms"].toInt();
            state["volume"]=device["volume_percent"].toInt();
            state["supportsVolume"]=device["supports_volume"].toBool();
            state["deviceId"]=device["id"].toString();
            state["restricted"]=device["is_restricted"].toBool();
            state["disallows"]=o["actions"].toObject()["disallows"].toObject().toVariantMap();
            state["shuffle"]=o["shuffle_state"].toBool();
            state["repeat"]=o["repeat_state"].toString("off");
            publish(state);
        }
        if(!includeDevices)return;
        request("GET","/me/player/devices",{},[this](QJsonObject d){
            deviceRows.clear();bool found=false;
            for(const auto &v:d["devices"].toArray()){auto o=v.toObject();if(o["is_restricted"].toBool()||o["id"].toString().isEmpty())continue;auto id=o["id"].toString();deviceRows.append(QVariantMap{{"id",id},{"name",o["name"].toString()},{"supportsVolume",o["supports_volume"].toBool()},{"volume",o["volume_percent"].toInt()}});if(id==selectedDevice)found=true;}
            if(!localDevice.isEmpty()) {
                bool listed=false;for(auto &row:deviceRows)if(row.toMap()["id"].toString()==localDevice){auto device=row.toMap();device["supportsVolume"]=true;device["name"]="This computer · built-in player";row=device;listed=true;}
                if(!listed)deviceRows.prepend(QVariantMap{{"id",localDevice},{"name","This computer · built-in player"},{"supportsVolume",true}});
                if(selectedDevice==localDevice)found=true;
            }
            // Prefer the device that is actually playing over the first one in the list.
            const QString active=player.value("deviceId").toString();
            if(!found)selectedDevice=preferLocal||deviceRows.isEmpty()?QString():std::any_of(deviceRows.cbegin(),deviceRows.cend(),[&](const QVariant &v){return v.toMap()["id"].toString()==active;})?active:deviceRows.first().toMap()["id"].toString();
            info=deviceRows.isEmpty()?"Start the built-in player or open Spotify on another device.":"Devices updated. Choose where you want to listen.";
            emit changed();
        },true);
    },true);
}
QString SpotifyApi::controlDevice()const{const auto active=player.value("deviceId").toString();return active.isEmpty()?selectedDevice:active;}
bool SpotifyApi::localActive()const{return !localDevice.isEmpty() && controlDevice()==localDevice;}
void SpotifyApi::startPlayback(QJsonObject body){
    if(selectedDevice.isEmpty()){fail("empty","Choose a device first with the device button.",true);return;}
    request("PUT",target("/me/player/play"),body,[this](QJsonObject){refreshSoon();},true);
}
void SpotifyApi::play(QString uri){
    if(selectedDevice.isEmpty()){fail("empty","Choose a device first with the device button.",true);return;}
    if(uri.isEmpty() && !allowed("resuming")){fail("error","Spotify does not allow resuming right now.",true);return;}
    // The SDK can only resume what it already plays; otherwise the Web API moves playback to this device.
    if(uri.isEmpty() && localActive() && selectedDevice==localDevice){emit localControl("resume",0);return;}
    QJsonObject b;if(!uri.isEmpty()){
        if(!QRegularExpression("^spotify:(track|playlist):[A-Za-z0-9]+$").match(uri).hasMatch())return;
        if(uri.startsWith("spotify:playlist:"))b["context_uri"]=uri;else b["uris"]=QJsonArray{uri};
    }
    startPlayback(b);
}
void SpotifyApi::playFrom(QStringList uris,int index){
    static const QRegularExpression track("^spotify:track:[A-Za-z0-9]+$");
    QStringList valid;int offset=0;
    for(int i=0;i<uris.size();++i){if(i==index)offset=valid.size();if(track.match(uris[i]).hasMatch())valid<<uris[i];}
    if(valid.isEmpty())return;
    offset=qMin(offset,int(valid.size())-1);
    // Keep the request small: the chosen track plus what follows it.
    if(valid.size()>100){valid=valid.mid(offset,100);offset=0;}
    startPlayback({{"uris",QJsonArray::fromStringList(valid)},{"offset",QJsonObject{{"position",offset}}}});
}
void SpotifyApi::playLiked(QStringList uris,int index,bool shuffle){
    if(selectedDevice.isEmpty()){fail("empty","Choose a device first with the device button.",true);return;}
    auto fallback=[this,uris,index,shuffle]{
        QStringList list=uris;
        if(shuffle)std::shuffle(list.begin(),list.end(),*QRandomGenerator::global());
        playFrom(list,shuffle?0:index);
    };
    auto start=[this,uris,index,shuffle,fallback]{
        if(userId.isEmpty()){fallback();return;}
        QJsonObject b{{"context_uri","spotify:user:"+userId+":collection"}};
        const QString uri=uris.value(index);
        if(!shuffle && QRegularExpression("^spotify:track:[A-Za-z0-9]+$").match(uri).hasMatch())b["offset"]=QJsonObject{{"uri",uri}};
        const QString device=selectedDevice;
        auto play=[this,b,device,fallback]{request("PUT",target("/me/player/play",{},device),b,[this](QJsonObject){refreshSoon();},true,false,fallback);};
        // Shuffle has to be set before starting so the first song is random too. It fails harmlessly when nothing is active yet.
        if(shuffle)request("PUT",target("/me/player/shuffle",{{"state","true"}},device),{},[play](QJsonObject){play();},true,false,play);
        else play();
    };
    if(!userId.isEmpty()){start();return;}
    request("GET","/me",{},[this,start](QJsonObject me){
        const auto id=me["id"].toString();
        if(QRegularExpression("^[A-Za-z0-9._-]{1,128}$").match(id).hasMatch())userId=id;
        start();
    },true,false,fallback);
}
void SpotifyApi::playInContext(QString context,QString uri){
    if(!QRegularExpression("^spotify:playlist:[A-Za-z0-9]+$").match(context).hasMatch())return;
    QJsonObject b{{"context_uri",context}};
    if(QRegularExpression("^spotify:track:[A-Za-z0-9]+$").match(uri).hasMatch())b["offset"]=QJsonObject{{"uri",uri}};
    startPlayback(b);
}
void SpotifyApi::command(QString cmd){
    if(!QStringList{"pause","next","previous"}.contains(cmd))return;
    if(!allowed(cmd=="pause"?"pausing":cmd=="next"?"skipping_next":"skipping_prev")){fail("error","Spotify does not allow this control right now.",true);return;}
    if(controlDevice().isEmpty()){fail("empty","Choose a Spotify device first.",true);return;}
    if(localActive()){emit localControl(cmd,0);return;}
    request(cmd=="pause"?"PUT":"POST",target("/me/player/"+cmd,{},controlDevice()),{},[this](QJsonObject){refreshSoon();},true);
}
void SpotifyApi::togglePlayback(){if(player.value("playing").toBool())command("pause");else play();}
void SpotifyApi::seek(qint64 ms){
    if(player.value("uri").toString().isEmpty() || controlDevice().isEmpty() || !allowed("seeking"))return;
    const qint64 duration=player.value("duration").toLongLong();
    if(duration>0)ms=qMin(ms,duration);
    ms=qMax<qint64>(0,ms);
    auto state=player;state["progress"]=ms;publish(state,true);
    if(localActive()){emit localControl("seek",int(ms));return;}
    request("PUT",target("/me/player/seek",{{"position_ms",QString::number(ms)}},controlDevice()),{},[this](QJsonObject){refreshSoon();},true);
}
void SpotifyApi::setShuffle(bool enabled){
    if(controlDevice().isEmpty() || player.value("uri").toString().isEmpty() || !allowed("toggling_shuffle"))return;
    auto state=current();state["shuffle"]=enabled;publish(state);
    request("PUT",target("/me/player/shuffle",{{"state",enabled?"true":"false"}},controlDevice()),{},[this](QJsonObject){refreshSoon();},true);
}
void SpotifyApi::setRepeat(QString mode){
    if(!QStringList{"off","context","track"}.contains(mode) || controlDevice().isEmpty() || player.value("uri").toString().isEmpty())return;
    if(mode!="off" && !allowed(mode=="track"?"toggling_repeat_track":"toggling_repeat_context"))return;
    auto state=current();state["repeat"]=mode;publish(state);
    request("PUT",target("/me/player/repeat",{{"state",mode}},controlDevice()),{},[this](QJsonObject){refreshSoon();},true);
}
void SpotifyApi::save(QString uri,bool remove){
    if(!QRegularExpression("^spotify:track:[A-Za-z0-9]+$").match(uri).hasMatch())return;
    QUrlQuery q;q.addQueryItem("uris",uri);
    request(remove?"DELETE":"PUT","/me/library?"+q.query(QUrl::FullyEncoded),{},[this,remove](QJsonObject){info=remove?"Removed from your saved songs. Refresh the library.":"Added to your saved songs in Spotify.";emit changed();announce(info);},true);
}
void SpotifyApi::openSpotify(QString url){const QUrl u(url);if(u.scheme()=="https" && u.host()=="open.spotify.com" && u.userInfo().isEmpty())QDesktopServices::openUrl(u);}

void SpotifyApi::setVolume(int percent){
    percent=qBound(0,percent,100);
    const QString device=controlDevice();
    if(device.isEmpty())return;
    bool supported=localActive() || (player.value("deviceId").toString()==device && player.value("supportsVolume").toBool());
    for(const auto &v:deviceRows){auto d=v.toMap();if(d["id"].toString()==device)supported=supported||d["supportsVolume"].toBool();}
    if(!supported)return;
    if(!player.isEmpty()){auto state=current();state["volume"]=percent;publish(state);}
    if(localActive()){emit localControl("volume",percent);return;}
    request("PUT",target("/me/player/volume",{{"volume_percent",QString::number(percent)}},device),{},[](QJsonObject){},true);
}

void SpotifyApi::prepareLocalPlayback(){
    preferLocal=true;selectedDevice.clear();publish({});emit changed();
}
void SpotifyApi::setLocalDevice(QString id){
    const QString previous=localDevice;
    for(qsizetype i=deviceRows.size();i>0;--i)if(deviceRows[i-1].toMap()["id"].toString()==previous)deviceRows.removeAt(i-1);
    localDevice=id;
    if(!id.isEmpty()){
        deviceRows.prepend(QVariantMap{{"id",id},{"name","This computer · built-in player"},{"supportsVolume",true},{"volume",50}});
        selectedDevice=id;preferLocal=true;
        // Give Spotify a moment to register the new Connect device before making it the active one.
        const int g=generation;
        QTimer::singleShot(1500,this,[this,g,id]{if(g==generation && localDevice==id)activateLocal();});
    }else if(!previous.isEmpty()&&selectedDevice==previous){selectedDevice.clear();}
    if(!previous.isEmpty()&&player.value("deviceId").toString()==previous)publish({});
    emit changed();
}
void SpotifyApi::updateLocalPlayback(QJsonObject state){
    if(localDevice.isEmpty()||selectedDevice!=localDevice)return;
    if(state.isEmpty()){publish({});return;}
    auto track=state["track_window"].toObject()["current_track"].toObject();
    const QString id=track["id"].toString();
    if(QRegularExpression("^[A-Za-z0-9]+$").match(id).hasMatch())track["external_urls"]=QJsonObject{{"spotify","https://open.spotify.com/track/"+id}};
    auto next=item(track);next["duration"]=state["duration"].toInt();
    next["playing"]=!state["paused"].toBool();next["progress"]=state["position"].toInt();
    next["device"]="This computer";next["deviceId"]=localDevice;
    next["volume"]=qRound(state["volume"].toDouble(0.5)*100);next["supportsVolume"]=true;
    next["restricted"]=false;next["disallows"]=state["disallows"].toObject().toVariantMap();
    next["shuffle"]=state["shuffle"].toBool();
    next["repeat"]=QStringList{"off","context","track"}.value(state["repeat_mode"].toInt(),"off");
    publish(next);
}
void SpotifyApi::activateLocal(){
    // Make this computer the active Spotify device, but never take over music that is playing elsewhere.
    request("GET","/me/player",{},[this,id=localDevice](QJsonObject o){
        if(id.isEmpty() || id!=localDevice)return;
        const auto device=o["device"].toObject();
        if(device["id"].toString()==id)return;
        if(o["is_playing"].toBool()){announce(QString("Music is playing on %1. Choose this computer under devices (Ctrl+D) to move it here.").arg(device["name"].toString()));return;}
        request("PUT","/me/player",QJsonObject{{"device_ids",QJsonArray{id}},{"play",false}},[this](QJsonObject){announce("This computer is now your Spotify device.");refreshSoon();},true);
    },true);
}
