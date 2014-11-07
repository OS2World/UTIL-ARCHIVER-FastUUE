{
 PluginSystem CORE
 (c) by sergey korowkin, 1999.
}

unit PlugCore;

interface

procedure pInit;
procedure pStart;
procedure pDone;

{$IFDEF SOLID}
{$IFDEF CUSTOMSOLID}
{$I CUSTOM3.INC}
{$ELSE}
const SolidDllcnt = 17;
const SolidDll:array[1..17] of PChar = (
'COMMON',
'UUE', 'SCAN', 'ANNOUNCE', 'ARCHIVER',
'FILES', 'FILESBBS', 'GATE', 'HATCHER', 'MSGOUT',
'H', 'LOGCUT', 'PATHBLD', 'SEENBY', 'TWIT',
'DOB', 'CRAX');
{$ENDIF}
{$ENDIF}

implementation
uses
{$IFDEF SOLID}
     Common,
{$IFDEF CUSTOMSOLID}
{$I CUSTOM1.INC}
{$ELSE}
     Uue,
     Scan,
     Announce,
     Archiver,
     Files,
     Filesbbs,
     Gate,
     Hatcher,
     Msgout,
     H,
     Logcut,
     Pathbld,
     Seenby,
     Twit,
     Dob,
     Crax,
{$ENDIF}
{$ENDIF}
     Plugins, Types, Language, Config, Wizard, Semaphor, Consts_, Video;

{$IFDEF SOLID}
{$IFDEF CUSTOMSOLID}
{$I CUSTOM2.INC}
{$ELSE}
function QueryPluginService(const FName: String): Pointer; Far;
 begin
  if FName = 'COMMON.DLL'   then QueryPluginService:=@Common.Service else
  if FName = 'SCAN.DLL'     then QueryPluginService:=@Scan.Service else
  if FName = 'ANNOUNCE.DLL' then QueryPluginService:=@Announce.Service else
  if FName = 'ARCHIVER.DLL' then QueryPluginService:=@Archiver.Service else
  if FName = 'FILES.DLL'    then QueryPluginService:=@Files.Service else
  if FName = 'FILESBBS.DLL' then QueryPluginService:=@FilesBBS.Service else
  if FName = 'GATE.DLL'     then QueryPluginService:=@Gate.Service else
  if FName = 'HATCHER.DLL'  then QueryPluginService:=@Hatcher.Service else
  if FName = 'MSGOUT.DLL'   then QueryPluginService:=@MsgOut.Service else
  if FName = 'H.DLL'        then QueryPluginService:=@H.Service else
  if FName = 'LOGCUT.DLL'   then QueryPluginService:=@LogCut.Service else
  if FName = 'PATHBLD.DLL'  then QueryPluginService:=@PathBld.Service else
  if FName = 'SEENBY.DLL'   then QueryPluginService:=@SeenBy.Service else
  if FName = 'TWIT.DLL'     then QueryPluginService:=@Twit.Service else
  if FName = 'DOB.DLL'      then QueryPluginService:=@Dob.Service else
  if FName = 'CRAX.DLL'     then QueryPluginService:=@Crax.Service else
  if FName = 'UUE.DLL'      then QueryPluginService:=@Uue.Service else
   QueryPluginService:=Nil;
 end;
{$ENDIF}
{$ENDIF}

procedure pConnectPlugin(FName: String);
 var
  Plugin: PPlugin;
  Data: String;
 begin
  TrimEx(FName);
  if FName = '' then Exit;
  sSetSemaphore('Kernel.Plugins.CommandLine', GetAllAfterSpace(FName, 1));
  FName:=ExtractWord(1, FName, [' ']);
  lngBegin;
  lngPush(JustFileName(FName));
  lngPush(FName);
  lngPrint('Main', 'Loading.Plugin');
  lngEnd;
  Plugin:=New(PPlugin, Init(FName));
  if Plugin^.Load then
   begin
    Plugin^.Service(snQueryAuthor, Nil);
    lngBegin;
    lngPush(sGetSemaphore('Kernel.Plugins.Info.Author'));
    lngPrint('Main', 'Plugin.Info.Author');
    lngEnd;
    lngBegin;
    lngPush(Version2Str(Plugin^.Service(snQueryVersion, Nil)));
    lngPrint('Main', 'Plugin.Info.Version');
    lngEnd;
    lngBegin;
    lngPush(Version2Str(Plugin^.Service(snQueryReqVer, nil)));
    lngPrint('Main', 'Plugin.Info.ReqVer');
    lngEnd;
    if Plugin^.Service(snQueryReqVer, Nil) > KernelVersion then
     begin
      lngPrint('Main', 'Plugin.Error.OldKernel');
      Dispose(Plugin, Done);
     end
    else
     if Plugin^.Service(snStartup, Nil) <> srYes then
      begin
       lngBegin;
       lngPush(JustFileName(FName));
       lngPrint('Main', 'Plugin.Cancelled');
       lngEnd;
       Dispose(Plugin, Done);
      end
     else
      begin
       Plugin^.Boot;
       lngBegin;
       lngPush(JustFileName(FName));
       lngPush(Plugin^.Name^);
       lngPush(HexL(Plugin^.Handle));
       lngPrint('Main', 'Plugin.Loaded');
       lngEnd;
       Pool^.Insert(Plugin);
      end;
   end
  else
   begin
    lngBegin;
    lngPush(FName);
    lngPush(HexL(Plugin^.ErrorCode));
    lngPrint('Main', sGetSemaphore('Plugin.Subsystem.ErrorString'));
    lngEnd;
    Dispose(Plugin, Done);
   end;
 end;

procedure pDropPlugin(const Plugin: PPlugin);
 begin
  Plugin^.Service(snShutdown, Nil);
  Plugin^.Unload;
  lngBegin;
  lngPush(Plugin^.Name^);
  lngPrint('Main', 'Plugin.Shutdowned');
  lngEnd;
 end;

procedure pInit;
 var
  List: PStrings;
  K: Longint;
 begin
  {$IFDEF SOLID}
  Plugins.QueryPluginService:=PlugCore.QueryPluginService;
  {$ENDIF}
  lngPrint('Main', 'Plugin.Startup');
  Pool:=New(PCollection, Init);
  List:=New(PStrings, Init);
  cProcessList('Plugins', List);
  for K:=1 to List^.Count do
   pConnectPlugin(GetPString(List^.At(K)));
  Dispose(List, Done);
 end;

procedure pStart;
 var
  K: Longint;
 begin
  K:=0;
  repeat
   Inc(K);
   if K > Pool^.Count then Break;
   PPlugin(Pool^.At(K))^.Service(snStart, Nil);
  until False;
 end;

procedure pDone;
 var
  K: Longint;
 begin
  for K:=1 to Pool^.Count do
   pDropPlugin(Pool^.At(K));
  Dispose(Pool, Done);
  lngPrint('Main', 'Plugin.Shutdown');
 end;

end.
