set path=%path%;\VP20\bin.W32
deltree /Y EXE\W32\


rem � �⫠��筮� ���ଠ樥�
vpc -DSOLID -T -$LocInfo+ -$Zd+ -$D+ fastuue.pas

rem ��� �⫠��筮� ���ଠ樨
rem vpc -DSOLID fastuue.pas


cd EXE\W32
ren FASTUUE.EXE fuue32s.exe
cd ..\..
