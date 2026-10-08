#include "Preferences.h"
QString Preferences::clientId() const { auto env=qEnvironmentVariable("SPOTIFY_CLIENT_ID"); return env.isEmpty()?settings.value("clientId").toString():env; }
void Preferences::setClientId(QString v){settings.setValue("clientId",v.trimmed());emit changed();}
void Preferences::setDark(bool v){settings.setValue("dark",v);emit changed();}
void Preferences::setMinutes(int v){settings.setValue("minutes",qBound(5,v,120));emit changed();}
QString Preferences::mood() const {
    // Settings written by Dutch builds before 0.4 are mapped to the English names.
    const auto v=settings.value("mood","Calm").toString();
    return v=="Rust"?"Calm":v=="Helder"?"Bright":v=="Ruimte"?"Space":v;
}
void Preferences::setMood(QString v){if(QStringList{"Calm","Bright","Space"}.contains(v)){settings.setValue("mood",v);emit changed();}}
void Preferences::setAutoStartPlayer(bool v){settings.setValue("autoStartPlayer",v);emit changed();}
void Preferences::reset(){settings.clear();emit changed();}

void Preferences::setAccent(int v){settings.setValue("accent",qBound(0,v,2));emit changed();}
