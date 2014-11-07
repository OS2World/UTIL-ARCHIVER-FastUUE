set path=%path%;\VP20\bin.W32
deltree /Y EXE\OS2\


rem С отладочной информацией
vpc -CO -DSOLID -T -$LocInfo+ -$Zd+ -$D+ fastuue.pas

rem Без отладочной информации
rem vpc -CO -DSOLID fastuue.pas


cd EXE\OS2
ren FASTUUE.EXE fuue2s.exe
cd ..\..
