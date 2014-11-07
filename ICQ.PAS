{$B-}
{$IFDEF SOLID}
unit ICQ;

interface

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint;

implementation
{$ELSE}
library ICQ;
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
 icqVersion     = $00010000;
 icqMake        : boolean = false;
 icqCollect     : boolean = false;
 icqSort        : byte = 0;

 icqICQ         = 1;
 icqAddress     = 2;
 icqName        = 3;

{$i scan.inc}
{$i common.inc}

type
 PRecord = ^TRecord;
 TRecord = object(TObject)
 public
  icq: PString;
  name: PString;
  address: TAddress;
  constructor Init(AICQ, AName: String; AAddress: TAddress);
  constructor Load(var S: TStream);
  procedure Store(var S: TStream);
  destructor Done; virtual;
 end;

constructor TRecord.Init(AICQ, AName: String; AAddress: TAddress);
 begin
  inherited Init;
  ICQ:=NewStr(AICQ);
  Name:=NewStr(AName);
  Address.Zone:=AAddress.Zone;
  Address.Net:=AAddress.Net;
  Address.Node:=AAddress.Node;
  Address.Point:=AAddress.Point;
 end;

constructor TRecord.Load(var S: TStream);
 begin
  ICQ:=NewStr(S.ReadStr);
  Name:=NewStr(S.ReadStr);
  S.Read(Address, SizeOf(Address));
 end;

procedure TRecord.Store;
 begin
  S.WriteStr(GetPString(ICQ));
  S.WriteStr(GetPString(Name));
  S.Write(Address, SizeOf(Address));
 end;

destructor TRecord.Done;
 begin
  DisposeStr(icq);
  DisposeStr(name);
  inherited Done;
 end;

type
 PICQs = ^TICQs;
 TICQs = object(TObject)
 public
  FName: String;
  Items: TCollection;
  constructor Init(AFName: String);
  procedure Add(AICQ, AName: String; AAddress: TAddress);
  procedure Load;
  procedure Make(FileName: String);
  procedure Store;
  destructor Done; virtual;
 end;

constructor TICQs.Init;
 begin
  inherited Init;
  FName:=AFName;
  Items.Init;
  Load;
 end;

procedure TICQs.Add(AICQ, AName: String; AAddress: TAddress);
 var
  R, Last: PRecord;
  K: Longint;
 begin
  R:=Nil;
  Last:=Items.At(Items.Count);
  for K:=1 to Items.Count do
   if GetPString(PRecord(Items.At(K))^.Name) = AName then R:=Items.At(K);
  if R=Nil then
   begin
    R:=New(PRecord, Init(AICQ, AName, AAddress));
    Items.Insert(R);
   end
  else
   begin
    DisposeStr(R^.ICQ);
    DisposeStr(R^.Name);
    R^.ICQ:=NewStr(AICQ);
    R^.Name:=NewStr(AName);
   end;
 end;

procedure TICQs.Load;
 var
  S: TBufStream;
  Z: Longint;
  R, C, L: PRecord;
 begin
  S.Init(FName, stOpenRead, 2048);
  if S.Status<>stOk then
   begin
    S.Done;
    Exit;
   end;
  Z:=S.GetSize;
  while S.GetPos<>Z do
   begin
    R:=New(PRecord, Load(S));
    Items.Insert(R);
   end;
  S.Done;
 end;

procedure TICQs.Store;
 var
  S: TBufStream;
  K: Longint;
 begin
  S.Init(FName, stCreate, 2048);
  if S.Status<>stOk then
   begin
    lngBegin;
    lngPush(FName);
    lngPush(Long2Str(S.Status));
    lngPrint('Main', 'error.cant.create');
    lngEnd;
    S.Done;
    Exit;
   end;
  for K:=1 to Items.Count do
   PRecord(Items.At(K))^.Store(S);
  S.Done;
 end;

destructor TICQs.Done;
 begin
  Store;
  Items.FreeAll;
  Items.Done;
  inherited Done;
 end;

var
 icqs: PICQs;
 msg: PMessage;

procedure CheckICQ(_S: PString);
 var
  S, T: String;
  K, L: Integer;
  icqStart, icqEnd: Integer;
 begin
  if (_S=Nil) then Exit;
  S:=stLocase(_S^);
  K:=Pos('icq', S);
  if K = 0 then K:=Pos('uin', S);
  if K = 0 then Exit;

  L:=K + 13;
  if L > Length(S) then L:=Length(S);

  icqStart:=0;
  for L:=K + 1 to L do
   if S[L] in ['0'..'9'] then
    begin
     icqStart:=L;
     Break;
    end;

  if icqStart = 0 then Exit;

  icqEnd:=Length(S) + 1;
  for K:=icqStart to Length(S) do
   if not (S[K] in ['0'..'9', '-']) then
    begin
     icqEnd:=K-1;
     Break;
    end;

  T:='';
  for K:=icqStart to icqEnd do
   if S[K] in ['0'..'9'] then
    T:=T+S[K];

  if Length(T) <= 6 then Exit;

  if ICQs<>Nil then ICQs^.Add(T, Msg^.iFrom, Msg^.iFromAddress);
 end;

procedure emMessage;
 var
  K: Longint;
 begin
  for K:=1 to cmCount(Msg^.Data) do
   CheckICQ(cmAt(Msg^.Data, K));
 end;

const
 Macros: Pointer = nil;
 Cache: PStrings = nil;
var
 F: Text;

procedure WriteLine(S: String);
 begin
  {$i-}
  InOutRes:=0;
  WriteLn(F, S);
  InOutRes:=0;
 end;

procedure ProcessStrings(Key: String);
 var
  List: PStrings;
  K: Longint;
  S: String;
 begin
  cmCreateStrings(List);
  cProcessList(Key, List);
  for K:=1 to cmCount(List) do
   begin
    S:=umProcessMacro(Macros, GetPString(cmAt(List, K)));
    if not umEmptyLine(Macros) then WriteLine(S);
   end;
  cmDisposeObject(List);
 end;

procedure CacheStrings(Key: String);
 begin
  cmFreeAll(Cache);
  cProcessList(Key, Cache);
 end;

procedure ProcessCachedStrings;
 var
  S: String;
  K: Longint;
 begin
  for K:=1 to cmCount(Cache) do
   begin
    S:=umProcessMacro(Macros, GetPString(cmAt(Cache, K)));
    if not umEmptyLine(Macros) then WriteLine(S);
   end;
 end;

function GetICQ(R: PRecord): longint;
 var
  K: Longint;
 begin
  Str2Longint(GetPString(R^.ICQ), K);
  GetICQ:=K;
 end;

function Sort_Name(C: PCollection; Key1, Key2: Longint): Longint; Far;
 var
  K1, K2: PRecord;
 begin
  K1:=C^.At(Key1);
  K2:=C^.At(Key2);
  if GetPString(K1^.Name) < GetPString(K2^.Name) then Sort_Name:=-1 else
  if GetPString(K1^.Name) > GetPString(K2^.Name) then Sort_Name:=1 else
   Sort_Name:=0;
 end;

function Sort_ICQ(C: PCollection; Key1, Key2: Longint): Longint; Far;
 var
  K1, K2: PRecord;
 begin
  K1:=C^.At(Key1);
  K2:=C^.At(Key2);
  if GetICQ(K1) < GetICQ(K2) then Sort_ICQ:=-1 else
  if GetICQ(K1) > GetICQ(K2) then Sort_ICQ:=1 else
  if GetPString(K1^.Name) < GetPString(K2^.Name) then Sort_ICQ:=-1 else
  if GetPString(K1^.Name) > GetPString(K2^.Name) then Sort_ICQ:=1 else
   Sort_ICQ:=0;
 end;

function Sort_Address(C: PCollection; Key1, Key2: Longint): Longint; Far;
 var
  K1, K2: PRecord;
 begin
  K1:=C^.At(Key1);
  K2:=C^.At(Key2);
  if K1^.Address.Zone < K2^.Address.Zone then Sort_Address:=-1 else
  if K1^.Address.Zone > K2^.Address.Zone then Sort_Address:=1 else
  if K1^.Address.Net < K2^.Address.Net then Sort_Address:=-1 else
  if K1^.Address.Net > K2^.Address.Net then Sort_Address:=1 else
  if K1^.Address.Node < K2^.Address.Node then Sort_Address:=-1 else
  if K1^.Address.Node > K2^.Address.Node then Sort_Address:=1 else
  if K1^.Address.Point < K2^.Address.Point then Sort_Address:=-1 else
  if K1^.Address.Point > K2^.Address.Point then Sort_Address:=1 else
  if GetPString(K1^.Name) < GetPString(K2^.Name) then Sort_Address:=-1 else
  if GetPString(K1^.Name) > GetPString(K2^.Name) then Sort_Address:=1 else
  if GetICQ(K1) < GetICQ(K2) then Sort_Address:=-1 else
  if GetICQ(K1) > GetICQ(K2) then Sort_Address:=1 else
   Sort_Address:=0;
 end;

procedure TICQs.Make;
 var
  C: PRecord;
  K: Longint;
 begin
  if sExitNow then Exit;
  mCreate(JustPathName(Filename));
  Assign(F, Filename);
  Rewrite(F);
  if InOutRes<>0 then
   begin
    lngBegin;
    lngPush(FileName);
    lngPush(Long2Str(IOResult));
    lngPrint('Main', 'error.cant.create');
    lngEnd;
    sSetExitNow;
    Exit;
   end;

  lngBegin;
  lngPush(FileName);
  lngPrint('Main', 'producing.stuff');
  lngEnd;

  case icqSort of
   icqICQ: Items.Sort(Sort_ICQ);
   icqAddress: Items.Sort(Sort_Address);
   icqName: Items.Sort(Sort_Name);
  end;

  Macros:=umCreateMacros;
  cmCreateStrings(Cache);

  ProcessStrings('ICQ.Header');
  CacheStrings('ICQ.Center');
  for K:=1 to Items.Count do
   begin
    C:=Items.At(K);
    umAddMacro(Macros, '@icq', GetPString(C^.ICQ));
    umAddMacro(Macros, '@name', GetPString(C^.Name));
    umAddMacro(Macros, '@address', Address2Str(C^.Address));
    ProcessCachedStrings;
   end;
  ProcessStrings('ICQ.Footer');

  cmDisposeObject(Cache);
  umDestroyMacros(Macros);
  Close(F);
 end;

procedure emMake(FileName: String);
 begin
  ICQs^.Make(FileName);
 end;

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint; {$IFNDEF SOLID}export;{$ENDIF}
 var
  S: String;
 begin
  Service:=srYes;
  case ServiceNumber of
   snStartup:
    begin
     S:=StUpcase(Trim(cGetParam('ICQ.Sort')))+' ';
     case S[1] of
      'I': icqSort:=icqICQ;
      'A': icqSort:=icqAddress;
      'N': icqSort:=icqName;
     else
      icqSort:=icqName;
     end;
     icqMake:=cGetBoolParam('ICQ.Make');
     icqCollect:=cGetBoolParam('ICQ.Collect');
     if cGetParam('ICQ.Base')='' then
      begin
       lngBegin;
       lngPush('ICQ.Base');
       lngPush('-1');
       lngPrint('Main', 'error.cant.create');
       lngEnd;
       sSetExitNow;
       Exit;
      end;
     if cGetParam('ICQ.Output')='' then
      begin
       lngBegin;
       lngPush('ICQ.Output');
       lngPush('-1');
       lngPrint('Main', 'error.cant.create');
       lngEnd;
       sSetExitNow;
       Exit;
      end;
     ICQs:=New(PICQs, Init(cGetParam('ICQ.Base')));
    end;
   snStart: if (icqMake) and (ICQs <> nil) and (not sExitNow) then ICQs^.Make(cGetParam('ICQ.Output'));
   snShutdown:
    begin
     if ICQs<>Nil then Dispose(ICQs, Done);
    end;
   snAfterStartup: mCheckPlugin('ICQ', 'USER');
   snQueryName: sSetSemaphore('Kernel.Plugins.Info.Name','ICQ');
   snQueryAuthor: sSetSemaphore('Kernel.Plugins.Info.Author','sergey korowkin');
   snQueryVersion: Service:=icqVersion;
   snQueryReqVer: Service:=kernelVersion;
   snsMessage:
    if icqCollect then
     begin
      msg:=Buffer;
      emMessage;
     end;
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
