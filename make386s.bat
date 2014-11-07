@echo off
del *.tpp
del fastuue.exe
del resmain.exe
del main.dll
bpc -B -M -CP -$A+ -$D- -$G+ -$I- -$L- -$N+ -$S- -$Y- -DSOLID FASTUUE.PAS
del fastuues.exe
ren fastuue.exe fastuues.exe
