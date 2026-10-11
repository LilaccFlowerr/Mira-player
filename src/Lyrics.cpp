#include "Lyrics.h"
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QRegularExpression>
#include <QUrlQuery>
#include <QCoreApplication>
#include <algorithm>
Lyrics::Lyrics(QObject *p):QObject(p){network.setTransferTimeout(10000);}
void Lyrics::finish(QString s,QVariantList synced,QString plain){
    status=s;lines=synced;text=plain;times.clear();
    for(const auto &l:synced)times<<l.toMap()["time"].toLongLong();
    emit changed();
}
void Lyrics::clear(){++generation;loadedUri.clear();finish("idle");}
int Lyrics::lineAt(qint64 ms)const{
    // The last line whose time has passed (a little early, so the highlight does not trail the voice).
    const auto it=std::upper_bound(times.begin(),times.end(),ms+250);
    return int(it-times.begin())-1;
}
QList<QPair<qint64,QString>> Lyrics::parseLrc(const QString &lrc){
    static const QRegularExpression stamp(R"(\[(\d+):(\d+)(?:[.:](\d+))?\])");
    QList<QPair<qint64,QString>> out;
    for(const auto &raw:lrc.split('\n')){
        QList<QRegularExpressionMatch> stamps;
        auto it=stamp.globalMatch(raw);
        while(it.hasNext())stamps<<it.next();
        if(stamps.isEmpty())continue;
        const QString words=raw.mid(stamps.last().capturedEnd()).trimmed();
        for(const auto &m:stamps){
            const QString frac=(m.captured(3)+"00").left(3);
            out.append({(m.captured(1).toLongLong()*60+m.captured(2).toLongLong())*1000+(m.captured(3).isEmpty()?0:frac.toLongLong()),words});
        }
    }
    std::stable_sort(out.begin(),out.end(),[](const auto &a,const auto &b){return a.first<b.first;});
    return out;
}
bool Lyrics::apply(const QJsonObject &o){
    QVariantList synced;
    for(const auto &l:parseLrc(o["syncedLyrics"].toString()))synced.append(QVariantMap{{"time",l.first},{"text",l.second}});
    const QString plain=o["plainLyrics"].toString();
    if(synced.isEmpty() && plain.trimmed().isEmpty())return false;
    finish("found",synced,plain);
    return true;
}
void Lyrics::get(int g,QUrl url,std::function<void(QByteArray)> done){
    QNetworkRequest req(url);
    req.setRawHeader("User-Agent",QCoreApplication::applicationName().toUtf8()+" "+QCoreApplication::applicationVersion().toUtf8()+" (desktop)");
    req.setAttribute(QNetworkRequest::RedirectPolicyAttribute,QNetworkRequest::NoLessSafeRedirectPolicy);
    auto *r=network.get(req);
    connect(r,&QNetworkReply::finished,this,[this,r,g,done]{
        r->deleteLater();if(g!=generation)return;
        const int code=r->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        if(code==404){done({});return;}
        if(code<200 || code>=300 || r->error()!=QNetworkReply::NoError){finish("failed");return;}
        done(r->readAll());
    });
}
void Lyrics::search(int g,QString title,QString artist){
    QUrl url("https://lrclib.net/api/search");
    QUrlQuery q;q.addQueryItem("track_name",title);q.addQueryItem("artist_name",artist);url.setQuery(q);
    get(g,url,[this](QByteArray body){
        // No exact match: take the first search result that has any lyrics.
        for(const auto &v:QJsonDocument::fromJson(body).array())if(apply(v.toObject()))return;
        finish("notfound");
    });
}
void Lyrics::load(QString uri,QString title,QString artist,QString album,qint64 durationMs){
    if(uri.isEmpty()){clear();return;}
    if(uri==loadedUri && (status=="loading" || status=="found" || status=="notfound"))return;
    loadedUri=uri;const int g=++generation;
    finish("loading");
    QUrl url("https://lrclib.net/api/get");
    QUrlQuery q;q.addQueryItem("track_name",title);q.addQueryItem("artist_name",artist);
    if(!album.isEmpty())q.addQueryItem("album_name",album);
    if(durationMs>0)q.addQueryItem("duration",QString::number(durationMs/1000));
    url.setQuery(q);
    get(g,url,[this,g,title,artist](QByteArray body){
        if(!body.isEmpty() && apply(QJsonDocument::fromJson(body).object()))return;
        search(g,title,artist);
    });
}
