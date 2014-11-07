{$IFDEF SOLID}
unit uue;

interface

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint;

implementation
{$ELSE}
library uue;
{$ENDIF}

{$IFDEF VIRTUALPASCAL}

 uses
      Dos, Wizard,
      Types,
      Consts_,
      Log, Video, Misc, Language, Semaphor, Plugins, Config, uueCore,
      uueOver, uueScan;

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
      Types, Consts_, uueCore, uueOver, uueScan;

{$ENDIF}

(*** A bit of the shit ***)

{$I SCAN.INC}

(*** Services handler ***)

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint; {$IFNDEF SOLID}export;{$ENDIF}
 begin
  Service:=srYes;
  case ServiceNumber of
   (*** Startup actions ***)
   snQueryName: sSetSemaphore('Kernel.Plugins.Info.Name', 'UUE');
   snQueryAuthor: sSetSemaphore('Kernel.Plugins.Info.Author', 'sergey korowkin');
   snQueryVersion: Service:=uueVersion;
   snQueryReqVer: Service:=KernelVersion;
   snCommandLine: __CommandLine(sGetSemaphore('Kernel.CommandLine'));

   (*** Work actions ***)
   snStartup: Service:=__Startup;
   snAfterStartup: __AfterStartup;
   snStart: __Start;
   snShutdown: __Shutdown;

   (*** Runtime actions ***)
   snsAreYouScanner: Service:=snrIamScanner;
   snsMessage:
    if uueScanning then
     begin
      Message:=Buffer;

      __ProcessMessage;
     end;
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
