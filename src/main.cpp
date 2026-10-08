#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QIcon>
#include <QSettings>
#include <QQuickWindow>
#include <QCommandLineParser>
#include <QTextStream>
#include "AppConfig.h"
#include "Preferences.h"
#include "OAuth.h"
#include "SpotifyApi.h"
#include "FocusSession.h"
#include "WebPlayback.h"
#include <QtWebEngineQuick/qtwebenginequickglobal.h>
#ifdef MIRA_MPRIS
#include "Mpris.h"
#endif
int main(int argc,char **argv){
#ifdef MIRA_MPRIS
    // Mira publishes its own MPRIS player; keep Chromium from adding a second, anonymous one.
    auto chromiumFlags=qEnvironmentVariable("QTWEBENGINE_CHROMIUM_FLAGS");
    if(!chromiumFlags.contains("--disable-features")){
        chromiumFlags+=" --disable-features=HardwareMediaKeyHandling,MediaSessionService";
        qputenv("QTWEBENGINE_CHROMIUM_FLAGS",chromiumFlags.trimmed().toUtf8());
    }
#endif
    QtWebEngineQuick::initialize();
    QGuiApplication app(argc,argv);
    app.setOrganizationName("Mira");app.setOrganizationDomain(AppConfig::id);
    app.setApplicationName(AppConfig::name);app.setApplicationVersion(AppConfig::version);
    app.setWindowIcon(QIcon(":/assets/mira.png"));app.setDesktopFileName(AppConfig::id);
    QQuickStyle::setStyle("Material");
    {
        // One-time move of settings from builds released as "Luwte".
        QSettings current;
        if(current.allKeys().isEmpty()) {
#ifdef Q_OS_MACOS
            QSettings legacy("io.github.luwte","Luwte");
#else
            QSettings legacy("Luwte","Luwte");
#endif
            for(const auto &key:legacy.allKeys())current.setValue(key,legacy.value(key));
        }
    }
    QCommandLineParser parser;parser.addHelpOption();parser.addVersionOption();
    parser.addOption({"capture", "Save a local UI preview and exit (use an isolated config directory).", "png"});
    parser.addOption({"page", "Initial page for a local UI preview: 0, 1 or 2.", "index", "0"});
    parser.addOption({"audio-check", "Check local Widevine/AAC support without contacting Spotify, then exit."});
    parser.addOption({"compact", "Open at the minimum supported window size."});
    parser.process(app);
    Preferences prefs;OAuth auth(&prefs,nullptr,!parser.isSet("audio-check"));SpotifyApi spotify(&auth);WebPlayback localPlayer(&auth);FocusSession focus;
    QObject::connect(&localPlayer,&WebPlayback::localRequested,&spotify,&SpotifyApi::prepareLocalPlayback);
    QObject::connect(&localPlayer,&WebPlayback::deviceChanged,&spotify,&SpotifyApi::setLocalDevice);
    QObject::connect(&localPlayer,&WebPlayback::playbackState,&spotify,&SpotifyApi::updateLocalPlayback);
    QObject::connect(&spotify,&SpotifyApi::localControl,&localPlayer,&WebPlayback::control);
    if(parser.isSet("audio-check")){
        QObject::connect(&localPlayer,&WebPlayback::changed,&app,[&]{
            if(!localPlayer.busy()){QTextStream(stdout)<<localPlayer.status()<<Qt::endl;app.quit();}
        });
        QTimer::singleShot(0,&localPlayer,&WebPlayback::diagnose);
        return app.exec();
    }
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("initialPage",qBound(0,parser.value("page").toInt(),2));
    engine.rootContext()->setContextProperty("prefs",&prefs);
    engine.rootContext()->setContextProperty("auth",&auth);
    engine.rootContext()->setContextProperty("spotify",&spotify);
    engine.rootContext()->setContextProperty("localPlayer",&localPlayer);
    engine.rootContext()->setContextProperty("focusSession",&focus);
    engine.rootContext()->setContextProperty("appName",AppConfig::name);
    engine.rootContext()->setContextProperty("appVersion",AppConfig::version);
    QObject::connect(&engine,&QQmlApplicationEngine::objectCreationFailed,&app,[]{QCoreApplication::exit(1);},Qt::QueuedConnection);
    engine.loadFromModule("Mira","Main");
    if(!engine.rootObjects().isEmpty()) {
        auto *window=qobject_cast<QQuickWindow*>(engine.rootObjects().first());
        if(window && parser.isSet("compact"))window->resize(640,680);
#ifdef MIRA_MPRIS
        if(window && !parser.isSet("capture")){
            auto *mpris=new Mpris(&spotify,&app);
            QObject::connect(mpris,&Mpris::raiseRequested,window,[window]{window->show();window->raise();window->requestActivate();});
            QObject::connect(mpris,&Mpris::quitRequested,&app,&QCoreApplication::quit);
        }
#endif
        if(window && parser.isSet("capture"))QTimer::singleShot(1200,&app,[window,&app,&parser]{app.exit(window->grabWindow().save(parser.value("capture"))?0:2);});
    }
    return app.exec();
}
