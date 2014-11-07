@echo off
del *.tpp
del fastuue.exe
del resmain.exe
del main.dll
bpc -B -M -CP -$A+ -$D- -$G+ -$I- -$L- -$N+ -$S- -$Y- -DSOLID -DCUSTOMSOLID FASTUUE.PAS
del fastuuec.exe
ren fastuue.exe fastuuec.exe
