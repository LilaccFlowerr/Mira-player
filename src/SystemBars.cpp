#include "SystemBars.h"
#ifdef Q_OS_ANDROID
#include <QCoreApplication>
#include <QJniObject>
#include <QVariant>
#endif
void SystemBars::apply(QColor background,bool dark){
#ifdef Q_OS_ANDROID
    const jint argb=jint(background.rgba());
    const bool lightIcons=dark;
    // Window changes must happen on Android's UI thread.
    QNativeInterface::QAndroidApplication::runOnAndroidMainThread([argb,lightIcons]()->QVariant{
        QJniObject activity(QNativeInterface::QAndroidApplication::context());
        if(!activity.isValid())return {};
        QJniObject window=activity.callObjectMethod("getWindow","()Landroid/view/Window;");
        if(!window.isValid())return {};
        constexpr jint translucentStatus=0x04000000, translucentNavigation=0x08000000;
        constexpr jint drawsSystemBarBackgrounds=jint(0x80000000u);
        window.callMethod<void>("clearFlags","(I)V",jint(translucentStatus|translucentNavigation));
        window.callMethod<void>("addFlags","(I)V",drawsSystemBarBackgrounds);
        window.callMethod<void>("setStatusBarColor","(I)V",argb);
        window.callMethod<void>("setNavigationBarColor","(I)V",argb);
        // Dark icons on a light background and the other way round.
        QJniObject decor=window.callObjectMethod("getDecorView","()Landroid/view/View;");
        if(decor.isValid()){
            constexpr jint lightStatusBar=0x2000, lightNavigationBar=0x10;
            jint flags=decor.callMethod<jint>("getSystemUiVisibility","()I");
            flags=lightIcons?(flags&~(lightStatusBar|lightNavigationBar)):(flags|lightStatusBar|lightNavigationBar);
            decor.callMethod<void>("setSystemUiVisibility","(I)V",flags);
        }
        return {};
    });
#else
    Q_UNUSED(background);Q_UNUSED(dark);
#endif
}
