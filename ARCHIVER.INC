
const
 sraYeahhow                     = $00005666;
 snaCheck                       = $00005000;
 snaSearchArchive               = $00005010;
 snaGetExtension                = $00005011;
 snaUnpackSingle                = $00005012;
 snaUnpackAll                   = $00005013;
 snaPackSingle                  = $00005014;
 snaPackAll                     = $00005015;
 snaCheckArchiver               = $00005016;

function aCheck: Boolean;
 begin
  aCheck:=srvExecute('ARCHIVER', snaCheck, nil)=sraYeahhow;
 end;

function aSearchArchiver(Extension: String): String;
 begin
  sSetSemaphore('Archiver.Externals.Extension', Extension);
  srvExecute('ARCHIVER', snaSearchArchive, nil);
  aSearchArchiver:=sGetSemaphore('Archiver.Externals.Result');
 end;

function aGetExtension(Archiver: String): String;
 begin
  sSetSemaphore('Archiver.Externals.Archiver', Archiver);
  srvExecute('ARCHIVER', snaGetExtension, nil);
  aGetExtension:=sGetSemaphore('Archiver.Externals.Extension');
 end;

function aGetCommandLine(Archiver: String; ID: Longint): String;
 begin
  sSetSemaphore('Archiver.Externals.Archiver', Archiver);
  srvExecute('ARCHIVER', ID, nil);
  Archiver:=Ltrim(sGetSemaphore('Archiver.Externals.CommandLine'));
  if Copy(Archiver,1,1)=',' then Archiver:=' '+Archiver;
  aGetCommandLine:=Archiver;
 end;

function aExist(Archiver: String): boolean;
 begin
  sSetSemaphore('Archiver.Externals.Archiver', Archiver);
  srvExecute('ARCHIVER', snaCheckArchiver, nil);
  aExist:=sGetSemaphore('Archiver.Externals.Check')<>'';
 end;

function aIsArchive(Archive: String): boolean;
 begin
  aIsArchive:=aSearchArchiver(JustExtension(JustFileName(Archive)))<>'';
 end;

function aPushDir(S: String): String;
 var
  O: String;
 begin
  GetDir(0,O);
  if S<>'' then
   begin
    InOutRes:=0;
    ChDir(S);
    InOutRes:=0;
   end;
  aPushDir:=O;
 end;

procedure aPopDir(S: String);
 begin
  InOutRes:=0;
  ChDir(RemoveBackSlash(S));
  InOutRes:=0;
 end;

const
 _cArchive = '%archive';
 _cFilename = '%filename';
 _cJustFilename = '%jfilename';
 _cTarget = '%target';
 _cTargetSlash = '%targetslash';
 _cSource = '%source';
 _cSourceSlash = '%sourceslash';

function aExec(S: String): boolean;
 var
  A: Longint;
 begin
  A:=mExec(S);
  if A<>0 then
   begin
    lngBegin;
    lngPush(Long2Str(A));
    lngPush(S);
    lngPrint('Main','archiver.exec.bad');
    lngEnd;
    aExec:=False;
   end
  else
   aExec:=True;
 end;

function aUnpackSingle(Archiver, Archive, Target, Filename: String): boolean;
 var
  S, D: String;
 begin
  Archive:=FExpand(Archive);
  Target:=FExpand(Target);
  S:=aGetCommandLine(Archiver, snaUnpackSingle);
  S:=Replace(S, _cArchive, Archive);
  S:=Replace(S, _cFilename, Filename);
  S:=Replace(S, _cJustFilename, JustFilename(FExpand(FileName)));
  S:=Replace(S, _cTargetSlash, AddBackSlash(Target));
  S:=Replace(S, _cTarget, RemoveBackSlash(Target));
  D:=Trim(ExtractWord(1,S,[',']));
  if D<>'' then D:=StUpcase(RemoveBackSlash(FExpand(D)));
  S:=GetAllAfterChar(S,1,',');
  D:=aPushDir(D);
  aUnpackSingle:=aExec(S);
  aPopDir(D);
 end;

function aUnpackAll(Archiver, Archive, Target: String): boolean;
 var
  S, D: String;
 begin
  Archive:=FExpand(Archive);
  Target:=FExpand(Target);
  S:=aGetCommandLine(Archiver, snaUnpackAll);
  S:=Replace(S, _cArchive, Archive);
  S:=Replace(S, _cTargetSlash, AddBackSlash(Target));
  S:=Replace(S, _cTarget, RemoveBackSlash(Target));
  D:=Trim(ExtractWord(1,S,[',']));
  if D<>'' then D:=StUpcase(RemoveBackSlash(FExpand(D)));
  S:=GetAllAfterChar(S,1,',');
  D:=aPushDir(D);
  aUnpackAll:=aExec(S);
  aPopDir(D);
 end;

function aPackSingle(Archiver, Archive, Filename: String): boolean;
 var
  S, D: String;
 begin
  Archive:=FExpand(Archive);
  FileName:=FExpand(FileName);
  S:=aGetCommandLine(Archiver, snaPackSingle);
  S:=Replace(S, _cArchive, Archive);
  S:=Replace(S, _cFilename, FExpand(FileName));
  S:=Replace(S, _cJustFilename, JustFilename(FExpand(FileName)));
  S:=Replace(S, _cSourceSlash, AddBackSlash(JustPathName(FExpand(FileName))));
  S:=Replace(S, _cSource, RemoveBackSlash(JustPathName(FExpand(FileName))));
  D:=Trim(ExtractWord(1,S,[',']));
  if D<>'' then D:=StUpcase(RemoveBackSlash(FExpand(D)));
  S:=GetAllAfterChar(S,1,',');
  D:=aPushDir(D);
  aPackSingle:=aExec(S);
  aPopDir(D);
 end;

function aPackAll(Archiver, Archive, Source: String): boolean;
 var
  S, D: String;
 begin
  Archive:=FExpand(Archive);
  Source:=FExpand(Source);
  S:=aGetCommandLine(Archiver, snaPackAll);
  S:=Replace(S, _cArchive, Archive);
  S:=Replace(S, _cSourceSlash, AddBackSlash(Source));
  S:=Replace(S, _cSource, RemoveBackSlash(Source));
{  S:=mProcessMacros(S);}
  D:=Trim(ExtractWord(1,S,[',']));
  if D<>'' then D:=StUpcase(RemoveBackSlash(FExpand(D)));
  S:=GetAllAfterChar(S,1,',');
  D:=aPushDir(D);
  aPackAll:=aExec(S);
  aPopDir(D);
 end;
