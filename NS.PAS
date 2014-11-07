{$IFDEF SOLID}
unit NS;

interface

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint;

implementation
{$ELSE}
library NS;
{$ENDIF}

{$IfDef VIRTUALPASCAL}
uses Types, Consts_, Log, Video, Misc, Language, Config, Resource,
     Division,
     Plugins, Semaphor, Wizard,
     nsCommon, nsScan;
{$IFNDEF SOLID}
{$Dynamic MAIN.LIB}
{$ENDIF}
{$EndIF}
{$IFDEF DPMI}
uses
{$IFDEF SOLID}
     Plugins, Semaphor, Language, Misc, Config, Video, Division,
{$ELSE}
     Decl,
{$ENDIF}
     Wizard, Consts_, Dos, Macroz, Types,
     nsCommon, nsScan;
{$ENDIF}

{$i scan.inc}

function nsStartup: Longint;
 var
  G: PCollection;
  K: Longint;
 begin
  nsCollect:=cGetBoolParam('ns.Collect');
  nsBase:=cGetParam('ns.Base');

  if nsBase = '' then
   begin
    lngPrint('Main', 'ns.wrong.base');

    nsStartup:=srNo;
    Exit;
   end;

  nsStartup:=srYes;
  Groups:=New(PCollection, Init);

  G:=gGroups;
  for K:=1 to cmCount(G) do
   begin
    msgGroup:=cmAt(G, K);
    Group:=Nil;

    for K:=1 to Groups^.Count do
     if PGroup(Groups^.At(K))^.Group = msgGroup then
      begin
       Group:=Groups^.At(K);
       Break;
      end;

    if Group = Nil then
     begin
      Group:=New(PGroup, Init(msgGroup));
      Groups^.Insert(Group);
     end;
   end;
 end;

procedure nsStore;
 var
  K: Longint;
  F: TBufStream;
 begin
  F.Init(nsBase, stCreate, $F000);

  if F.Status <> stOk then
   begin
    lngBegin;
     lngPush(nsBase);
     lngPush(HexL(F.Status));
     lngPrint('Main', 'error.cant.create');
    lngEnd;
    Exit;
   end;

  for K:=1 to Groups^.Count do
   PGroup(Groups^.At(K))^.Store(F);

  F.Done;
 end;

procedure nsShutdown;
 begin
  nsStore;

  Dispose(Groups, Done);
 end;

procedure nsStart;
 begin
 end;

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint; {$IFNDEF SOLID}export;{$ENDIF}
 var
  S: String;
 begin
  Service:=srYes;
  case ServiceNumber of
   snStartup: Service:=nsStartup;
   snStart: nsStart;
   snShutdown: nsShutdown;
   snAfterStartup:;
   snQueryName: sSetSemaphore('Kernel.Plugins.Info.Name','NewStat');
   snQueryAuthor: sSetSemaphore('Kernel.Plugins.Info.Author','sergey korowkin');
   snQueryVersion: Service:=nsVersion;
   snQueryReqVer: Service:=kernelVersion;
   snsAreYouScanner: Service:=snrIamScanner;
   snsMessage:
    if nsCollect then
     begin
      msg:=Buffer;
      nsMessage;
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
