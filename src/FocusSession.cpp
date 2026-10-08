#include "FocusSession.h"
FocusSession::FocusSession(QObject *p):QObject(p){timer.setInterval(250);connect(&timer,&QTimer::timeout,this,[this]{if(remaining()==0){timer.stop();saved=0;done=true;}emit changed();});}
int FocusSession::remaining() const{return running()?qMax(0,saved-int(elapsed.elapsed()/1000)):saved;}
void FocusSession::start(int m){duration=qBound(5,m,120)*60;saved=duration;done=false;elapsed.start();timer.start();emit changed();}
void FocusSession::pause(){saved=remaining();timer.stop();emit changed();}
void FocusSession::resume(){if(saved>0){elapsed.start();timer.start();emit changed();}}
void FocusSession::reset(){timer.stop();saved=duration;done=false;emit changed();}
