#pragma once
#include <QObject>
#include <QThreadPool>
#include <functional>
// All vault operations are serialized off the GUI thread. No plaintext fallback.
class TokenStore : public QObject {
    Q_OBJECT
public:
    explicit TokenStore(QObject *parent = nullptr);
    ~TokenStore() override;
    using Callback = std::function<void(bool, QByteArray)>;
    void read(const QString &account, Callback callback);
    void write(const QString &account, const QByteArray &token, Callback callback);
    void remove(const QString &account, Callback callback);
private:
    QThreadPool pool;
    void run(int operation, QString account, QByteArray token, Callback callback);
};
