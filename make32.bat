set path=%path%;\VP20\bin.W32
deltree /Y EXE\W32\
copy /Y MAIN.PAS MAIN32.PAS
vpc %1 MAIN32.PAS
del MAIN32.PAS
cd EXE\W32
ren main32.lib main.lib
cd ..\..
vpc ARCHIVER.PAS
vpc COMMON.PAS
vpc crax.PAS
vpc EMAIL.PAS
vpc FILES.PAS
vpc FILESBBS.PAS
vpc H.PAS
vpc HATCHER.PAS
vpc ICQ.PAS
vpc SCAN.PAS
vpc UUE.PAS
vpc TWIT.PAS
vpc STAT.PAS
vpc SEENBY.PAS
vpc PATHBLD.PAS
vpc NS.PAS
vpc MSGOUT.PAS
vpc LOGCUT.PAS
vpc dob.PAS
vpc gate.pas
vpc BINKSTAT.PAS
vpc ANNOUNCE.PAS

vpc FASTUUE.PAS
vpc RESMAN.PAS
cd EXE\W32
ren FASTUUE.EXE fuue32.exe
ren RESMAN.EXE resman32.exe
cd ..\..