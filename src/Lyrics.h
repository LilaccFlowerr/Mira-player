#pragma once
#include <QObject>
#include <QNetworkAccessManager>
#include <QVariantList>
// Looks lyrics up on lrclib.net (free, no account). Only the song, artist and album name and the duration are sent.
class Lyrics : public QObject {
    Q_OBJECT
    // idle, loading, notfound, failed or found
    Q_PROPERTY(QString state READ state NOTIFY changed)
    // Lines of {time (ms), text}; empty when only plain lyrics exist.
    Q_PROPERTY(QVariantList synced READ synced NOTIFY changed)
    Q_PROPERTY(QString plain READ plain NOTIFY changed)
public:
    explicit Lyrics(QObject *parent=nullptr);
    QString state()const{return status;} QVariantList synced()const{return lines;} QString plain()const{return text;}
    Q_INVOKABLE void load(QString uri,QString title,QString artist,QString album,qint64 durationMs);
    Q_INVOKABLE void clear();
    // Index of the line being sung at this position, or -1 before the first line.
    Q_INVOKABLE int lineAt(qint64 ms)const;
    static QList<QPair<qint64,QString>> parseLrc(const QString &lrc);
signals:
    void changed();
private:
    QNetworkAccessManager network;
    QString status="idle",text,loadedUri;
    QVariantList lines;
    QList<qint64> times;
    int generation=0;
    void finish(QString state,QVariantList synced={},QString plain={});
    bool apply(const QJsonObject &object);
    void search(int g,QString title,QString artist);
    void get(int g,QUrl url,std::function<void(QByteArray)> done);
};
