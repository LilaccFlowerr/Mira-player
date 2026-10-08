#include "TokenStore.h"
#include "AppConfig.h"
#include <QtConcurrent>
#include <QFutureWatcher>
#include <QProcess>
#include <QSettings>
#include <QStandardPaths>
#ifdef Q_OS_WIN
#include <windows.h>
#include <wincred.h>
#elif defined(Q_OS_MACOS)
#include <Security/Security.h>
#endif
namespace {
using Result = QPair<bool,QByteArray>;
Result vault(int op, const QString &service, const QString &account, const QByteArray &token) {
#ifdef Q_OS_WIN
    const auto target = service + "/" + account;
    const auto name = target.toStdWString();
    if(op == 0) {
        PCREDENTIALW cred = nullptr;
        if(!CredReadW(name.c_str(), CRED_TYPE_GENERIC, 0, &cred)) return {GetLastError()==ERROR_NOT_FOUND,{}};
        QByteArray data(reinterpret_cast<char*>(cred->CredentialBlob), int(cred->CredentialBlobSize));
        CredFree(cred); return {true,data};
    }
    if(op == 2) return {bool(CredDeleteW(name.c_str(),CRED_TYPE_GENERIC,0)) || GetLastError()==ERROR_NOT_FOUND,{}};
    CREDENTIALW cred{}; cred.Type=CRED_TYPE_GENERIC; cred.TargetName=const_cast<wchar_t*>(name.c_str());
    cred.CredentialBlobSize=DWORD(token.size()); cred.CredentialBlob=reinterpret_cast<LPBYTE>(const_cast<char*>(token.constData()));
    cred.Persist=CRED_PERSIST_LOCAL_MACHINE; return {bool(CredWriteW(&cred,0)),{}};
#elif defined(Q_OS_MACOS)
    auto a=account.toUtf8();
    const auto serviceName=service.toUtf8();
    auto serviceRef=CFStringCreateWithCString(nullptr,serviceName.constData(),kCFStringEncodingUTF8);
    auto user=CFStringCreateWithCString(nullptr,a.constData(),kCFStringEncodingUTF8);
    auto query=CFDictionaryCreateMutable(nullptr,0,&kCFTypeDictionaryKeyCallBacks,&kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(query,kSecClass,kSecClassGenericPassword);
    CFDictionarySetValue(query,kSecAttrService,serviceRef); CFDictionarySetValue(query,kSecAttrAccount,user);
    OSStatus status; QByteArray result;
    if(op==0) {
        CFDictionarySetValue(query,kSecReturnData,kCFBooleanTrue);
        CFTypeRef data=nullptr; status=SecItemCopyMatching(query,&data);
        if(status==errSecSuccess) { auto d=static_cast<CFDataRef>(data); result=QByteArray(reinterpret_cast<const char*>(CFDataGetBytePtr(d)),CFDataGetLength(d)); CFRelease(data); }
    } else if(op==2) status=SecItemDelete(query);
    else {
        auto data=CFDataCreate(nullptr,reinterpret_cast<const UInt8*>(token.constData()),token.size());
        auto attrs=CFDictionaryCreateMutable(nullptr,0,&kCFTypeDictionaryKeyCallBacks,&kCFTypeDictionaryValueCallBacks);
        CFDictionarySetValue(attrs,kSecValueData,data); status=SecItemUpdate(query,attrs);
        if(status==errSecItemNotFound) { CFDictionarySetValue(query,kSecValueData,data); status=SecItemAdd(query,nullptr); }
        CFRelease(attrs); CFRelease(data);
    }
    CFRelease(query); CFRelease(user); CFRelease(serviceRef);
    return {status==errSecSuccess || (op!=1 && status==errSecItemNotFound),result};
#elif defined(Q_OS_ANDROID)
    // Android has no Secret Service. The token lives in the app's private data directory, which
    // other apps cannot read (Android sandbox). Moving it into the Android Keystore is a follow-up.
    QSettings store(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)+"/tokens.ini",QSettings::IniFormat);
    const QString key=QString(service).replace('/','_')+"/"+account;
    if(op==0) return {true,store.value(key).toByteArray()};
    if(op==1) store.setValue(key,token); else store.remove(key);
    store.sync();
    return {store.status()==QSettings::NoError,{}};
#else
    // libsecret's maintained CLI talks to Secret Service (GNOME Keyring/KWallet).
    // Secret goes through stdin, never through argv, shell, files or diagnostics.
    QProcess process;
    QStringList args;
    if(op==0) args << "lookup";
    else if(op==1) args << "store" << "--label=" + QString::fromLatin1(AppConfig::name) + " Spotify";
    else args << "clear";
    args << "application" << service << "account" << account;
    process.start("/usr/bin/secret-tool",args);
    if(!process.waitForStarted(3000)) return {false,{}};
    if(op==1) process.write(token);
    process.closeWriteChannel();
    if(!process.waitForFinished(20000)) { process.kill(); process.waitForFinished(); return {false,{}}; }
    auto err=process.readAllStandardError();
    const bool ok=process.exitStatus()==QProcess::NormalExit && (process.exitCode()==0 || (op!=1 && process.exitCode()==1 && err.isEmpty()));
    return {ok,op==0 && ok ? process.readAllStandardOutput().trimmed() : QByteArray{}};
#endif
}
}
TokenStore::TokenStore(QObject *p):QObject(p) { pool.setMaxThreadCount(1); }
TokenStore::~TokenStore() { pool.waitForDone(); }
void TokenStore::run(int op,QString a,QByteArray t,Callback cb) {
    auto *w=new QFutureWatcher<Result>(this);
    connect(w,&QFutureWatcher<Result>::finished,this,[w,cb]{ const auto r=w->result(); w->deleteLater(); cb(r.first,r.second); });
    w->setFuture(QtConcurrent::run(&pool,[op,a,t]{
        const QString service=QString::fromLatin1(AppConfig::id);
        auto result=vault(op,service,a,t);
        // Builds before the rename stored the token as "io.github.luwte". Move it once, on first read.
        if(op==0 && result.first && result.second.isEmpty()) {
            const QString legacy="io.github.luwte";
            const auto old=vault(0,legacy,a,{});
            if(old.first && !old.second.isEmpty() && vault(1,service,a,old.second).first) { vault(2,legacy,a,{}); result=old; }
        }
        return result;
    }));
}
void TokenStore::read(const QString &a,Callback cb){run(0,a,{},cb);}
void TokenStore::write(const QString &a,const QByteArray &t,Callback cb){run(1,a,t,cb);}
void TokenStore::remove(const QString &a,Callback cb){run(2,a,{},cb);}
