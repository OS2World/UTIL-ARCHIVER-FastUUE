library TEST;

{$IfNDef VIRTUALPASCAL}
uses Decl, Types, Consts_, Wizard, WinTypes, WinApi;
{$EndIF}
{$IfDef VIRTUALPASCAL}
uses Types, Consts_, Log, Video, Wizard, Misc, Language, Config, Resource,
     Plugins, Semaphor;
{$Dynamic MAIN.LIB}
{$EndIF}

const
 testVersion     = $FF030201;

procedure Start;
 begin
  mExec('dir');
 end;

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint; {$IFNDEF SOLID}export;{$ENDIF}
 begin
  Service:=srYes;
  case ServiceNumber of
   snStartup: Service:=srYes;
   snQueryName: sSetSemaphore('Kernel.Plugins.Info.Name','TEST');
   snQueryAuthor: sSetSemaphore('Kernel.Plugins.Info.Author','sergey korowkin');
   snQueryVersion: Service:=testVersion;
   snQueryReqVer: Service:=kernelVersion;
   snCommandLine:;
   snStart: Start;
  else
   Service:=srNotSupported;
  end;
 end;

exports
 Service;

begin
end.
