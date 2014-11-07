{$IFDEF SOLID}
unit H;

interface

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint;

implementation
{$ELSE}
library H;
{$ENDIF}

{$IfDef VIRTUALPASCAL}
uses Types, Consts_, Log, Video, Misc, Language, Config, Resource,
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

const
 hpVersion      = $00010000;

{$i scan.inc}

procedure Translate(S: PString);
 var
  K: Byte;
 begin
  if S=Nil then Exit;
  for K:=1 to Byte(S^[0]) do
   if S^[K]=#141 then S^[K]:=#72;
 end;

procedure hpMessage(Msg: PMessage);
 var
  K: Longint;
 begin
  Translate(@Msg^.iFrom);
  Translate(@Msg^.iTo);
  Translate(@Msg^.iSubj);
  for K:=1 to cmCount(Msg^.Data) do
   Translate(cmAt(Msg^.Data, K));
 end;

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint; {$IFNDEF SOLID}export;{$ENDIF}
 begin
  Service:=srYes;
  case ServiceNumber of
   snStartup:;
   snAfterStartup: mCheckPlugin('H', 'SCANNER');
   snQueryName: sSetSemaphore('Kernel.Plugins.Info.Name','H');
   snQueryAuthor: sSetSemaphore('Kernel.Plugins.Info.Author','sergey korowkin');
   snQueryVersion: Service:=hpVersion;
   snQueryReqVer: Service:=kernelVersion;
   snsMessage: hpMessage(Buffer);
   snsAreYouScanner: Service:=snrIamScanner;
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
