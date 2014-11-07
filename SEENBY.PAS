{$IFDEF SOLID}
unit SeenBY;

interface

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint;

implementation
{$ELSE}
library SeenBY;
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

{$i scan.inc}
{$i common.inc}

const
 seenbyMake                        : Boolean             = True;
 seenbyCollect                     : Boolean             = True;
 seenbyVersion                                           = $00010000;
 seenbyRevisionC                   : Array[1..4] of Char = 'iREN';

var
 seenbyRevision                   : Longint absolute seenbyRevisionC;
 revision                         : Longint;
 msg                              : PMessage;
 Bases                            : PCollection;
 sb_Database                      : String;
 sb_Output                        : String;
 sb_S                             : String;
 sb_S1                            : String;
 sb_Net                           : Longint;
 sb_Node                          : Longint;

type
 PNode = ^TNode;
 TNode = record
  Node: Longint;
 end;

 PNet = ^TNet;
 TNet = object(TCollection)
 public
  Number: Longint;
  constructor Init(ANumber: Longint);
  procedure FreeItem(Item: Pointer); virtual;
  procedure Store(var S: TStream); virtual;
  constructor Load(var S: TStream);
  destructor Done; virtual;
 end;

 PBase = ^TBase;
 TBase = object(TObject)
 public
  DataBase: PString;
  Output: PString;
  Nets: PCollection;
  constructor Init(ADataBase, AOutput: String);
  procedure Store(var S: TStream); virtual;
  procedure Load(var S: TStream); virtual;
  destructor Done; virtual;
 end;

constructor TNet.Init(ANumber: Longint);
 begin
  inherited Init;
  Number:=ANumber;
 end;

procedure TNet.FreeItem(Item: Pointer);
 begin
  if Item <> Nil then Dispose(PNode(Item));
 end;

procedure TNet.Store(var S: TStream);
 var
  K: Longint;
 begin
  S.Write(Number, SizeOf(Number));
  S.Write(Count, SizeOf(Count));
  for K:=1 to Count do
   S.Write(PNode(At(K))^, SizeOf(TNode));
 end;

constructor TNet.Load(var S: TStream);
 var
  K: Longint;
  L: Longint;
  N: PNode;
 begin
  Init(0);
  S.Read(Number, SizeOf(Number));
  S.Read(L, SizeOf(L));
  for K:=1 to L do
   begin
    New(N);
    S.Read(N^, SizeOf(TNode));
    Insert(N);
   end;
 end;

destructor TNet.Done;
 begin
  inherited Done;
 end;

constructor TBase.Init;
 begin
  inherited Init;
  DataBase:=NewStr(ADataBase);
  Output:=NewStr(AOutput);
  Nets:=New(PCollection, Init);
 end;

procedure TBase.Store;
 var
  K: Longint;
 begin
  S.Write(Nets^.Count, SizeOf(Nets^.Count));
  for K:=1 to Nets^.Count do
   PNet(Nets^.At(K))^.Store(S);
 end;

procedure TBase.Load;
 var
  K: Longint;
  L: Longint;
  N: PNet;
 begin
  S.Read(L, SizeOf(L));
  for K:=1 to L do
   begin
    N:=New(PNet, Load(S));
    Nets^.Insert(N);
   end;
 end;

destructor TBase.Done;
 begin
  DisposeStr(DataBase);
  DisposeStr(Output);
  Dispose(Nets, Done);
  inherited Done;
 end;

function xCheckForMask(S: String; Ss: PStrings): Boolean;
 var
  K: Longint;
 begin
  xCheckForMask:=False;
  S:=Trim(StUpcase(S));
  for K:=1 to cmCount(Ss) do
   if mCheckWildCard(S, Trim(StUpcase(GetPString(cmAt(Ss, K))))) then
    begin
     xCheckForMask:=True;
     Exit;
    end;
 end;

function sbOpenBase(G: PStrings): PBase;
 var
  K: Longint;
  B: PBase;
  db: TBufStream;
 begin
  sbOpenBase:=Nil;
  sb_Database:=Trim(gGetParam(G, 'SeenBy.Database'));
  if sb_Database = '' then Exit;
  sb_Database:=StUpcase(sb_Database);
  for K:=1 to Bases^.Count do
   if PBase(Bases^.At(K))^.Database^ = sb_Database then
    begin
     sbOpenBase:=Bases^.At(K);
     Exit;
    end;
  sb_Output:=Trim(gGetParam(G, 'SeenBy.Output'));
  B:=New(PBase, Init(sb_Database, sb_Output));
  Bases^.Insert(B);
  if ExistFile(sb_Database) then
   begin
    db.Init(sb_Database, stOpenRead, 2048);
    if db.Status = stOk then
     begin
      db.Read(Revision, SizeOf(Revision));
      if Revision <> seenbyRevision then
       begin
        lngBegin;
        lngPush(sb_Database);
        lngPrint('Main', 'seenby.old.base');
        lngEnd;
       end
      else
       begin
        B^.Load(db);
        lngBegin;
        lngPush(sb_Database);
        lngPrint('Main', 'seenby.loaded');
        lngEnd;
       end;
     end
    else
     begin
      lngBegin;
      lngPush(sb_DataBase);
      lngPush(Long2Str(db.Status));
      lngPrint('Main', 'error.cant.open');
      lngEnd;
     end;
    db.Done;
   end
  else
   begin
    lngBegin;
    lngPush(sb_DataBase);
    lngPush(gGetParam(G, 'Name'));
    lngPrint('Main', 'seenby.created');
    lngEnd;
   end;
  sbOpenBase:=B;
 end;

procedure sbStartup;
 var
  K: Longint;
  L: PStrings;
 begin
  seenbyMake:=cGetBoolParam('seenby.Make');
  seenbyCollect:=cGetBoolParam('seenby.Collect');
  bases:=New(PCollection, Init);
  cmCreateStrings(L);
  cProcessList('seenby.Groups', L);
  for K:=1 to cmCount(gGroups) do
   if xCheckForMask(gGetParam(cmAt(gGroups, K), 'Name'), L) then
    sbOpenBase(cmAt(gGroups, K));
  cmDisposeObject(L);
 end;

procedure sbShutdown;
 var
  K: Longint;
  B: PBase;
  db: TBufStream;
 begin
  for K:=1 to Bases^.Count do
   begin
    B:=Bases^.At(K);
    db.Init(B^.Database^, stCreate, 2048);
    if db.Status <> stOk then
     begin
      lngBegin;
      lngPush(B^.Database^);
      lngPush(Long2Str(db.Status));
      lngPrint('Main', 'error.cant.create');
      lngEnd;
     end
    else
     begin
      Revision:=seenbyRevision;
      db.Write(Revision, SizeOf(Revision));
      B^.Store(db);
      lngBegin;
      lngPush(B^.Database^);
      lngPrint('Main', 'seenby.saved');
      lngEnd;
     end;
    db.Done;
   end;
  Dispose(bases, Done);
 end;

procedure sbMessage;
 var
  K: Longint;
  L: Longint;
  M: Longint;
  S: PString;
  G: PStrings;
  B: PBase;
  N: PNet;
  D: PNode;
 begin
  G:=msg^.Group;
  if G = Nil then Exit;
  B:=sbOpenBase(G);
  if B = Nil then Exit;
  for K:=1 to cmCount(msg^.Data) do
   begin
    S:=cmAt(msg^.Data, K);
    if S = Nil then Continue;
    if Copy(S^, 1, 9) <> 'SEEN-BY: ' then Continue;
    sb_S:=S^;
    Delete(sb_S, 1, 9);
    for L:=1 to WordCount(sb_S, [' ']) do
     begin
      sb_S1:=ExtractWord(L, sb_S, [' ']);
      if Pos('/', sb_S1) <> 0 then
       begin
        Str2Longint(ExtractWord(1, sb_S1, ['/']), sb_Net);
        Str2Longint(ExtractWord(2, sb_S1, ['/']), sb_Node);
       end
      else
       Str2Longint(sb_S1, sb_Node);
      N:=Nil;
      for M:=1 to B^.Nets^.Count do
       if PNet(B^.Nets^.At(M))^.Number = sb_Net then
        begin
         N:=B^.Nets^.At(M);
         Break;
        end;
      if N = Nil then
       begin
        N:=New(PNet, Init(sb_Net));
        B^.Nets^.Insert(N);
       end;
      D:=Nil;
      for M:=1 to N^.Count do
       if PNode(N^.At(M))^.Node = sb_Node then
        begin
         D:=N^.At(M);
         Break;
        end;
      if D = Nil then
       begin
        New(D);
        D^.Node:=sb_Node;
        N^.Insert(D);
       end;
     end;
   end;
 end;

function Sort_Nets(C: PCollection; Key1, Key2: Longint): Longint; far;
 begin
  if PNet(C^.At(Key1))^.Number < PNet(C^.At(Key2))^.Number then Sort_Nets:=-1 else
  if PNet(C^.At(Key1))^.Number > PNet(C^.At(Key2))^.Number then Sort_Nets:=1 else
   Sort_Nets:=0;
 end;

function Sort_Nodes(C: PCollection; Key1, Key2: Longint): Longint; far;
 begin
  if PNode(C^.At(Key1))^.Node < PNode(C^.At(Key2))^.Node then Sort_Nodes:=-1 else
  if PNode(C^.At(Key1))^.Node > PNode(C^.At(Key2))^.Node then Sort_Nodes:=1 else
   Sort_Nodes:=0;
 end;

procedure sbMake;
 var
  K: Longint;
  L: Longint;
  M: Longint;
  B: PBase;
  Net: PNet;
  F: Text;
 begin
  if sExitNow then
   begin
    lngPrint('Main', 'seenby.cannot.make');
    Exit;
   end;
  lngPrint('Main', 'seenby.making.1');
  for K:=1 to Bases^.Count do
   begin
    B:=Bases^.At(K);
    if GetPString(B^.Output) = '' then Continue;
    B^.Nets^.Sort(Sort_Nets);
    {$I-}
    InOutRes:=0;
    Assign(F, B^.Output^);
    Rewrite(F);
    if IOResult = 0 then
     begin
      for L:=1 to B^.Nets^.Count do
       begin
        Net:=B^.Nets^.At(L);
        WriteLn(F, Net^.Number);
        sb_S:='';
        Net^.Sort(Sort_Nodes);
        for M:=1 to Net^.Count do
         begin
          sb_S:=sb_S + ' /' + Long2Str(PNode(Net^.At(M))^.Node);
          if Length(sb_S) > 70 then
           begin
            WriteLn(F, sb_S);
            sb_S:='';
           end;
         end;
        if sb_S <> '' then
         WriteLn(F, sb_S);
        WriteLn(F, '');
       end;
     end;
    Close(F);
    InOutRes:=0;
    lngPrint('Main', 'seenby.making.2');
   end;
  lngPrint('Main', 'seenby.making.3');
 end;

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint; {$IFNDEF SOLID}export;{$ENDIF}
 var
  S: String;
 begin
  Service:=srYes;
  case ServiceNumber of
   snStartup: sbStartup;
   snStart: if seenbyMake then sbMake;
   snShutdown: sbShutdown;
   snAfterStartup:;
   snQueryName: sSetSemaphore('Kernel.Plugins.Info.Name','SeenBY');
   snQueryAuthor: sSetSemaphore('Kernel.Plugins.Info.Author','sergey korowkin');
   snQueryVersion: Service:=seenbyVersion;
   snQueryReqVer: Service:=kernelVersion;
   snsAreYouScanner: Service:=snrIamScanner;
   snsMessage:
    if seenbyCollect then
     begin
      msg:=Buffer;
      sbMessage;
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
