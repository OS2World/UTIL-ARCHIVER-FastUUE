{$B-}
{$IFDEF SOLID}
unit PathBld;

interface

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint;

implementation
{$ELSE}
library PathBld;
{$ENDIF}

{$IfDef VIRTUALPASCAL}
uses Dos, Types, Consts_, Log, Video, Misc, Language, Config, Resource,
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

type
 TBldAddress = record
  Net, Node: Longint;
 end;

const
 pathbldVersion   = $00010200;
 pathbldRevision  = $deadf1d0;
 revision         : Longint = 0;
 msg              : PMessage = nil;
 pathbldMake      : boolean = False;
 pathbldCollect   : boolean = False;
 Roots            : PCollection = Nil;
 Queue            : PCollection = Nil;
var
 pb_Database      : String;
 pb_Root          : String;
 pb_Output        : String;
 pb_S             : String;
 pb_D             : String;
 pb_RootAddress   : TBldAddress;
 TextFile         : Text;

type
 PNode = ^TNode;

 TNodeForEach = procedure(Level: Longint; Node: PNode);

 TNode = object(TCollection)
 public
  Owner: PNode;
  Address: TBldAddress;
  Used: Longint;
  Date: Longint;
  constructor Init(AAddress: TBldAddress);
  procedure ForEach(var Level: Longint; Proc: TNodeForEach);
  procedure Store(var S: TStream);
  procedure Load(var S: TStream);
 end;

 PRoot = ^TRoot;
 TRoot = object(TObject)
 public
  Messages: Longint;
  FileName: String;
  OutFileName: String;
  Group: PStrings;
  Root: PNode;
  constructor Init(AFileName: String; AGroup: PStrings; RootAddr: TBldAddress);
  procedure Store(var S: TStream); virtual;
  procedure Load(var S: TStream); virtual;
  destructor Done; virtual;
 end;

constructor TNode.Init;
 begin
  inherited Init;
  Address:=AAddress;
  Used:=0;
  Date:=0;
 end;

procedure TNode.ForEach;
 var
  K: Longint;
 begin
  Inc(Level);
  Proc(Level, @Self);
  for K:=1 to Count do
   PNode(At(K))^.ForEach(Level, Proc);
  Dec(Level);
 end;

procedure TNode.Store(var S: TStream);
 var
  K: Longint;
 begin
  S.Write(Address, SizeOf(Address));
  S.Write(Used, SizeOf(Used));
  S.Write(Date, SizeOf(Date));
  S.Write(Count, SizeOf(Count));
  for K:=1 to Count do
   PNode(At(K))^.Store(S);
 end;

procedure TNode.Load(var S: TStream);
 var
  K, L: Longint;
  N: PNode;
 begin
  FreeAll;
  S.Read(Address, SizeOf(Address));
  S.Read(Used, SizeOf(Used));
  S.Read(Date, SizeOf(Date));
  S.Read(L, SizeOf(L));
  for K:=1 to L do
   begin
    N:=New(PNode, Init(Address));
    Insert(N);
    N^.Load(S);
   end;
 end;

constructor TRoot.Init(AFileName: String; AGroup: PStrings; RootAddr: TBldAddress);
 begin
  inherited Init;
  FileName:=AFileName;
  Group:=AGroup;
  Root:=New(PNode, Init(RootAddr));
 end;

procedure TRoot.Store(var S: TStream);
 begin
  Root^.Store(S);
 end;

procedure TRoot.Load(var S: TStream);
 begin
  Root^.Load(S);
 end;

destructor TRoot.Done;
 begin
  Dispose(Root, Done);
  inherited Done;
 end;

function SortHandler(C: PCollection; Key1, Key2: Longint): Longint; Far;
 var
  K1, K2: PNode;
 begin
  K1:=C^.At(Key1);
  K2:=C^.At(Key2);
  if K1^.Address.Net < K2^.Address.Net then SortHandler:=-1 else
  if K1^.Address.Net > K2^.Address.Net then SortHandler:=1 else
   if K1^.Address.Node < K2^.Address.Node then SortHandler:=-1 else
   if K1^.Address.Node > K2^.Address.Node then SortHandler:=1 else
    SortHandler:=0;
 end;

procedure Handler(Level: Longint; Node: PNode); Far;
 var
  K: Longint;
  S: String;
  D: Char;
  P: PNode;
  DT: DateTime;
 begin
  {check'em}
  for K:=1 to Node^.Count do
   PNode(Node^.At(K))^.Owner:=Node;
  {sort'em}
  Node^.Sort(SortHandler);
  {build'em}
  S:='';
  P:=Node;
  while P <> Nil do
   begin
    D:=' ';
    if P^.Owner = Nil then
     D:=' '
    else
     if P = Node then
      if P^.At(1) <> Nil then
       if P^.Owner^.IndexOf(P) = P^.Owner^.Count then
        D:='À'
       else
        D:='Ã'
      else
       if P^.Owner^.IndexOf(P) = P^.Owner^.Count then
        D:='À'
       else
        D:='Ã'
     else
      if P^.Owner^.IndexOf(P) <> P^.Owner^.Count then
       D:='³'
      else
       D:=' ';
    if D in ['Ã', 'À'] then
     S:=D + 'Ä' + S
    else
     S:=D + ' ' + S;
    P:=P^.Owner;
   end;
  Delete(S, 1, 2);
  S:=S + Long2Str(Node^.Address.Net) + '/' + Long2Str(Node^.Address.Node);
  if (Length(S) < 61) and (Node^.Owner <> Nil) then
   begin
    S:=PadCh(S + ' ', '.', 61);
    UnpackTime(Node^.Date, DT);
    S:=S + ' [' + LeftPadCh(Long2Str(Node^.Used), '0', 5) + ']';
    with DT do
     S:=S + ' ' + Copy(GetPktDateTimeCustom(Day, Month, Year, Hour, Min, Sec), 1, 9);
   end;
  WriteLn(TextFile, S);
 end;

procedure pbMake;
 var
  K: Longint;
  Root: PRoot;
  Level: Longint;
 begin
  if sExitNow then
   begin
    lngPrint('Main', 'pathbld.cannot.make');
    Exit;
   end;
  lngPrint('Main', 'pathbld.making.1');
  for K:=1 to Roots^.Count do
   begin
    Root:=Roots^.At(K);
    if Trim(Root^.OutFileName) = '' then Continue;
    mCreate(JustPathName(Root^.OutFileName));
    {$I-}
    InOutRes:=0;
    Assign(TextFile, Root^.OutFileName);
    Rewrite(TextFile);
    if IOResult = 0 then
     begin
      Level:=0;
      Root^.Root^.ForEach(Level, Handler);
     end;
    Close(TextFile);
    InOutRes:=0;
    lngPrint('Main', 'pathbld.making.2');
   end;
  lngPrint('Main', 'pathbld.making.3');
 end;

function Compare(N1, N2: PNode): boolean;
 begin
  Compare:=(N1^.Address.Net = N2^.Address.Net) and (N1^.Address.Node = N2^.Address.Node);
 end;

function pbOpenArea(Group: PStrings): PRoot;
 var
  Root: PRoot;
  K: Longint;
  db: TBufStream;
 begin
  pbOpenArea:=Nil;
  Root:=Nil;
  pb_DataBase:=Trim(gGetParam(Group, 'PathBld.Database'));
  if pb_DataBase = '' then Exit;
  pb_Database:=StUpcase(pb_Database);
  { search for Root, if it already in list }
  for K:=1 to Roots^.Count do
   if PRoot(Roots^.At(K))^.Filename = pb_DataBase then
    begin
     Root:=Roots^.At(K);
     Break;
    end;
  if Root = Nil then
   begin
    pb_Root:=Trim(gGetParam(Group, 'PathBld.Root'));
    pb_Output:=Trim(gGetParam(Group, 'PathBld.Output'));
    if pb_Root = '' then
     begin
      sSetExitNow;
      lngBegin;
      lngPush(gGetParam(Group, 'Name'));
      lngPrint('Main', 'pathbld.wrong.root');
      lngEnd;
      Exit;
     end;
    if pb_Output = '' then
     begin
      sSetExitNow;
      lngBegin;
      lngPush(gGetParam(Group, 'Name'));
      lngPrint('Main', 'pathbld.wrong.output');
      lngEnd;
      Exit;
     end;
    pb_RootAddress.Net:=0;
    pb_RootAddress.Node:=0;
    Str2Longint(ExtractWord(1, pb_Root, ['/']), pb_RootAddress.Net);
    Str2Longint(ExtractWord(2, pb_Root, ['/']), pb_RootAddress.Node);
    if (pb_RootAddress.Net = 0) {or (pb_RootAddress.Node = 0) }then
     begin
      sSetExitNow;
      lngBegin;
      lngPush(gGetParam(Group, 'Name'));
      lngPrint('Main', 'pathbld.wrong.root');
      lngEnd;
      Exit;
     end;
    Root:=New(PRoot, Init(pb_DataBase, Group, pb_RootAddress));
    Root^.OutFileName:=pb_Output;
    Roots^.Insert(Root);
    if ExistFile(pb_DataBase) then
     begin
      db.Init(pb_DataBase, stOpenRead, 2048);
      if db.Status = stOk then
       begin
        db.Read(Revision, SizeOf(Revision));
        if Revision <> pathbldRevision then
         begin
          lngBegin;
          lngPush(pb_DataBase);
          lngPrint('Main', 'pathbld.old.base');
          lngEnd;
         end
        else
         begin
          Root^.Root^.Load(db);
          lngBegin;
          lngPush(pb_DataBase);
          lngPrint('Main', 'pathbld.loaded');
          lngEnd;
         end;
       end
      else
       begin
        lngBegin;
        lngPush(pb_DataBase);
        lngPush(Long2Str(db.Status));
        lngPrint('Main', 'error.cant.open');
        lngEnd;
       end;
      db.Done;
     end
    else
     begin
      lngBegin;
      lngPush(pb_DataBase);
      lngPush(gGetParam(Group, 'Name'));
      lngPrint('Main', 'pathbld.created');
      lngEnd;
     end;
   end;
  pbOpenArea:=Root;
 end;

procedure pbMessage;
 var
  Group: PStrings;
  Root: PRoot;
  Current: PNode;
  Pretendent: PNode;
  K: Longint;
  L: Longint;
  S: PString;
  DT: DateTime;
  Dow: XWord;
 begin
  Group:=gSearchByArea(msg^.iArea);
  if Group = Nil then Exit;
  Root:=pbOpenArea(Group);
  if Root = Nil then Exit;
  for K:=1 to cmCount(Msg^.Data) do
   begin
    S:=cmAt(Msg^.Data, K);
    if S = Nil then Continue;
    if Copy(S^, 1, 7) <> #1'PATH: ' then Continue;
    pb_S:=S^;
    Delete(pb_S, 1, 7);
    for L:=1 to WordCount(pb_S, [' ']) do
     begin
      pb_D:=ExtractWord(L, pb_S, [' ']);
      if Pos('/', pb_D) <> 0 then
       begin
        Str2Longint(ExtractWord(1, pb_D, ['/']), pb_RootAddress.Net);
        Str2Longint(ExtractWord(2, pb_D, ['/']), pb_RootAddress.Node);
       end
      else
       Str2Longint(pb_D, pb_RootAddress.Node);
      Queue^.Insert(New(PNode, Init(pb_RootAddress)));
     end;
   end;
  Current:=Root^.Root;
  ParsePktDateTime(msg^.iDate, DT.Day, DT.Month, DT.Year, DT.Hour, DT.Min, DT.Sec, Dow);
  for K:=Queue^.Count downto 1 do
   begin
    Pretendent:=Nil;
    for L:=1 to Current^.Count do
     if Compare(Queue^.At(K), Current^.At(L)) then
      begin
       Pretendent:=Current^.At(L);
       Break;
      end;
    if Pretendent = Nil then
     begin
      Pretendent:=New(PNode, Init(PNode(Queue^.At(K))^.Address));
      Current^.Insert(Pretendent)
     end;
    Inc(Pretendent^.Used);
    PackTime(DT, Pretendent^.Date);
    Current:=Pretendent;
   end;
  Queue^.FreeAll;
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

procedure pbStartup;
 var
  K: Longint;
  List: PStrings;
 begin
  Roots:=New(PCollection, Init);
  Queue:=New(PCollection, Init);
  pathbldMake:=cGetBoolParam('pathbld.Make');
  pathbldCollect:=cGetBoolParam('pathbld.Collect');
  cmCreateStrings(List);
  cProcessList('pathbld.Groups', List);
  for K:=1 to cmCount(gGroups) do
   if xCheckForMask(gGetParam(cmAt(gGroups, K), 'Name'), List) then
    pbOpenArea(cmAt(gGroups, K));
  cmDisposeObject(List);
 end;

procedure pbShutdown;
 var
  K: Longint;
  Root: PRoot;
  S: TBufStream;
 begin
  for K:=1 to Roots^.Count do
   begin
    Root:=Roots^.At(K);
    mCreate(JustPathName(Root^.FileName));
    S.Init(Root^.Filename, stCreate, 2048);
    if S.Status <> stOk then
     begin
      lngBegin;
      lngPush(Root^.Filename);
      lngPush(Long2Str(S.Status));
      lngPrint('Main', 'error.cant.create');
      lngEnd;
     end
    else
     begin
      Revision:=pathbldRevision;
      S.Write(Revision, SizeOf(Revision));
      Root^.Store(S);
      lngBegin;
      lngPush(Root^.Filename);
      lngPrint('Main', 'pathbld.saved');
      lngEnd;
     end;
    S.Done;
   end;
  Dispose(Roots, Done);
  Dispose(Queue, Done);
 end;

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint; {$IFNDEF SOLID}export;{$ENDIF}
 var
  S: String;
 begin
  Service:=srYes;
  case ServiceNumber of
   snStartup: pbStartup;
   snStart: if pathbldMake then pbMake;
   snShutdown: pbShutdown;
   snAfterStartup: {mCheckPlugin('E-MAIL', 'USER')};
   snQueryName: sSetSemaphore('Kernel.Plugins.Info.Name','PathBld');
   snQueryAuthor: sSetSemaphore('Kernel.Plugins.Info.Author','sergey korowkin');
   snQueryVersion: Service:=pathbldVersion;
   snQueryReqVer: Service:=kernelVersion;
   snsAreYouScanner: Service:=snrIamScanner;
   snsMessage:
    if pathbldCollect then
     begin
      msg:=Buffer;
      pbMessage;
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
