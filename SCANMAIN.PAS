unit ScanMain;

{$IFDEF VIRTUALPASCAL}
 {$DEFINE USEUNITS}
{$ENDIF}
{$IFDEF SOLID}
 {$DEFINE USEUNITS}
{$ENDIF}

interface

uses
{$IFDEF USEUNITS}
     Misc, Language, Video, Semaphor, Config, Plugins, Division,
{$ELSE}
     Decl,
{$ENDIF}
     Consts_, Dos, Wizard, Types,
     ScanSys;

procedure ____DoCheckPlugins;
procedure ____DoScanPackets;
procedure ____DoStatistics;

implementation

{ ____CreateDirectories's code here }

procedure ____CreateDirectories(const Directories: PStrings);
 var
  K: Longint;
 begin
  for K:=1 to cmCount(Directories) do
   mCreate(GetPString(cmAt(Directories, K)));
 end;

{ ____SearchPacketsMask's code here }

procedure ____SearchPacketsMask(const Directory, Mask: PString; const Packets: PStrings);
 var
  SR: SearchRec;
  Dir: String;
 begin
  if Mask = Nil then Exit;
  Dir:=AddBackSlash(Directory^);
  FindFirst(Dir + Mask^, AnyFile, SR);
  while DosError = 0 do
   begin
    if (SR.Attr and (Dos.Directory + Dos.VolumeID) = 0) and (SR.Name[1] <> '.') then
     begin
      cmInsert(Packets, cmNewStr(Dir + SR.Name));
      Inc(ScanTotalSize, SR.Size);
     end;
    FindNext(SR);
   end;
  FindClose(SR);
 end;

{ ____SearchPacketsInDirectory's code here }

procedure ____SearchPacketsInDirectory(const Directory: PString; const Masks, Packets: PStrings);
 var
  K: Longint;
 begin
  if Directory = Nil then Exit;
  for K:=1 to cmCount(Masks) do
   ____SearchPacketsMask(Directory, cmAt(Masks, K), Packets)
 end;

{ ____SearchPackets's code here }

procedure ____SearchPackets(const Directories, Masks, Packets: PStrings);
 var
  K: Longint;
 begin
  for K:=1 to cmCount(Directories) do
   ____SearchPacketsInDirectory(cmAt(Directories, K), Masks, Packets);
 end;

{ ____SortHandler's code here }

function QueryFileDate(const FileName: String): Longint;
 var
  Structure: Pointer;
  Date: Longint;
 begin
  Structure:=diCreate(diTempDivisionIdentifier);
  Date:=diGetNum(Structure, FileName);
  if Date = 0 then
   begin
    Date:=GetFileDate(FileName);
    diSetNum(Structure, FileName, Date);
   end;
  QueryFileDate:=Date;
 end;

function ____SortHandler(C: PCollection; Key1, Key2: Longint): Longint; Far;
 var
  DT1, DT2: Longint;
 begin
  DT1:=QueryFileDate(GetPString(cmAt(C, Key1)));
  DT2:=QueryFileDate(GetPString(cmAt(C, Key2)));
  if DT1 < DT2 then ____SortHandler:=-1 else
  if DT1 > DT2 then ____SortHandler:=1 else
   ____SortHandler:=0;
 end;

{ ____DoCheckPlugins's code here }

procedure ____DoCheckPlugins;
 var
  K: Longint;
  C: PCollection;
  P, Service: Pointer;
  Name, FName, SearchName: String;
 begin
  C:=pGet;
  for K:=1 to cmCount(C) do
   begin
    P:=cmAt(C, K);
    if srvExecuteDirect(P, snsAreYouScanner, nil) = snrIamScanner then
     begin
      PluginsQueue^.Insert(New(PStatPlugin, Init(P)));
      pQueryPluginInfo(P, FName, Name, SearchName, Service);
      lngBegin;
       lngPush(Name);
       lngPush(FName);
       lngPrint('Main', 'scan.plugin.queued');
      lngEnd;
     end;
   end;

  if PluginsQueue^.Count = 0 then
   lngPrint('Main', 'scan.no.plugins.queued')
  else
   begin
    lngBegin;
     lngPush(Long2Str(PluginsQueue^.Count));
     lngPrint('Main', 'scan.plugins.queued');
    lngEnd;
   end;
 end;

{ ____DoScanPackets's code here }

procedure ____DoScanPackets;
 var
  Packets, Masks, Directories: PStrings;
  FileName: String;
  K: Longint;
 begin
  if sExitNow then Exit;
  srvBroadcast(snsScanStart, nil);

  cmCreateStrings(Packets);
  cmCreateStrings(Masks);
  cmCreateStrings(Directories);

  cProcessList('Packets.Directory', Directories);
  cProcessList('Packets.Mask', Masks);

  repeat
   if cmCount(Directories) = 0 then
    begin
     lngPrint('Main', 'Scanning.Pkt.None');
     Break;
    end;
   if cmCount(Masks) = 0 then
    begin
     lngPrint('Main', 'Scanning.Pkt.No.Mask');
     Break;
    end;

   lngBegin;
    lngPush(Long2StrFmt(cmCount(Directories)));
    lngPrint('Main', 'Scanning.Pkt.Start');
   lngEnd;

   lngPrint('Main', 'Scanning.Pkt.Reading');

   ____CreateDirectories(Directories);
   ____SearchPackets(Directories, Masks, Packets);

   lngBegin;
    lngPush(Long2StrFmt(cmCount(Packets)));
    lngPush(Long2StrFmt(ScanTotalSize));
    lngPush(Long2StrFmt(ScanTotalSize div 1024));
    lngPrint('Main', 'Scanning.Pkt.Readed');
   lngEnd;

   lngPrint('Main', 'Scanning.Sorting');
   cmSort(Packets, ____SortHandler);
   diDestroy(diTempDivisionIdentifier);
   vPrint(' '#8);

   for K:=1 to cmCount(Packets) do
    begin
     if sExitNow then Break;
     GetPStringEx(cmAt(Packets, K), FileName);
     __ScanPacket(FileName);
    end;
  until True;

  cmDisposeObject(Directories);
  cmDisposeObject(Masks);
  cmDisposeObject(Packets);

  srvBroadcast(snsScanEnd, nil);
 end;

{ ____ShowPluginStatistics }

procedure ____ShowPluginStatistics(const Plugin: PStatPlugin; const Name: String);
 var
  S: String;
 begin
  lngBegin;

   if Plugin^.Plugin = Nil then
    lngPush('internal')
   else
    lngPush(HexL(Longint(Plugin^.Plugin)));

   Str((Plugin^.Time / 1000):1:2, S);

   lngPush(LeftPad(S, 6));
   lngPush(LeftPad(Long2StrFmt(Plugin^.Time), 6));
   lngPush(LeftPad(Long2StrFmt(Plugin^.Calls), 6));
   lngPush(Name);
   lngPrint('Main', 'scan.stat');
  lngEnd;
 end;

{ ____DoStatistics's code here }

procedure ____DoStatistics;
 var
  K: Longint;
  Name, FName, SearchName: String;
  Service: Pointer;
  Total: TStatPlugin;
  Current: PStatPlugin;
 begin
  if not Stat then Exit;

  lngPrint('Main', 'scan.emptyline');

  ____ShowPluginStatistics(@StatExternal, 'SCAN: external');
  ____ShowPluginStatistics(@StatInternal, 'SCAN: internal');
  ____ShowPluginStatistics(@StatLoadMessage, 'SCAN: lm');

  if ScanPreload then
   ____ShowPluginStatistics(@StatPreload, 'SCAN: preload');

  if ScanPresave then
   ____ShowPluginStatistics(@StatPresave, 'SCAN: presave');

  Total.Init(Nil);

  for K:=1 to PluginsQueue^.Count do
   begin
    Current:=PluginsQueue^.At(K);

    pQueryPluginInfo(Current^.Plugin, FName, Name, SearchName, Service);

    ____ShowPluginStatistics(Current, Name);

    Inc(Total.Time, Current^.Time);
    Inc(Total.Calls, Current^.Calls);
   end;

  if PluginsQueue^.Count <> 0 then
   ____ShowPluginStatistics(@Total, 'Total [plugins]');

  Total.Done;
 end;

end.