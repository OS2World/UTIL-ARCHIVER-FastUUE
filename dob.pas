{$B-}
{$IFDEF SOLID}
unit DOB;

interface

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint;

implementation
{$ELSE}
library Dob;
{$ENDIF}

{$IfDef VIRTUALPASCAL}
uses Dos, Types, Consts_, Log, Video, Misc, Language, Config, Resource,
     Plugins, Semaphor, Wizard;
{$IFNDEF SOLID}
{$Dynamic MAIN.LIB}
{$ENDIF}
{$EndIF}
{$IFDEF DPMI}
uses
{$IFDEF SOLID}
     Plugins, Semaphor, Language, Misc, Config, Video,
{$ELSE}
     Decl,
{$ENDIF}
     Wizard, Consts_, Dos, Macroz, Types;
{$ENDIF}

{$i common.inc}
{$i announce.inc}

const
 dobVersion       = $00010000;

type
 PDob = ^TDob;
 TDob = object(TObject)
 public
  Day, Month: Longint;
  Block: PStrings;
 end;

var
 Dobs: TCollection;

function Startup: Longint;
 var
  List: PStrings;
  K, Day, Month: Longint;
  S: String;
  Dob: PDob;
 begin
  Startup:=srYes;
  Dobs.Init;
  cmCreateStrings(List);
  cProcessList('dob.List', List);
  for K:=1 to cmCount(List) do
   begin
    GetPStringEx(cmAt(List, K), S);
    Str2Longint(ExtractWord(1, S, [',']), Day);
    Str2Longint(ExtractWord(2, S, [',']), Month);
    if (Day < 0) or (Day > 31) or (Month < 0) or (Month > 12) then
     begin
      sSetExitNow;
      lngBegin;
      lngPush(S);
      lngPrint('Main', 'dob.wrong.declaration');
      lngEnd;
      Break;
     end;
    S:=GetAllAfterChar(S, 2, ',');
    if bSearch(S) = Nil then
     begin
      sSetExitNow;
      lngBegin;
      lngPush(S);
      lngPrint('Main', 'dob.wrong.block');
      lngEnd;
      Break;
     end;
    Dob:=New(PDob, Init);
    Dobs.Insert(Dob);
    Dob^.Day:=Day;
    Dob^.Month:=Month;
    Dob^.Block:=bSearch(S);
   end;
  cmDisposeObject(List);
 end;

procedure Shutdown;
 begin
  Dobs.Done;
 end;

const
 Count: Longint = 0;

procedure Post(Dob: PDob);
 var
  Block: PStrings;
  Lines: PStrings;
  _FileName, S: String;
  F: Text;
  K: Longint;
  M: Pointer;
 begin
  cmCreateStrings(Lines);
  Block:=Dob^.Block;
  _FileName:=iGetParam(Block, 'FileName');

  repeat
   {$I-}
   Assign(F, _FileName);
   Reset(F);
   if InOutRes <> 0 then
    begin
     lngBegin;
     lngPush(_FileName);
     lngPush(Long2Str(IOResult));
     lngPrint('Main', 'error.cant.open');
     lngEnd;
     Break;
    end;

   M:=umCreateMacros;
   while not Eof(F) do
    begin
     ReadLn(F, S);
     S:=umProcessMacro(M, S);
     if not umEmptyLine(M) then
      cmInsert(Lines, cmNewStr(S));
    end;
   umDestroyMacros(M);

   Close(F);

   if IOResult <> 0 then;

   lngBegin;
   lngPush(iGetParam(Block, 'Title'));
   lngPrint('Main', 'dob');
   lngEnd;

   sSetSemaphore('Announcer.Mode', '3');
   sSetSemaphore('Announcer.Lines', HexPtr(Lines));
   sSetSemaphore('Announcer.Group', HexPtr(Block));
   sSetSemaphore('Announcer.Prefix', '');

   K:=annProcessAnnounce;
   if K <> srYes then
    begin
     lngBegin;
     lngPush(HexL(K));
     lngPrint('Main', 'dob.error');
     lngEnd;
    end
   else
    lngPrint('Main', 'dob.ok');

   Inc(Count);
  until True;

  cmDisposeObject(Lines);
 end;

procedure Go;
 var
  K: Longint;
  Dob: PDob;
  Day, Month, Year: Word;
 begin
  IWannaDate(Day, Month, Year);
  for K:=1 to Dobs.Count do
   begin
    Dob:=Dobs.At(K);
    if ((Dob^.Day = Day) and (Dob^.Month = Month)) or
       ((Dob^.Day = 0) and (Dob^.Month = 0)) then
     Post(Dob);
   end;
 end;

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint; {$IFNDEF SOLID}export;{$ENDIF}
 var
  S: String;
 begin
  Service:=srYes;
  case ServiceNumber of
   snStartup: Service:=Startup;
   snStart: Go;
   snShutdown: Shutdown;
   snAfterStartup: mCheckPlugin('D.O.B.', 'ANNOUNCER');
   snQueryName: sSetSemaphore('Kernel.Plugins.Info.Name','D.O.B.');
   snQueryAuthor: sSetSemaphore('Kernel.Plugins.Info.Author','sergey korowkin');
   snQueryVersion: Service:=dobVersion;
   snQueryReqVer: Service:=kernelVersion;
  else
   Service:=srNotSupported;
  end;
 end;

{$IFNDEF SOLID}
exports
 SERVICE;

begin
{$ENDIF}
end.
