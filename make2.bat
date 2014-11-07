set path=%path%;\VP20\bin.W32
deltree /Y EXE\OS2\
copy /Y MAIN.PAS MAIN2.PAS
vpc -CO %1 MAIN2.PAS
del MAIN2.PAS
cd EXE\OS2
ren main2.lib main.lib
cd ..\..
vpc -CO ARCHIVER.PAS
vpc -CO COMMON.PAS
vpc -CO crax.PAS
vpc -CO EMAIL.PAS
vpc -CO FILES.PAS
vpc -CO FILESBBS.PAS
vpc -CO H.PAS
vpc -CO HATCHER.PAS
vpc -CO ICQ.PAS
vpc -CO SCAN.PAS
vpc -CO UUE.PAS
vpc -CO TWIT.PAS
vpc -CO STAT.PAS
vpc -CO SEENBY.PAS
vpc -CO PATHBLD.PAS
vpc -CO NS.PAS
vpc -CO MSGOUT.PAS
vpc -CO LOGCUT.PAS
vpc -CO dob.PAS
vpc -CO gate.pas
vpc -CO BINKSTAT.PAS
vpc -CO ANNOUNCE.PAS

vpc -CO FASTUUE.PAS
vpc -CO RESMAN.PAS
cd EXE\OS2
ren FASTUUE.EXE fuue2.exe
ren RESMAN.EXE resman2.exe
cd ..\..