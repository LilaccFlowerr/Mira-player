#pragma once
#include <QObject>
#include <QTimer>
#include <QElapsedTimer>
class FocusSession : public QObject {
    Q_OBJECT
    Q_PROPERTY(int remaining READ remaining NOTIFY changed)
    Q_PROPERTY(int total READ total NOTIFY changed)
    Q_PROPERTY(bool running READ running NOTIFY changed)
    Q_PROPERTY(bool finished READ finished NOTIFY changed)
public:
    explicit FocusSession(QObject *p=nullptr);
    int remaining() const; int total() const{return duration;}
    bool running() const{return timer.isActive();} bool finished() const{return done;}
    Q_INVOKABLE void start(int minutes); Q_INVOKABLE void pause(); Q_INVOKABLE void resume(); Q_INVOKABLE void reset();
signals: void changed();
private: QTimer timer; QElapsedTimer elapsed; int duration=1500, saved=1500; bool done=false;
};
