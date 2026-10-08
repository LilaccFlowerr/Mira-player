// Android build: Qt WebEngine and the Web Playback SDK are not available, so the
// built-in player only explains how to play through the Spotify app instead.
#include "WebPlayback.h"
#include "OAuth.h"
namespace {
const char *unavailable="Built-in playback is not available on Android. Open the Spotify app on this phone, then choose it under devices.";
}
WebPlayback::WebPlayback(OAuth *a,QObject *parent):QObject(parent),auth(a){info=QString::fromLatin1(unavailable);}
WebPlayback::~WebPlayback()=default;
void WebPlayback::control(QString,int){}
void WebPlayback::start(){info=QString::fromLatin1(unavailable);emit changed();}
void WebPlayback::stop(){}
void WebPlayback::diagnose(){info=QString::fromLatin1(unavailable);emit changed();}
