set path=%path%;\VP20\bin.W32
deltree /Y EXE\W32\


rem С отладочной информацией
vpc -DSOLID -DCUSTOMSOLID -T -$LocInfo+ -$Zd+ -$D+ fastuue.pas

rem Без отладочной информации
rem vpc -DSOLID -DCUSTOMSOLID fastuue.pas


cd EXE\W32
ren FASTUUE.EXE fuue32c.exe
cd ..\..
