#include "Mpris.h"
#include "SpotifyApi.h"
#include "AppConfig.h"
#include <QDBusConnection>
#include <QDBusMessage>
#include <QCoreApplication>
#include <QRegularExpression>
namespace {
const QString objectPath="/org/mpris/MediaPlayer2";
const QString noTrack="/org/mpris/MediaPlayer2/TrackList/NoTrack";
QString trackPath(const QVariantMap &track){
    const auto id=track.value("id").toString();
    return QRegularExpression("^[A-Za-z0-9]+$").match(id).hasMatch()?"/io/github/mira/track/"+id:noTrack;
}
}
Mpris::Mpris(SpotifyApi *api,QObject *parent):QObject(parent),spotify(api){
    new MprisRoot(this);
    auto *player=new MprisPlayer(this);
    connect(spotify,&SpotifyApi::seeked,player,[player](qint64 ms){emit player->Seeked(ms*1000);});
    connect(spotify,&SpotifyApi::playbackChanged,this,&Mpris::sync);
    connect(spotify,&SpotifyApi::changed,this,&Mpris::sync);
    auto bus=QDBusConnection::sessionBus();
    if(!bus.isConnected() || !bus.registerObject(objectPath,this,QDBusConnection::ExportAdaptors))return;
    // Bus name elements allow only [A-Za-z0-9_-]; APP_NAME may be overridden at configure time.
    auto name=QString(AppConfig::name).toLower().replace(QRegularExpression("[^a-z0-9_]"),"_");
    if(name.isEmpty() || name.front().isDigit())name.prepend("mira_");
    service="org.mpris.MediaPlayer2."+name;
    if(!bus.registerService(service)){
        service+=".instance"+QString::number(QCoreApplication::applicationPid());
        if(!bus.registerService(service)){service.clear();return;}
    }
    published=playerProperties();
}
Mpris::~Mpris(){
    if(service.isEmpty())return;
    auto bus=QDBusConnection::sessionBus();
    bus.unregisterService(service);bus.unregisterObject(objectPath);
}
QString Mpris::playbackStatus()const{
    const auto track=spotify->playback();
    if(track.value("uri").toString().isEmpty())return "Stopped";
    return track.value("playing").toBool()?"Playing":"Paused";
}
bool Mpris::can(const QString &action)const{
    const auto track=spotify->playback();
    if(!spotify->connected() || spotify->deviceId().isEmpty() || track.value("uri").toString().isEmpty() || track.value("restricted").toBool())return false;
    return !track.value("disallows").toMap().value(action).toBool();
}
QVariantMap Mpris::metadata()const{
    const auto track=spotify->playback();
    if(track.value("uri").toString().isEmpty())return {{"mpris:trackid",QVariant::fromValue(QDBusObjectPath(noTrack))}};
    QVariantMap data{
        {"mpris:trackid",QVariant::fromValue(QDBusObjectPath(trackPath(track)))},
        {"mpris:length",qlonglong(track.value("duration").toLongLong()*1000)},
        {"xesam:title",track.value("name").toString()},
        {"xesam:artist",track.value("artists").toStringList()},
        {"xesam:album",track.value("album").toString()},
    };
    if(!track.value("cover").toString().isEmpty())data["mpris:artUrl"]=track.value("cover").toString();
    if(!track.value("url").toString().isEmpty())data["xesam:url"]=track.value("url").toString();
    return data;
}
QVariantMap Mpris::playerProperties()const{
    const auto track=spotify->playback();
    const auto repeat=track.value("repeat").toString();
    return {
        {"PlaybackStatus",playbackStatus()},
        {"LoopStatus",repeat=="track"?"Track":repeat=="context"?"Playlist":"None"},
        {"Shuffle",track.value("shuffle").toBool()},
        {"Metadata",metadata()},
        {"Volume",track.value("volume",0).toDouble()/100.0},
        {"CanGoNext",can("skipping_next")},{"CanGoPrevious",can("skipping_prev")},
        {"CanPlay",can("resuming")},{"CanPause",can("pausing")},{"CanSeek",can("seeking")},
    };
}
void Mpris::sync(){
    if(service.isEmpty())return;
    const auto next=playerProperties();
    QVariantMap changed;
    for(auto it=next.cbegin();it!=next.cend();++it)if(published.value(it.key())!=it.value())changed.insert(it.key(),it.value());
    published=next;
    if(changed.isEmpty())return;
    auto signal=QDBusMessage::createSignal(objectPath,"org.freedesktop.DBus.Properties","PropertiesChanged");
    signal<<QString("org.mpris.MediaPlayer2.Player")<<changed<<QStringList();
    QDBusConnection::sessionBus().send(signal);
}

QString MprisRoot::identity()const{return QString::fromUtf8(AppConfig::name);}
QString MprisRoot::desktopEntry()const{return QString::fromLatin1(AppConfig::id);}

MprisPlayer::MprisPlayer(Mpris *o):QDBusAbstractAdaptor(o),owner(o){}
QString MprisPlayer::loopStatus()const{return owner->playerProperties().value("LoopStatus").toString();}
void MprisPlayer::setLoopStatus(const QString &status){
    if(status=="None")owner->spotify->setRepeat("off");
    else if(status=="Playlist")owner->spotify->setRepeat("context");
    else if(status=="Track")owner->spotify->setRepeat("track");
}
bool MprisPlayer::shuffle()const{return owner->spotify->playback().value("shuffle").toBool();}
void MprisPlayer::setShuffle(bool enabled){owner->spotify->setShuffle(enabled);}
double MprisPlayer::volume()const{return owner->spotify->playback().value("volume",0).toDouble()/100.0;}
void MprisPlayer::setVolume(double v){owner->spotify->setVolume(qRound(qBound(0.0,v,1.0)*100));}
qlonglong MprisPlayer::position()const{return owner->spotify->position()*1000;}
void MprisPlayer::Next(){if(canGoNext())owner->spotify->command("next");}
void MprisPlayer::Previous(){if(canGoPrevious())owner->spotify->command("previous");}
void MprisPlayer::Pause(){if(owner->spotify->playback().value("playing").toBool())owner->spotify->command("pause");}
void MprisPlayer::Play(){if(!owner->spotify->playback().value("playing").toBool())owner->spotify->play();}
void MprisPlayer::Stop(){Pause();}
void MprisPlayer::PlayPause(){owner->spotify->togglePlayback();}
void MprisPlayer::Seek(qlonglong offset){
    if(!canSeek())return;
    const qint64 target=owner->spotify->position()+offset/1000;
    const qint64 duration=owner->spotify->playback().value("duration").toLongLong();
    if(duration>0 && target>=duration){Next();return;}
    owner->spotify->seek(qMax<qint64>(0,target));
}
void MprisPlayer::SetPosition(const QDBusObjectPath &track,qlonglong position){
    const qint64 duration=owner->spotify->playback().value("duration").toLongLong();
    if(!canSeek() || track.path()!=trackPath(owner->spotify->playback()) || position<0 || position/1000>duration)return;
    owner->spotify->seek(position/1000);
}
