{$IFDEF SOLID}
unit Scan;

interface

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint;

implementation
{$ELSE}
library Scan;
{$ENDIF}

{$IFDEF VIRTUALPASCAL}
 uses
      Dos, Wizard,
      Types,
      Consts_,
      Log, Video, Misc, Language, Semaphor, Plugins, Config, ScanCore;
 {$IFNDEF SOLID}
  {$DYNAMIC MAIN.LIB}
 {$ENDIF}
{$ELSE}
 uses
      Macroz, Dos, Wizard,
 {$IFDEF SOLID}
      Log, Video, Misc, Language, Semaphor, Plugins, Config,
 {$ELSE}
      Decl,
 {$ENDIF}
      Types, Consts_, ScanCore;
{$ENDIF}

(*** Services handler ***)

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint; {$IFNDEF SOLID}export;{$ENDIF}
 begin
  Service:=srYes;
  case ServiceNumber of
   (*** Startup actions ***)
   snQueryName: sSetSemaphore('Kernel.Plugins.Info.Name', 'SCANNER');
   snQueryAuthor: sSetSemaphore('Kernel.Plugins.Info.Author', 'sergey korowkin');
   snQueryVersion: Service:=ScanVersion;
   snQueryReqVer: Service:=KernelVersion;
   snCommandLine:
    if sGetSemaphore('Kernel.CommandLine') = 'DISABLESCAN' then ScanEnabled:=False else
    if sGetSemaphore('Kernel.CommandLine') = 'ENABLESCAN' then ScanEnabled:=True;

   (*** Work actions ***)
   snAfterStartup: __AfterStartup;
   snStartup: __Startup;
   snShutdown: __Shutdown;
   snStart: __Start;

   (*** Message actions ***)
   snsPutMessage: ___PutMessage(Buffer);
   snsDupeMessage: ___DupeMessage(Buffer);
   snsKillMessage: ___KillMessage(Buffer);
   snsCopyMessage: ___CopyMessage;
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
