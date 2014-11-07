{$IFDEF SOLID}
unit Gate;

interface

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint;

implementation
{$ELSE}
library Gate;
{$ENDIF}

{$IfDef VIRTUALPASCAL}
uses Types, Consts_, Log, Video, Wizard, Misc, Language, Config, Resource,
     Plugins, Semaphor;
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

const
 gateVersion     = $00020000;

{$I Scan.Inc}

type
 PCharacter = ^TCharacter;
 TCharacter = record
  Source, Destination: Char;
 end;

 PCharset = ^TCharset;
 TCharset = record
  { reserved for future use:)
    maybe diffferent charsets for different groups? agrhh.. who knows.. }
  Size: Byte;
  Table: Array[0..255] of TCharacter;
 end;

const
 Charset: PCharset = Nil;

var
 TheMap: Array[0..255] of Char;

function __Init: Longint;
 var
  S: String;
  F: TBufStream;
  K: Byte;
 begin
  S:=cGetParam('Gate.Charset');
  if S = '' then
   begin
    __Init:=srYes;
    Exit;
   end;

  New(Charset);
  FillChar(Charset^, SizeOf(TCharset), 0);

  F.Init(S, stOpenRead, 1024);

  if F.GetSize > SizeOf(CharSet^.Table) then
   begin
    lngBegin;
     lngPush(S);
     lngPrint('Main', 'gate.table.wrong');
    lngEnd;
    __Init:=srNo;
    sSetExitNow;
    Exit;
   end;

  Charset^.Size:=F.GetSize div 2;
  F.Read(Charset^.Table, F.GetSize);

  F.Done;

  lngBegin;
   lngPush(S);
   lngPush(Long2Str(Charset^.Size));
   lngPrint('Main', 'gate.using.table');
  lngEnd;

  for K:=0 to 255 do
   Byte(TheMap[K]):=K;

  if cGetBoolParam('Gate.Reverse') then
   for K:=1 to Charset^.Size do
    TheMap[Byte(Charset^.Table[K].Destination)]:=Charset^.Table[K].Source
  else
   for K:=1 to Charset^.Size do
    TheMap[Byte(Charset^.Table[K].Source)]:=Charset^.Table[K].Destination;

  __Init:=srYes;
 end;

procedure __Done;
 begin
  if Charset <> Nil then
   Dispose(Charset);
 end;

procedure __Do(var S: String);
 var
  K: Byte;
 begin
  for K:=1 to Length(S) do
   S[K]:=TheMap[Byte(S[K])];
 end;

procedure __Message(const msg: PMessage);
 var
  K: Longint;
  S: String;
 begin
  if Charset = Nil then Exit; { WTF? }
  __Do(msg^.iFrom);
  __Do(msg^.iTo);
  __Do(msg^.iSubj);
  for K:=1 to cmCount(msg^.Data) do
   begin
    GetPStringEx(cmAt(msg^.Data, K), S);
    __Do(S);
    cmAtFree(msg^.Data, K);
    cmAtInsert(msg^.Data, cmNewStr(S), K);
   end;
 end;

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint; {$IFNDEF SOLID}export;{$ENDIF}
 begin
  Service:=srYes;
  case ServiceNumber of
   snStartup: Service:=__Init;
   snShutdown: __Done;
   snQueryName: sSetSemaphore('Kernel.Plugins.Info.Name','Gate To Hell');
   snQueryAuthor: sSetSemaphore('Kernel.Plugins.Info.Author','sergey korowkin');
   snQueryVersion: Service:=gateVersion;
   snQueryReqVer: Service:=kernelVersion;
   snsMessage: __Message(Buffer);
   snsAreYouScanner: Service:=snrIamScanner;
  else
   Service:=srNotSupported;
  end;
 end;

{$IFNDEF SOLID}
exports
 Service;

begin
{$ENDIF}
end.