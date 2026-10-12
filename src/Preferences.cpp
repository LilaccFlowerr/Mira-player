#include "Preferences.h"
QString Preferences::clientId() const { auto env=qEnvironmentVariable("SPOTIFY_CLIENT_ID"); return env.isEmpty()?settings.value("clientId").toString():env; }
void Preferences::setClientId(QString v){settings.setValue("clientId",v.trimmed());emit changed();}
void Preferences::setDark(bool v){settings.setValue("dark",v);emit changed();}
void Preferences::setAutoStartPlayer(bool v){settings.setValue("autoStartPlayer",v);emit changed();}
void Preferences::reset(){settings.clear();emit changed();}

void Preferences::setAccent(int v){settings.setValue("accent",qBound(0,v,8));emit changed();}
void Preferences::setRoundness(int v){settings.setValue("roundness",qBound(0,v,2));emit changed();}
void Preferences::setFontStyle(int v){settings.setValue("fontStyle",qBound(0,v,2));emit changed();}
void Preferences::setTextSize(int v){settings.setValue("textSize",qBound(0,v,2));emit changed();}
void Preferences::setTrueBlack(bool v){settings.setValue("trueBlack",v);emit changed();}
void Preferences::setPauseOnClose(bool v){settings.setValue("pauseOnClose",v);emit changed();}
void Preferences::setLyrics(bool v){settings.setValue("lyrics",v);emit changed();}
void Preferences::rememberSearch(QString term){
    term=term.trimmed();if(term.isEmpty())return;
    QStringList list=recentSearches();
    list.removeIf([&](const QString &s){return s.compare(term,Qt::CaseInsensitive)==0;});
    list.prepend(term);
    while(list.size()>8)list.removeLast();
    settings.setValue("recentSearches",list);emit changed();
}
void Preferences::clearRecentSearches(){settings.remove("recentSearches");emit changed();}
void Preferences::setFancyPlayer(bool v){settings.setValue("fancyPlayer",v);emit changed();}
