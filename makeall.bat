deltree /Y COMPLETE\
md COMPLETE
md COMPLETE\DOS
md COMPLETE\W32
md COMPLETE\OS2

call make386.bat
move fastuue.exe COMPLETE\
move resman.exe COMPLETE\
move main.dll COMPLETE\
move *.dll COMPLETE\DOS\

call make386s.bat
move fastuues.exe COMPLETE\

call make32.bat
move EXE\W32\fuue32.exe COMPLETE\
move EXE\W32\resman32.exe COMPLETE\
move EXE\W32\main32.dll COMPLETE\
move EXE\W32\*.dll COMPLETE\W32\

call make32s.bat
move EXE\W32\fuue32s.exe COMPLETE\

call make2.bat
move EXE\OS2\fuue2.exe COMPLETE\
move EXE\OS2\resman2.exe COMPLETE\
move EXE\OS2\main2.dll COMPLETE\
move EXE\OS2\*.dll COMPLETE\OS2\

call make2s.bat
move EXE\OS2\fuue2s.exe COMPLETE\

copy /Y README.TXT COMPLETE
copy /Y CHANGES.TXT COMPLETE
xcopy CFG COMPLETE\CFG /E /I /H /R /Y
xcopy LNG COMPLETE\LNG /E /I /H /R /Y
xcopy TEMPLATE COMPLETE\TEMPLATE /E /I /H /R /Y
xcopy XLT COMPLETE\XLT /E /I /H /R /Y
xcopy Addon COMPLETE\Addon /E /I /H /R /Y

del *.tpp
deltree /Y EXE\OS2\
deltree /Y EXE\W32\
