#pragma once
#include <QObject>
#include <QColor>
// Colours Android's status and navigation bars to match the app (they default to Qt's blue).
// A no-op on desktop platforms.
class SystemBars : public QObject {
    Q_OBJECT
public:
    using QObject::QObject;
    Q_INVOKABLE void apply(QColor background,bool dark);
};
