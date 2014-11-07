unit ScanCore;

{$IFDEF VIRTUALPASCAL}
 {$DEFINE USEUNITS}
{$ENDIF}
{$IFDEF SOLID}
 {$DEFINE USEUNITS}
{$ENDIF}

interface
uses
{$IFDEF USEUNITS}
     Misc, Language, Semaphor, Plugins, Config, Video,
{$ELSE}
     Decl,
{$ENDIF}
     Dos, Wizard, Types,
     ScanMain, ScanSys;

{ Some useful constants and variables ;) }

const
 ScanVersion                 = $00020003;
 ScanEnabled                 : Boolean = False;

{ Scan.Inc's declarations here }

{$DEFINE SCAN_DECL}
{$I SCAN.INC}

{ General actions }

procedure __Startup;
procedure __AfterStartup;
procedure __Start;
procedure __Shutdown;

{ Miscellaneous actions }

procedure ___PutMessage(const Data: PStrings);
procedure ___DupeMessage(const Message: PMessage);
procedure ___KillMessage(const Message: PMessage);
procedure ___CopyMessage;

implementation

{ Scan.Inc's code here }

{$DEFINE SCAN_CODE}
{$I SCAN.INC}

{ __CheckEmpty code here }

function __CheckEmpty: Boolean;
 var
  Masks, Dirs: PStrings;
 function CheckDir(const Dir: PString): Boolean;
  function CheckMask(const Mask: PString): Boolean;
   var
    SR: SearchRec;
   begin
    CheckMask:=False;
    if Mask = Nil then Exit;
    FindFirst(AddBackSlash(Dir^) + Mask^, AnyFile, SR);
    while DosError = 0 do
     begin
      if (SR.Attr and (Directory + VolumeID) = 0) and (SR.Name[1] <> '.') then
       begin
        CheckMask:=True;
        Break;
       end;
      FindNext(SR);
     end;
    FindClose(SR);
   end;
  var
   K: Longint;
  begin
   CheckDir:=False;
   if Dir = Nil then Exit;
   for K:=1 to cmCount(Masks) do
    if CheckMask(cmAt(Masks, K)) then
     begin
      CheckDir:=True;
      Break;
     end;
  end;
 var
  K: Longint;
  Found: Boolean;
 begin
  Found:=False;
  cmCreateStrings(Masks);
  cmCreateStrings(Dirs);
  cProcessList('Packets.Directory', Dirs);
  cProcessList('Packets.Mask', Masks);
  repeat
   if cmCount(Dirs) = 0 then Break;
   if cmCount(Masks) = 0 then Break;
   for K:=1 to cmCount(Dirs) do
    if CheckDir(cmAt(Dirs, K)) then
     begin
      Found:=True;
      Break;
     end;
  until True;
  cmDisposeObject(Dirs);
  cmDisposeObject(Masks);
  __CheckEmpty:=not Found;
 end;

{ __Startup's code here }

procedure __Startup;
 begin
  sSetSemaphore('Scanner.Info.Version', Version2Str(ScanVersion));
  sSetSemaphore('Scanner.Loaded', 'Yes');

  ScanEnabled:=cGetBoolParam('Scan.Enabled');
  ScanUseReply:=cGetBoolParam('Scan.Message.UseReply');
  ScanRepack:=cGetBoolParam('Scan.Message.Repack');
  ScanShowProgress:=cGetBoolParam('Scan.Message.ShowProgress');
  ScanPreload:=cGetBoolParam('Scan.Preload');
  ScanPresave:=cGetBoolParam('Scan.Presave');

  GetMem(MBuffer, MBufferSize);
  MBufferOffset:=Ofs(MBuffer^);

  TheQueue:=New(PCollection, Init);
  PluginsQueue:=New(PCollection, Init);

  if cGetBoolParam('Scan.Exit.If.Empty') and __CheckEmpty then
   begin
    lngPrint('Main', 'Scan.Empty');
    sSetExitNow;
   end;

  Stat:=cGetBoolParam('Scan.Stat');

  if Stat then
   Broadcaster:=BroadcastEx
  else
   Broadcaster:=Broadcast;

  StatInternal.Init(Nil);
  StatExternal.Init(Nil);
  StatLoadMessage.Init(Nil);
  StatPreload.Init(Nil);
  StatPresave.Init(Nil);

  cmCreateStrings(FromExclude);
  cmCreateStrings(FromRemain);
  cmCreateStrings(ToExclude);
  cmCreateStrings(ToRemain);

  cProcessList('Scan.From.Exclude', FromExclude);
  cProcessList('Scan.From.Remain', FromRemain);
  cProcessList('Scan.To.Exclude', ToExclude);
  cProcessList('Scan.To.Remain', ToRemain);
 end;

{ __AfterStartup's code here }

procedure __AfterStartup;
 begin
  mCheckPlugin('SCANNER', 'USER');
 end;

{ __Start's code here}

procedure __Start;
 var
  Time: Longint;
  S: String;
 begin
  if not ScanEnabled then Exit;
  lngPrint('Main', 'Scanning.Started');
  Time:=Clock;
  mCheckBreak;

  ____DoCheckPlugins;
  ____DoScanPackets;

  lngBegin;
   Time:=Clock - Time;

   Str((Time / 1024):1:2, S);
   lngPush(S);
   if Time = 0 then Inc(Time);

   Str((ScanProcessedSize / 1024):1:3, S);
   lngPush(S);

   Str((ScanProcessedSize / Time):1:2, S);
   lngPush(S);

   lngPrint('Main', 'Scanning.Stopped');
  lngEnd;

  ____DoStatistics;
 end;

{ __Shutdown's code here }

procedure __Shutdown;
 begin
  if TheQueue^.Count <> 0 then
   begin
    lngBegin;
    lngPush(Long2Str(TheQueue^.Count));
    lngPrint('Main', 'Scan.UnExported');
    lngEnd;
   end;

  cmDisposeObject(FromExclude);
  cmDisposeObject(FromRemain);
  cmDisposeObject(ToExclude);
  cmDisposeObject(ToRemain);

  StatPresave.Done;
  StatPreload.Done;
  StatLoadMessage.Done;
  StatInternal.Done;
  StatExternal.Done;

  Dispose(PluginsQueue, Done);
  Dispose(TheQueue, Done);

  FreeMem(MBuffer, MBufferSize);
 end;

{ ___PutMessage's code here }

procedure ___PutMessage(const Data: PStrings);
 var
  Message: PMessage;
 begin
  Message:=New(PMessage, Init);
  Message^.iArea:=sGetSemaphore('Scanner.Add.iArea');
  Message^.iFrom:=sGetSemaphore('Scanner.Add.iFrom');
  Message^.iTo:=sGetSemaphore('Scanner.Add.iTo');
  Message^.iSubj:=sGetSemaphore('Scanner.Add.iSubj');
  Message^.iDate:=GetPktDateTime;
  Str2Address(sGetSemaphore('Scanner.Add.iFromAddress'), Message^.iFromAddress);
  Str2Address(sGetSemaphore('Scanner.Add.iToAddress'), Message^.iToAddress);
  Message^.iSize:=0;
  Message^.Kill:=False;
  Message^.Group:=gSearchByArea(Message^.iArea);;
  cmDisposeObject(Message^.Data);
  Message^.Data:=Data;
  TheQueue^.Insert(Message);
 end;

{ ___DupeMessage's code here }

procedure ___DupeMessage;
 var
  Dupe: PMessage;
  K: Longint;
 begin
  Dupe:=New(PMessage, Init);
  for K:=1 to cmCount(Message^.Data) do
   cmInsert(Dupe^.Data, cmNewStr(GetPString(cmAt(Message^.Data, K))));
  Dupe^.iArea:=Message^.iArea;
  Dupe^.iFrom:=Message^.iFrom;
  Dupe^.iTo:=Message^.iTo;
  Dupe^.iSubj:=Message^.iSubj;
  Dupe^.iDate:=Message^.iDate;
  Dupe^.iFromAddress:=Message^.iFromAddress;
  Dupe^.iToAddress:=Message^.iToAddress;
  Dupe^.iSize:=Message^.iSize;
  Dupe^.Kill:=Message^.Kill;
  Dupe^.Group:=Message^.Group;
  sSetSemaphore('Scanner.Dupe', HexPtr(Dupe));
 end;

{ ___KillMessage's code here }

procedure ___KillMessage(const Message: PMessage);
 begin
  Dispose(Message, Done);
 end;

{ ___CopyMessage's code here }

procedure ___CopyMessage;
 var
  Source, Destination: PMessage;
  K: Longint;
 begin
  Source:=sGetPtrSemaphore('Scanner.Copy.Source');
  Destination:=sGetPtrSemaphore('Scanner.Copy.Destination');
  cmFreeAll(Destination^.Data);

  for K:=1 to cmCount(Source^.Data) do
   cmInsert(Destination^.Data, cmNewStr(GetPString(cmAt(Source^.Data, K))));

  Destination^.iArea:=Source^.iArea;
  Destination^.iFrom:=Source^.iFrom;
  Destination^.iTo:=Source^.iTo;
  Destination^.iSubj:=Source^.iSubj;
  Destination^.iDate:=Source^.iDate;
  Destination^.iFromAddress:=Source^.iFromAddress;
  Destination^.iToAddress:=Source^.iToAddress;
  Destination^.iSize:=Source^.iSize;
  Destination^.Kill:=Source^.Kill;
  Destination^.Group:=Source^.Group;
 end;

end.
