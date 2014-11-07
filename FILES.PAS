{$IFDEF SOLID}
unit Files;

interface

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint;

implementation
{$ELSE}
library Files;
{$ENDIF}

{$IFDEF VIRTUALPASCAL}
uses Types, Consts_, Log, Video, Wizard, Misc, Language, Config, Semaphor,
     Plugins;
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

const
 filesVersion = $00010300;
var
 Pool: TMemoryStream;
 FileName: String;
 TempSpool: TCollection;

{$i files.inc}

type 
 PFilesTempItem = ^TFilesTempItem; 
 TFilesTempItem = object(TObject)
  Filename: PString;
  Size: Longint;
  CRC: Longint;
  constructor Init;
  destructor Done; virtual;
 end;

constructor TFilesTempItem.Init;
 begin
  inherited Init;
  Filename:=nil;
 end;

destructor TFilesTempItem.Done;
 begin
  if Filename<>nil then cmDisposeStr(Filename);
  inherited Done;
 end;

function Startup: longint;
 var
  B: TBufStream;
 begin
  Startup:=srNo;

  FileName:=cGetParam('files.database');

  if Filename = '' then
   begin
    lngPrint('Main', 'files.wrong.database');
    sSetExitNow;
    Exit;
   end;

  Startup:=srYes;
  Filename:=FExpand(Filename);

  Pool.Init;
  B.Init(Filename, stOpenRead, 2048);
  TempSpool.Init;

  if B.Status<>stOk then
   begin
    B.Done;

    lngBegin;
     lngPush(Filename);
     lngPrint('Main', 'files.database.created');
    lngEnd;

    Exit;
   end;

  Pool.CopyFrom(B, B.GetSize);
  B.Done;
 end;

procedure Shutdown;
 var
  B: TBufStream;
 begin
  repeat
   mCreate(JustPathName(FileName));

   B.Init(Filename, stCreate, 2048);

   if B.Status <> stOk then
    begin
     lngBegin;
     lngPush(Filename);
     lngPush(HexL(B.Status));
     lngPrint('Main', 'files.cannot.save');
     lngEnd;
     break;
    end;

   Pool.Seek(0);

   B.CopyFrom(Pool, Pool.GetSize);

  until True;

  B.Done;
  Pool.Done;
  TempSpool.Done;

 end;

procedure InternalAdd(Filename: String; Size, CRC: Longint);
 begin
  Pool.Seek(Pool.GetSize);
  Pool.WriteStr(Filename);
  Pool.Write(Size, SizeOf(Size));
  Pool.Write(CRC, SizeOf(CRC));

  lngBegin;
   lngPush(Filename);
   lngPush(Long2StrFmt(Size));
   lngPush(HexL(CRC));

   lngPrint('Main', 'files.added');
  lngEnd;
 end;

procedure Add;
 begin
  InternalAdd(StUpcase(sGetSemaphore('Files.Filename')),
              sGetNumSemaphore('Files.Size'),
              sGetNumSemaphore('Files.CRC'));
 end;

function Check: longint;
 var
  PoolSize: Longint;
  AFilename, BFilename: String;
  ASize, BSize: Longint;
  Strategy, stCount, AstCount: Longint;
  ACRC, BCRC: Longint;
 begin
  Pool.Seek(0);
  PoolSize:=Pool.GetSize;

  AFilename:=sGetSemaphore('Files.Filename');
  StUpcaseEx(AFilename);
  ASize:=sGetNumSemaphore('Files.Size');
  ACRC:=sGetNumSemaphore('Files.CRC');
  Strategy:=sGetNumSemaphore('Files.Strategy');

  StCount:=0;
  if Strategy and fsgName <> 0 then inc(StCount);
  if Strategy and fsgCRC <> 0 then inc(StCount);
  if Strategy and fsgSize <> 0 then inc(StCount);

  Check:=srNo;

  if stCount = 0 then Exit;

  while Pool.GetPos <> PoolSize do
   begin
    BFilename:=Pool.ReadStr;
    StUpcaseEx(BFilename);

    Pool.Read(BSize, SizeOf(BSize));
    Pool.Read(BCRC, SizeOf(BCRC));

    AstCount:=0;
    if (Strategy and fsgName <> 0) and (AFilename = BFilename) then Inc(AstCount);
    if (Strategy and fsgCRC <> 0) and (ACRC = BCRC) then Inc(AstCount);
    if (Strategy and fsgSize <> 0) and (ASize = BSize) then Inc(AstCount);

    if Astcount >= stCount then
     begin
      Check:=srYes;
      Exit;
     end;
   end;
 end;

procedure AddSpool;
 var P:PFilesTempItem;
     FileName:String;
     Size, CRC, i:Longint;
     Add:boolean;
 begin
  FileName:=StUpcase(sGetSemaphore('Files.Filename'));
  Size:=sGetNumSemaphore('Files.Size');
  CRC:=sGetNumSemaphore('Files.CRC');

  Add:=true;
  for i:=1 to TempSpool.Count do
  begin
   P:=cmAt(@TempSpool, i);
   if (P^.Filename^=Filename) and (P^.Size = Size) and (P^.CRC = CRC) then 
   begin 
    Add:=false;
    break;
   end;
  end;

  if Add then
  begin
   P:=New(PFilesTempItem, Init);
   P^.FileName:=cmNewStr(Filename);
   P^.Size:=Size;
   P^.CRC:=CRC;
   cmInsert(@TempSpool, P);
  end;
 end;

procedure FlushSpool;
 var i:Longint;
     P:PFilesTempItem;
 begin
  for i:=1 to TempSpool.Count do
  begin
   P:=cmAt(@TempSpool, i);
   InternalAdd(P^.Filename^, P^.Size, P^.CRC);
  end;
  TempSpool.FreeAll;
 end;

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint; {$IFNDEF SOLID}export;{$ENDIF}
 begin
  Service:=srYes;
  case ServiceNumber of
   snStartup: Service:=Startup;
   snShutdown: Shutdown;
   snQueryName: sSetSemaphore('Kernel.Plugins.Info.Name','FILES');
   snQueryAuthor: sSetSemaphore('Kernel.Plugins.Info.Author','sergey korowkin');
   snQueryVersion: Service:=filesVersion;
   snQueryReqVer: Service:=kernelVersion;
   snfilCheck: Service:=Check;
   snfilAdd: Add;
   snfilAddSpool: AddSpool;
   snfilFlushSpool: FlushSpool;
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
