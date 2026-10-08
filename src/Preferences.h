#pragma once
#include <QObject>
#include <QSettings>
class Preferences : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString clientId READ clientId WRITE setClientId NOTIFY changed)
    Q_PROPERTY(int accent READ accent WRITE setAccent NOTIFY changed)
    Q_PROPERTY(bool dark READ dark WRITE setDark NOTIFY changed)
    Q_PROPERTY(int minutes READ minutes WRITE setMinutes NOTIFY changed)
    Q_PROPERTY(QString mood READ mood WRITE setMood NOTIFY changed)
    Q_PROPERTY(bool autoStartPlayer READ autoStartPlayer WRITE setAutoStartPlayer NOTIFY changed)
public:
    using QObject::QObject;
    QString clientId() const;
    int accent() const { return settings.value("accent",0).toInt(); }
    void setAccent(int v);
    bool dark() const { return settings.value("dark",true).toBool(); }
    int minutes() const { return settings.value("minutes",25).toInt(); }
    QString mood() const;
    bool autoStartPlayer() const { return settings.value("autoStartPlayer",true).toBool(); }
    void setClientId(QString v); void setDark(bool v); void setMinutes(int v); void setMood(QString v); void setAutoStartPlayer(bool v);
    Q_INVOKABLE void reset();
signals: void changed();
private: QSettings settings;
};
