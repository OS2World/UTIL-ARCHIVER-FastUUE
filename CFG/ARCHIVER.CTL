[RAR]
Name RAR
Ext RAR

Unpack.Single.File ,rar.exe x -std -av- -c- %archive %filename %targetslash
Unpack.All.Files ,rar.exe x -std -av- -c- %archive %targetslash
Pack.Single.File ,rar.exe a -std -av- -c- -ep1 %archive %filename
Pack.All.Files ,rar.exe a -std -av- -c- -ep1 %archive %sourceslash

[ARJ]
Name ARJ
Ext ARJ
Unpack.Single.File ,arj.exe x -y %archive %filename %targetslash
Unpack.All.Files %target,arj.exe x -y -r %archive *.*
Pack.Single.File %source,arj.exe a -y -e1 %archive %jfilename
Pack.All.Files %source,arj.exe a -y -r -e1 %archive *.*

[HA]
Name HA
Ext HA
Unpack.Single.File %target,c:\tools\ha.exe xy %archive %filename
Unpack.All.Files %target,c:\tools\ha.exe xy %archive
Pack.Single.File %source,c:\tools\ha.exe a2q %archive %jfilename
Pack.All.Files %source,c:\tools\ha.exe ar2q %archive *.*

[ZIP]
Name PKZIP
Ext ZIP
Unpack.Single.File %target,pkunzip.exe -d -o %archive %filename
Unpack.All.Files %target,pkunzip.exe -d -o %archive
Pack.Single.File %source,pkzip.exe -) %archive %filename
Pack.All.Files %source,pkzip.exe -) -r %archive
