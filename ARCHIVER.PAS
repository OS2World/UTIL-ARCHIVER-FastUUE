{$IFDEF SOLID}
unit Archiver;

interface

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint;

implementation
{$ELSE}
library Archiver;
{$ENDIF}

{$IFDEF VIRTUALPASCAL}
uses Types, Consts_, Log, Video, Wizard, Misc, Language, Config, Resource,
     Plugins, Semaphor;
{$IFNDEF SOLID}
{$Dynamic MAIN.LIB}
{$ENDIF}
{$ENDIF}
{$IFDEF DPMI}
uses
{$IFDEF SOLID}
     Plugins, Semaphor, Language, Misc, Config, Video,
{$ELSE}
     Decl,
{$ENDIF}
     Wizard, Consts_, Dos, Macroz, Types;
{$ENDIF}

{$I ARCHIVER.INC}

const
 arcVersion     = $00010000;
 archivers      : PCollection = nil;
type
 PArchiver      = ^TArchiver;
 TArchiver      = object(TObject)
  Name: PString;
  Ext: PString;
  UnpackSingle: PString;
  UnpackAll: PString;
  PackSingle: PString;
  PackAll: PString;
  destructor Done; virtual;
 end;

destructor TArchiver.Done;
 begin
  DisposeStr(Name);
  DisposeStr(Ext);
  DisposeStr(UnpackSingle);
  DisposeStr(UnpackAll);
  DisposeStr(PackSingle);
  DisposeStr(PackAll);
  inherited Done;
 end;

procedure LoadArchiver(BlockName: String);
 var
  Block: PStrings;
  Archiver: PArchiver;
 begin
  Block:=bSearch(BlockName);
  if Block=nil then
   begin
    lngBegin;
    lngPush(BlockName);
    lngPrint('Main','archiver.wrong.block');
    lngEnd;
    sSetExitNow;
    Exit;
   end;
  Archiver:=New(PArchiver, Init);
  Archivers^.Insert(Archiver);
  with Archiver^ do
   begin
    Name:=NewStr(Trim(StUpcase(iGetParam(Block, 'Name'))));
    Ext:=NewStr(Trim(StUpcase(iGetParam(Block, 'Ext'))));
    UnpackSingle:=NewStr(iGetParam(Block, 'Unpack.Single.File'));
    UnpackAll:=NewStr(iGetParam(Block, 'Unpack.All.Files'));
    PackSingle:=NewStr(iGetParam(Block, 'Pack.Single.File'));
    PackAll:=NewStr(iGetParam(Block, 'Pack.All.Files'));
   end;
 end;

function _Init: Longint;
 var
  ss: pstrings;
  k: longint;
 begin
  archivers:=new(PCollection, Init);
  _Init:=srYes;
  cmCreateStrings(ss);
  cProcessList('Archivers', ss);
  for k:=1 to cmCount(ss) do
   begin
    LoadArchiver(GetPString(cmAt(ss, k)));
    if sExitNow then Break;
   end;
  cmDisposeObject(ss);
 end;

procedure _Done;
 begin
  dispose(archivers, done);
 end;

function SeekByExtension(Ext: String): PArchiver;
 var
  k: Longint;
  a: PArchiver;
 begin
  Ext:=Trim(StUpcase(Ext));
  SeekByExtension:=Nil;
  for k:=1 to archivers^.count do
   begin
    a:=archivers^.at(k);
    if stupcase(trim(getpstring(a^.ext)))=ext then
     begin
      SeekByExtension:=A;
      Break;
     end;
   end;
 end;

function SeekByName(Name: String): PArchiver;
 var
  k: Longint;
  a: PArchiver;
 begin
  sSetSemaphore('Archiver.Loaded','Yes');
  sSetSemaphore('Archiver.Info.Version',Version2Str(arcVersion));
  Name:=Trim(StUpcase(Name));
  SeekByName:=Nil;
  for k:=1 to archivers^.count do
   begin
    a:=archivers^.at(k);
    if stupcase(trim(getpstring(a^.name)))=name then
     begin
      SeekByName:=A;
      Break;
     end;
   end;
 end;

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint; {$IFNDEF SOLID}export;{$ENDIF}
 var
  A: PArchiver;
  S: String;
 begin
  Service:=srYes;
  case ServiceNumber of
   snStartup: Service:=_Init;
   snShutdown: _Done;
   snQueryVersion: Service:=arcVersion;
   snQueryReqVer: Service:=kernelVersion;
   snQueryName: sSetSemaphore('Kernel.Plugins.Info.Name', 'ARCHIVER');
   snQueryAuthor: sSetSemaphore('Kernel.Plugins.Info.Author', 'sergey korowkin');
   snaCheck: Service:=sraYeahhow;
   snaSearchArchive:
    begin
     A:=SeekByExtension(sGetSemaphore('Archiver.Externals.Extension'));
     if A=Nil then S:='' else S:=GetPString(A^.Name);
     sSetSemaphore('Archiver.Externals.Result', S);
    end;
   snaGetExtension:
    begin
     A:=SeekByName(sGetSemaphore('Archiver.Externals.Archiver'));
     if A=Nil then S:='' else S:=GetPString(A^.Ext);
     sSetSemaphore('Archiver.Externals.Extension', S);
    end;
   snaUnpackSingle:
    begin
     A:=SeekByName(sGetSemaphore('Archiver.Externals.Archiver'));
     if A=Nil then S:='' else S:=GetPString(A^.UnpackSingle);
     sSetSemaphore('Archiver.Externals.CommandLine', S);
    end;
   snaUnpackAll:
    begin
     A:=SeekByName(sGetSemaphore('Archiver.Externals.Archiver'));
     if A=Nil then S:='' else S:=GetPString(A^.UnpackAll);
     sSetSemaphore('Archiver.Externals.CommandLine', S);
    end;
   snaPackSingle:
    begin
     A:=SeekByName(sGetSemaphore('Archiver.Externals.Archiver'));
     if A=Nil then S:='' else S:=GetPString(A^.PackSingle);
     sSetSemaphore('Archiver.Externals.CommandLine', S);
    end;
   snaPackAll:
    begin
     A:=SeekByName(sGetSemaphore('Archiver.Externals.Archiver'));
     if A=Nil then S:='' else S:=GetPString(A^.PackAll);
     sSetSemaphore('Archiver.Externals.CommandLine', S);
    end;
   snaCheckArchiver:
    begin
     A:=SeekByName(sGetSemaphore('Archiver.Externals.Archiver'));
     if A=Nil then S:='' else S:='Yes';
     sSetSemaphore('Archiver.Externals.Check', S);
    end;
  else
   Service:=srNotSupported;
  end;
 end;

{$IFNDEF SOLID}
exports
 Service name 'SERVICE';

begin
{$ENDIF}
end.
