#pragma once
#include <QObject>
#include <QSettings>
class Preferences : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString clientId READ clientId WRITE setClientId NOTIFY changed)
    Q_PROPERTY(int accent READ accent WRITE setAccent NOTIFY changed)
    Q_PROPERTY(bool dark READ dark WRITE setDark NOTIFY changed)
    Q_PROPERTY(bool autoStartPlayer READ autoStartPlayer WRITE setAutoStartPlayer NOTIFY changed)
    // 0 = sharp, 1 = default, 2 = extra round
    Q_PROPERTY(int roundness READ roundness WRITE setRoundness NOTIFY changed)
    // 0 = default, 1 = serif, 2 = monospace
    Q_PROPERTY(int fontStyle READ fontStyle WRITE setFontStyle NOTIFY changed)
    // 0 = small, 1 = default, 2 = large
    Q_PROPERTY(int textSize READ textSize WRITE setTextSize NOTIFY changed)
    Q_PROPERTY(bool trueBlack READ trueBlack WRITE setTrueBlack NOTIFY changed)
    Q_PROPERTY(bool pauseOnClose READ pauseOnClose WRITE setPauseOnClose NOTIFY changed)
    Q_PROPERTY(bool fancyPlayer READ fancyPlayer WRITE setFancyPlayer NOTIFY changed)
    Q_PROPERTY(bool lyrics READ lyrics WRITE setLyrics NOTIFY changed)
    Q_PROPERTY(QStringList recentSearches READ recentSearches NOTIFY changed)
public:
    using QObject::QObject;
    QString clientId() const;
    int accent() const { return settings.value("accent",0).toInt(); }
    void setAccent(int v);
    bool dark() const { return settings.value("dark",true).toBool(); }
    bool autoStartPlayer() const { return settings.value("autoStartPlayer",true).toBool(); }
    void setClientId(QString v); void setDark(bool v); void setAutoStartPlayer(bool v);
    int roundness() const { return settings.value("roundness",1).toInt(); }
    int fontStyle() const { return settings.value("fontStyle",0).toInt(); }
    int textSize() const { return settings.value("textSize",1).toInt(); }
    bool trueBlack() const { return settings.value("trueBlack",false).toBool(); }
    bool pauseOnClose() const { return settings.value("pauseOnClose",false).toBool(); }
    bool fancyPlayer() const { return settings.value("fancyPlayer",true).toBool(); }
    void setFancyPlayer(bool v);
    bool lyrics() const { return settings.value("lyrics",true).toBool(); }
    QStringList recentSearches() const { return settings.value("recentSearches").toStringList(); }
    void setRoundness(int v); void setFontStyle(int v); void setTextSize(int v); void setTrueBlack(bool v); void setPauseOnClose(bool v); void setLyrics(bool v);
    // Newest first, no duplicates (ignoring case), at most 8.
    Q_INVOKABLE void rememberSearch(QString term); Q_INVOKABLE void clearRecentSearches();
    Q_INVOKABLE void reset();
signals: void changed();
private: QSettings settings;
};
