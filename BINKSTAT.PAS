{$IFDEF SOLID}
unit BinkStat;

interface

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint;

implementation
{$ELSE}
library BinkStat;
{$ENDIF}

{$IfDef VIRTUALPASCAL}
uses Types, Consts_, Log, Video, Misc, Language, Config, Resource,
     Plugins, Semaphor, Wizard, Dos;
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

{$i common.inc}

const
 binkstatVersion      = $00010000;

function binkstatStartup: Longint;
 begin
  binkstatStartup:=srYes;
 end;

procedure binkstatAfterStartup;
 begin
  mCheckPlugin('BINKSTAT', 'USER');
  mCheckPlugin('BINKSTAT', 'MSGOUT');
  mCheckPlugin('BINKSTAT', 'ANNOUNCER');
 end;

procedure binkstatShutdown;
 begin
 end;

procedure binkstatStart; forward;

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint; {$IFNDEF SOLID}export;{$ENDIF}
 var
  S: String;
 begin
  Service:=srYes;
  case ServiceNumber of
   snStartup: Service:=binkstatStartup;
   snStart: binkstatStart;
   snShutdown: binkstatShutdown;
   snAfterStartup: binkstatAfterStartup;
   snQueryName: sSetSemaphore('Kernel.Plugins.Info.Name','BiNKSTAT');
   snQueryAuthor: sSetSemaphore('Kernel.Plugins.Info.Author','sergey korowkin');
   snQueryVersion: Service:=binkstatVersion;
   snQueryReqVer: Service:=kernelVersion;
  else
   Service:=srNotSupported;
  end;
 end;

{$IFNDEF SOLID}
exports
 SERVICE;
{$ENDIF}

{* Start *}
const
 smNoSort               = 0;
 smSize                 = 1;
 smAddress              = 2;
 smSizeReverse          = 3;
 smAddressReverse       = 4;

type
 POutbound = ^TOutbound;
 TOutbound = object(TObject)
 public
  Directory: PString;
  Domain: PString;
  Zone: Longint;
  constructor Init(ADirectory, ADomain: String; AZone: Longint);
  destructor Done; virtual;
 end;

constructor TOutbound.Init(ADirectory, ADomain: String; AZone: Longint);
 begin
  inherited Init;
  Directory:=NewStr(AddBackSlash(ADirectory));
  Domain:=NewStr(ADomain);
  Zone:=AZone;
 end;

destructor TOutbound.Done;
 begin
  DisposeStr(Directory);
  DisposeStr(Domain);
  inherited Done;
 end;

const
 ftUnknown      = 0;
 ftLO           = 1;
 ftNetmail      = 2;
 ftArcmail      = 3;

 flUnknown      = 0;
 flImmediate    = 1;
 flCrash        = 2;
 flDirect       = 3;
 flNormal       = 4;
 flHold         = 5;

type
 PFlavour = ^TFlavour;
 TFlavour = record
  NetMail, ArcMail, Files: Boolean;
 end;

 PNode = ^TNode;
 TNode = object(TObject)
 public
  Address: TAddress;
  NetMail, ArcMail, Files: Longint;
  Skip: Boolean;
  Flavours: Array[0..5] of TFlavour;
  Domain: PString;
 end;

 PBlock = ^TBlock;
 TBlock = object(TObject)
 public
  Output: PString;
  tplHeader: PStrings;
  tplItem: PStrings;
  tplFooter: PStrings;
  Outbounds: PCollection;
  SortBy: Longint;
  Error: Boolean;
  Nodes: PCollection;
  Outbound: POutbound;
  constructor Init;
  procedure ParseSelf(Block: String); virtual;
  function GetNode(Address: TAddress): PNode; virtual;
  procedure Count; virtual;
  procedure ScanOutbound(O: POutbound); virtual;
  function IsPointDirectory(var Sr: SearchRec): Boolean; virtual;
  function IsValidFlavour(C: Char): Boolean; virtual;
  function IsCountableFile(var Sr: SearchRec): Boolean; virtual;
  function IsBusy(FName: String): Boolean; virtual;
  function GetFileFlavour(FName: String): Longint; virtual;
  function GetFileType(FName: String): Longint; virtual;
  procedure ParseNodeFName(FName: String; var Net, Node: Longint);
  procedure ParsePointFName(FName: String; var Point: Longint);
  procedure ProcessFile(FName: String; Address: TAddress); virtual;
  procedure ScanNodeDirectory(Dir: String); virtual;
  procedure ScanPointDirectory(Dir: String); virtual;
  function GetFlavourMap(Node: PNode): String; virtual;
  procedure Generate; virtual;
  destructor Done; virtual;
 end;

constructor TBlock.Init;
 begin
  inherited Init;
  Output:=Nil;
  cmCreateStrings(tplHeader);
  cmCreateStrings(tplItem);
  cmCreateStrings(tplFooter);
  Outbounds:=New(PCollection, Init);
  Nodes:=New(PCollection, Init);
  SortBy:=smNoSort;
  Error:=False;
 end;

procedure TBlock.ParseSelf(Block: String);
 var
  C: PStrings;
  Outs: PStrings;
  Outb: POutbound;
  S: String;
  K, Z: Longint;
  Reverse: Boolean;
 begin
  Error:=True;
  C:=bSearch(Block);
  if C = Nil then
   begin
    lngBegin;
    lngPush(Block);
    lngPrint('Main', 'binkstat.unknown.block');
    lngEnd;
    Exit;
   end;
  S:=iGetParam(C, 'Output');
  if S = '' then
   begin
    lngBegin;
    lngPush(Block);
    lngPrint('Main', 'binkstat.error.in.block');
    lngEnd;
    Exit;
   end;
  Output:=NewStr(S);
  cmCreateStrings(Outs);
  iProcessList(C, 'Outbounds', Outs);
  for K:=1 to cmCount(Outs) do
   begin
    S:=GetPString(cmAt(Outs, K));
    Str2Longint(ExtractWord(2, S, [' ']), Z);
    Outb:=New(POutbound, Init(ExtractWord(1, S, [' ']), ExtractWord(3, S, [' ']), Z));
    Outbounds^.Insert(Outb);
   end;
  cmDisposeObject(Outs);
  iProcessList(C, 'Header', tplHeader);
  iProcessList(C, 'Node', tplItem);
  iProcessList(C, 'Footer', tplFooter);
  S:=Trim(StUpcase(iGetParam(C, 'Sort')));
  Reverse:=Copy(S, 1, 1) = '-';
  if Reverse then Delete(S, 1, 1);
  if (S[0] = #0) or (not (S[1] in ['S', 'A', 'N'])) then
   begin
    lngBegin;
    lngPush(Block);
    lngPrint('Main', 'binkstat.error.in.block');
    lngEnd;
    Exit;
   end;
  case S[1] of
   'S': SortBy:=smSize;
   'A': SortBy:=smAddress;
   'N': SortBy:=smNoSort;
  end;
  if Reverse then
   case SortBy of
    smSize: SortBy:=smSizeReverse;
    smAddress: SortBy:=smAddressReverse;
   end;
  Error:=False;
 end;

function TBlock.GetNode(Address: TAddress): PNode;
 var
  K: Longint;
  Node: PNode;
 begin
  for K:=1 to Nodes^.Count do
   begin
    Node:=Nodes^.At(K);
    if (Node^.Address.Zone = Address.Zone) and
       (Node^.Address.Net = Address.Net) and
       (Node^.Address.Node = Address.Node) and
       (Node^.Address.Point = Address.Point) then
        begin
         GetNode:=Node;
         Exit;
        end;
   end;
  Node:=New(PNode, Init);
  Node^.Address:=Address;
  Node^.NetMail:=0;
  Node^.ArcMail:=0;
  Node^.Files:=0;
  Node^.Skip:=False;
  FillChar(Node^.Flavours, SizeOf(Node^.Flavours), 0);
  Node^.Domain:=Outbound^.Domain;
  Nodes^.Insert(Node);
  GetNode:=Node;
 end;

var
 Reverse: Boolean;

function SortBy_Address(C: PCollection; Key1, Key2: Longint): Longint; Far;
 var
  K1, K2: PNode;
  R: Longint;
 begin
  K1:=C^.At(Key1);
  K2:=C^.At(Key2);
  if K1^.Address.Zone < K2^.Address.Zone then R:=-1 else
  if K1^.Address.Zone > K2^.Address.Zone then R:=1 else
  if K1^.Address.Net < K2^.Address.Net then R:=-1 else
  if K1^.Address.Net > K2^.Address.Net then R:=1 else
  if K1^.Address.Node < K2^.Address.Node then R:=-1 else
  if K1^.Address.Node > K2^.Address.Node then R:=1 else
  if K1^.Address.Point < K2^.Address.Point then R:=-1 else
  if K1^.Address.Point > K2^.Address.Point then R:=1 else
   R:=0;
  if Reverse then R:=-R;
  SortBy_Address:=R;
 end;

function SortBy_Size(C: PCollection; Key1, Key2: Longint): Longint; Far;
 var
  K1, K2: PNode;
  R: Longint;
 begin
  K1:=C^.At(Key1);
  K2:=C^.At(Key2);
  if K1^.Netmail + K1^.Arcmail + K1^.Files < K2^.Netmail + K2^.Arcmail + K2^.Files then R:=-1 else
  if K1^.Netmail + K1^.Arcmail + K1^.Files > K2^.Netmail + K2^.Arcmail + K2^.Files then R:=1 else
  if K1^.Address.Zone < K2^.Address.Zone then R:=-1 else
  if K1^.Address.Zone > K2^.Address.Zone then R:=1 else
  if K1^.Address.Net < K2^.Address.Net then R:=-1 else
  if K1^.Address.Net > K2^.Address.Net then R:=1 else
  if K1^.Address.Node < K2^.Address.Node then R:=-1 else
  if K1^.Address.Node > K2^.Address.Node then R:=1 else
  if K1^.Address.Point < K2^.Address.Point then R:=-1 else
  if K1^.Address.Point > K2^.Address.Point then R:=1 else
   R:=0;
  if Reverse then R:=-R;
  SortBy_Size:=R;
 end;

procedure TBlock.Count;
 var
  K: Longint;
 begin
  for K:=1 to Outbounds^.Count do
   ScanOutbound(Outbounds^.At(K));
  case SortBy of
   smAddress:
    begin
     Reverse:=False;
     Nodes^.Sort(SortBy_Address);
    end;
   smSize:
    begin
     Reverse:=False;
     Nodes^.Sort(SortBy_Size);
    end;
   smAddressReverse:
    begin
     Reverse:=True;
     Nodes^.Sort(SortBy_Address);
    end;
   smSizeReverse:
    begin
     Reverse:=True;
     Nodes^.Sort(SortBy_Size);
    end;
  end;
 end;

procedure TBlock.ScanOutbound(O: POutbound);
 begin
  Outbound:=O;
  ScanNodeDirectory(GetPString(O^.Directory));
 end;

function TBlock.IsPointDirectory(var Sr: SearchRec): Boolean;
 begin
  IsPointDirectory:=(Sr.Attr and (VolumeID + Directory) = Directory) and (StUpcase(JustExtension(Sr.Name)) = 'PNT');
 end;

function TBlock.IsValidFlavour(C: Char): Boolean;
 begin
  C:=Upcase(C);
  IsValidFlavour:=C in ['H', 'I', 'C', 'F', 'N', 'O', 'D'];
 end;

function TBlock.GetFileFlavour(FName: String): Longint;
 begin
  FName:=StUpcase(JustExtension(FName));
  if FName[0] = #0 then Exit;
  case FName[1] of
   'I': GetFileFlavour:=flImmediate;
   'C': GetFileFlavour:=flCrash;
   'D': GetFileFlavour:=flDirect;
   'F': GetFileFlavour:=flNormal;
   'N': GetFileFlavour:=flNormal;
   'O': GetFileFlavour:=flNormal;
   'H': GetFileFlavour:=flHold;
  else
   GetFileFlavour:=flUnknown;
  end;
 end;

function TBlock.GetFileType(FName: String): Longint;
 begin
  GetFileType:=ftUnknown;
  FName:=StUpcase(JustExtension(FName));
  if FName[0] = #0 then Exit;
  if IsValidFlavour(FName[1]) then
   begin
    if Copy(FName, 2, 2) = 'LO' then
     begin
      GetFileType:=ftLO;
      Exit;
     end;
    if Copy(FName, 2, 2) = 'UT' then
     begin
      GetFileType:=ftNetmail;
      Exit;
     end;
   end;
  if (Copy(FName, 1, 2) = 'SU') or (Copy(FName, 1, 2) = 'MO') or
     (Copy(FName, 1, 2) = 'TU') or (Copy(FName, 1, 2) = 'WE') or
     (Copy(FName, 1, 2) = 'TH') or (Copy(FName, 1, 2) = 'FR') or
     (Copy(FName, 1, 2) = 'SA') then
      begin
       GetFileType:=ftArcmail;
       Exit;
      end;
 end;

function TBlock.IsCountableFile(var Sr: SearchRec): Boolean;
 var
  S: String;
  FileType: Longint;
 begin
  FileType:=GetFileType(Sr.Name);
  S:=JustExtension(StUpcase(Sr.Name));
  IsCountableFile:=(S[0] <> #0) and IsValidFlavour(S[1]) and ((FileType = ftLO) or (FileType = ftNetmail));
 end;

function TBlock.IsBusy(FName: String): Boolean;
 begin
  IsBusy:=ExistFile(ForceExtension(FName, 'BSY')) or ExistFile(ForceExtension(FName, 'CSY'));
 end;

procedure TBlock.ParseNodeFName(FName: String; var Net, Node: Longint);
 begin
  FName:=JustFileName(FName);
  Str2Longint('$' + Copy(FName, 1, 4), Net);
  Str2Longint('$' + Copy(FName, 5, 4), Node);
 end;

procedure TBlock.ParsePointFName(FName: String; var Point: Longint);
 begin
  FName:=JustFileName(FName);
  Str2Longint('$' + Copy(FName, 1, 8), Point);
 end;

procedure TBlock.ProcessFile(FName: String; Address: TAddress);
 var
  Node: PNode;
  FileType: Longint;
  Flavour: Longint;
  Size: Longint;
  S: String;
  F: Text;
 begin
  Node:=GetNode(Address);
  if Node^.Skip then Exit;
  if IsBusy(FName) then
   begin
    Node^.Skip:=True;
    Exit;
   end;
  Flavour:=GetFileFlavour(FName);
  case GetFileType(FName) of
   ftLO:
    begin
     {$I-}
     if IOResult <> 0 then;
     Assign(F, FName);
     Reset(F);
     if IOResult <> 0 then
      begin
       Node^.Skip:=True;
       Exit;
      end;
     while not Eof(F) do
      begin
       ReadLn(F, S);
       if (S[0] = #0) or (S[1] = '~') then Continue;
       if (S[1] in ['#', '^']) then Delete(S, 1, 1);
       FileType:=GetFileType(S);
       case FileType of
        ftArcMail: Node^.Flavours[Flavour].ArcMail:=True;
       else
        Node^.Flavours[Flavour].Files:=True;
       end;
       Size:=GetFileSize(S);
       if Size <> -1 then
        case FileType of
         ftArcMail: Inc(Node^.ArcMail, Size);
        else
         Inc(Node^.Files, Size);
        end;
      end;
     Close(F);
     if IOResult <> 0 then;
    end;
   ftNetmail:
    begin
     Size:=GetFileSize(FName);
     if Size = -1 then
      Node^.Skip:=True
     else
      Inc(Node^.Netmail, Size);
     Node^.Flavours[Flavour].NetMail:=True;
    end;
  end;
 end;

procedure TBlock.ScanNodeDirectory(Dir: String);
 var
  Sr: SearchRec;
  Address: TAddress;
 begin
  FindFirst(Dir + '*.*', AnyFile, Sr);
  Address.Zone:=Outbound^.Zone;
  Address.Point:=0;
  while DosError = 0 do
   begin
    if IsPointDirectory(Sr) then ScanPointDirectory(Dir + Sr.Name + '\');
    if IsCountableFile(Sr) then
     begin
      ParseNodeFName(Sr.Name, Address.Net, Address.Node);
      ProcessFile(Dir + Sr.Name, Address);
     end;
    FindNext(Sr);
   end;
  FindClose(Sr);
 end;

procedure TBlock.ScanPointDirectory(Dir: String);
 var
  Sr: SearchRec;
  Address: TAddress;
 begin
  Address.Zone:=Outbound^.Zone;
  ParseNodeFName(RemoveBackSlash(Dir), Address.Net, Address.Node);
  FindFirst(Dir + '*.*', AnyFile, Sr);
  while DosError = 0 do
   begin
    if IsCountableFile(Sr) then
     begin
      ParsePointFName(Sr.Name, Address.Point);
      ProcessFile(Dir + Sr.Name, Address);
     end;
    FindNext(Sr);
   end;
  FindClose(Sr);
 end;

function TBlock.GetFlavourMap(Node: PNode): String;
 var
  S: String;
  K: Longint;
 begin
  S:='';
  for K:=flImmediate to flHold do
   begin
    if Node^.Flavours[K].NetMail then S:=S + 'M' else S:=S + '.';
    if Node^.Flavours[K].ArcMail then S:=S + 'A' else S:=S + '.';
    if Node^.Flavours[K].Files   then S:=S + 'X' else S:=S + '.';
   end;
  GetFlavourMap:=S;
 end;

procedure TBlock.Generate;
 var
  Macros: Pointer;
  Destination: PStrings;
 procedure AddMacro(Name, Value: String);
  begin
   umAddMacro(Macros, Name, Value);
  end;
 procedure ReInitMacros;
  begin
   umDestroyMacros(Macros);
   Macros:=umCreateMacros;
  end;
 procedure Process(List: PStrings);
  var
   S: String;
   K: Longint;
  begin
   for K:=1 to cmCount(List) do
    begin
     S:=umProcessMacro(Macros, GetPString(cmAt(List, K)));
     if not umEmptyLine(Macros) then
      cmInsert(Destination, cmNewStr(S));
    end;
  end;
 var
  K: Longint;
  Node: PNode;
  S: String;
  TotalNetmail, TotalArcmail, TotalFiles: Longint;
  F: Text;
 begin
  (* startup *)
  Macros:=umCreateMacros;
  cmCreateStrings(Destination);
  TotalNetmail:=0;
  TotalArcmail:=0;
  TotalFiles:=0;
  (* main processing *)
  ReInitMacros;
  Process(tplHeader);
  for K:=1 to Nodes^.Count do
   begin
    Node:=Nodes^.At(K);
    ReInitMacros;
    AddMacro('@azone', Long2Str(Node^.Address.Zone));
    AddMacro('@anet', Long2Str(Node^.Address.Net));
    AddMacro('@anode', Long2Str(Node^.Address.Node));
    AddMacro('@apoint', Long2Str(Node^.Address.Point));
    if Node^.Domain = Nil then
     begin
      AddMacro('@adomain', '');
      AddMacro('@addresstrim', Address2StrTrim(Node^.Address));
      AddMacro('@address', Address2Str(Node^.Address));
     end
    else
     begin
      AddMacro('@adomain', '@' + Node^.Domain^);
      AddMacro('@addresstrim', Address2StrTrim(Node^.Address) + '@' + Node^.Domain^);
      AddMacro('@address', Address2Str(Node^.Address) + '@' + Node^.Domain^);
     end;
    AddMacro('@netmail', Long2Str(Node^.NetMail));
    AddMacro('@arcmail', Long2Str(Node^.ArcMail));
    AddMacro('@files', Long2Str(Node^.Files));
    AddMacro('@map', GetFlavourMap(Node));
    Process(tplItem);
    Inc(TotalNetmail, Node^.Netmail);
    Inc(TotalArcmail, Node^.Arcmail);
    Inc(TotalFiles, Node^.Files);
   end;
  ReInitMacros;
  AddMacro('@netmail', Long2Str(TotalNetMail));
  AddMacro('@arcmail', Long2Str(TotalArcMail));
  AddMacro('@files', Long2Str(TotalFiles));
  AddMacro('@total', Long2Str(TotalNetmail + TotalArcmail + TotalFiles));
  AddMacro('@nodes', Long2Str(Nodes^.Count));
  Process(tplFooter);
  (* write to file *)
  {$I-}
  if IOResult <> 0 then;
  mCreate(JustPathName(GetPString(Output)));
  Assign(F, GetPString(Output));
  Rewrite(F);
  if InOutRes = 0 then
   begin
    for K:=1 to cmCount(Destination) do
     WriteLn(F, GetPString(cmAt(Destination, K)));
    lngBegin;
    lngPush(GetPString(Output));
    lngPrint('Main', 'binkstat.created');
    lngEnd;
   end
  else
   begin
    lngBegin;
    lngPush(GetPString(Output));
    lngPush(Long2Str(IOResult));
    lngPrint('Main', 'error.cant.create');
    lngEnd;
   end;
  Close(F);
  if IOResult <> 0 then;
  (* shutdown *)
  cmDisposeObject(Destination);
  umDestroyMacros(Macros);
 end;

destructor TBlock.Done;
 begin
  DisposeStr(Output);
  cmDisposeObject(tplHeader);
  cmDisposeObject(tplItem);
  cmDisposeObject(tplFooter);
  Dispose(Outbounds, Done);
  Dispose(Nodes, Done);
  inherited Done;
 end;

procedure binkstatStart;
 var
  Blocks: PStrings;
  Block: PBlock;
  K: Longint;
 begin
  cmCreateStrings(Blocks);
  cProcessList('binkstat.Blocks', Blocks);
  for K:=1 to cmCount(Blocks) do
   begin
    Block:=New(PBlock, Init);
    Block^.ParseSelf(GetPString(cmAt(Blocks, K)));
    if not Block^.Error then
     begin
      Block^.Count;
      Block^.Generate;
     end;
    Dispose(Block, Done);
   end;
  cmDisposeObject(Blocks);
 end;

begin
end.
