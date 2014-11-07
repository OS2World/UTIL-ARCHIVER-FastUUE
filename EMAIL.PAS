{$B-}
{$IFDEF SOLID}
unit EMail;

interface

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint;

implementation
{$ELSE}
library EMail;
{$ENDIF}

{$IFDEF VIRTUALPASCAL}
uses Types, Consts_, Log, Video, Misc, Language, Config, Resource,
     Plugins, Semaphor, Wizard;
{$IFNDEF SOLID}
{$Dynamic MAIN.LIB}
{$ENDIF}
{$ENDIF}
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
 emEmail        = 1;
 emAddress      = 2;
 emName         = 3;

const
 emailVersion   = $00010100;
 emailDivider   : set of char = [' ', ' ', ':', ';'];
 emailChars     : set of char = ['a'..'z', 'A'..'Z', '0'..'9', '-', '.', '_'];
 emailMake      : boolean = false;
 emailCollect   : boolean = false;
 emailSort      : byte = 0;

{$i scan.inc}
{$i common.inc}

type
 PRecord = ^TRecord;
 TRecord = object(TObject)
 public
  email: PString;
  name: PString;
  address: TAddress;
  constructor Init(AEMail, AName: String; AAddress: TAddress);
  constructor Load(var S: TStream);
  procedure Store(var S: TStream);
  destructor Done; virtual;
 end;

constructor TRecord.Init(AEMail, AName: String; AAddress: TAddress);
 begin
  inherited Init;
  EMail:=NewStr(AEMail);
  Name:=NewStr(AName);
  Address.Zone:=AAddress.Zone;
  Address.Net:=AAddress.Net;
  Address.Node:=AAddress.Node;
  Address.Point:=AAddress.Point;
 end;

constructor TRecord.Load(var S: TStream);
 begin
  EMail:=NewStr(S.ReadStr);
  Name:=NewStr(S.ReadStr);
  S.Read(Address, SizeOf(Address));
 end;

procedure TRecord.Store;
 begin
  S.WriteStr(GetPString(EMail));
  S.WriteStr(GetPString(Name));
  S.Write(Address, SizeOf(Address));
 end;

destructor TRecord.Done;
 begin
  DisposeStr(email);
  DisposeStr(name);
  inherited Done;
 end;

type
 PEMails = ^TEMails;
 TEMails = object(TObject)
 public
  FName: String;
  Items: TCollection;
  constructor Init(AFName: String);
  procedure Add(AEMail, AName: String; AAddress: TAddress);
  procedure Load;
  procedure Store;
  procedure Make(FileName: String);
  destructor Done; virtual;
 end;

constructor TEMails.Init;
 begin
  inherited Init;
  FName:=AFName;
  Items.Init;
  Load;
 end;

procedure TEMails.Add(AEMail, AName: String; AAddress: TAddress);
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
    R:=New(PRecord, Init(AEMail, AName, AAddress));
    Items.Insert(R);
   end
  else
   begin
    DisposeStr(R^.EMail);
    DisposeStr(R^.Name);
    R^.EMail:=NewStr(AEmail);
    R^.Name:=NewStr(AName);
   end;
 end;

procedure TEMails.Load;
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

procedure TEMails.Store;
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

destructor TEMails.Done;
 var
  R, E: PRecord;
 begin
  Store;
  Items.FreeAll;
  Items.Done;
  inherited Done;
 end;

var
 emails: PEmails;
 msg: PMessage;

procedure CheckEMail(S: PString);
 var
  K: Integer;
  L: Integer;
  E: String;
  _dogs, _dots, _ldot, _qpos, _dpos: Integer;
 begin
  if S = Nil then
   Exit;

  K:=Pos('@', S^);

  if (K <= 1) or (K = Byte(S^[0])) then
   Exit;

  E:='@';

  for L:=K - 1 downto 1 do
   if S^[L] in emailChars then
    E:=Concat(S^[L], E)
   else
    Break;

  for L:=K + 1 to Length(S^) do
   if S^[L] in emailChars then
    E:=Concat(E, S^[L])
   else
    Break;

  _dogs:=0;
  _dots:=0;
  _dpos:=0;
  _qpos:=Pos('>', S^);

  if _qpos = 0 then
   _qpos:=255;

  for L:=1 to Length(E) do
   case E[L] of
    '@':
     begin
      _dpos:=L;

      inc(_dogs);

      if _dogs > 1 then
       Exit;
     end;
    '.':
     begin
      inc(_dots);

      _ldot:=L;

      if E[L + 1] in ['0'..'9'] then
       Exit;
     end;
   end;

  E:=stLocase(E);

  if (E[0] < #7) or
     (_dots = 0) or
     (Pos('@.', E) <> 0) or
     (Pos('.@', E) <> 0) or
     (E[1] in ['.', '@', '0'..'9']) or
     (E[Byte(E[0])] in ['.', '@']) or
     (Pos('-@', E) <> 0) or
     (Pos('@-', E) <> 0) or
     (Pos('.', Copy(E, Pos('@', E), 255)) = 0) or
     (Length(E) - _ldot >= 5) or
     (Length(E) - _ldot < 2) or
     (Pos('.fidonet.org', E) <> 0) or
     (_qpos < 6) or
     (_ldot - _dpos < 3) or
     (_dpos < 3) then
      Exit;

  { todo:
     - таблица гейтов фидо/интернет
     - таблица недопустимых суффиксов
  }

  if EMails <> Nil then
   EMails^.Add(E, Msg^.iFrom, Msg^.iFromAddress);
 end;

procedure emMessage;
 var
  K: Longint;
 begin
  for K:=1 to cmCount(Msg^.Data) do
   CheckEmail(cmAt(Msg^.Data, K));
 end;

const
 Macros: Pointer = nil;
 Cache: PStrings = nil;
var
 F: Text;

procedure WriteLine(S: String);
 begin
  if IOResult <> 0 then;

  WriteLn(F, S);

  if IOResult <> 0 then;
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

    if not umEmptyLine(Macros) then
     WriteLine(S);
   end;

  cmDisposeObject(List);
 end;

procedure CacheStrings(const Key: String);
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

    if not umEmptyLine(Macros) then
     WriteLine(S);
   end;
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

function Sort_EMail(C: PCollection; Key1, Key2: Longint): Longint; Far;
 var
  K1, K2: PRecord;
 begin
  K1:=C^.At(Key1);
  K2:=C^.At(Key2);

  if GetPString(K1^.EMail) < GetPString(K2^.EMail) then Sort_EMail:=-1 else
  if GetPString(K1^.EMail) > GetPString(K2^.EMail) then Sort_EMail:=1 else
   if GetPString(K1^.Name) < GetPString(K2^.Name) then Sort_EMail:=-1 else
   if GetPString(K1^.Name) > GetPString(K2^.Name) then Sort_EMail:=1 else
    Sort_EMail:=0;
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
  if GetPString(K1^.EMail) < GetPString(K2^.EMail) then Sort_Address:=-1 else
  if GetPString(K1^.EMail) > GetPString(K2^.EMail) then Sort_Address:=1 else
   Sort_Address:=0;
 end;

procedure TEMails.Make;
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

  case emailSort of
   emEmail: Items.Sort(Sort_EMail);
   emAddress: Items.Sort(Sort_Address);
   emName: Items.Sort(Sort_Name);
  end;

  Macros:=umCreateMacros;
  cmCreateStrings(Cache);

  ProcessStrings('EMail.Header');
  CacheStrings('EMail.Center');
  for K:=1 to Items.Count do
   begin
    C:=Items.At(K);
    umAddMacro(Macros, '@email', GetPString(C^.Email));
    umAddMacro(Macros, '@name', GetPString(C^.Name));
    umAddMacro(Macros, '@address', Address2Str(C^.Address));
    ProcessCachedStrings;
   end;
  ProcessStrings('EMail.Footer');

  cmDisposeObject(Cache);
  umDestroyMacros(Macros);
  Close(F);
 end;

procedure emMake(FileName: String);
 begin
  EMails^.Make(FileName);
 end;

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint; {$IFNDEF SOLID}export;{$ENDIF}
 var
  S: String;
 begin
  Service:=srYes;
  case ServiceNumber of
   snStartup:
    begin
     S:=StUpcase(Trim(cGetParam('EMail.Sort')))+' ';
     case S[1] of
      'E': emailSort:=emEmail;
      'A': emailSort:=emAddress;
      'N': emailSort:=emName;
     else
      emailSort:=emName;
     end;
     emailMake:=cGetBoolParam('EMail.Make');
     emailCollect:=cGetBoolParam('EMail.Collect');
     if cGetParam('EMail.Base')='' then
      begin
       lngBegin;
       lngPush('EMail.Base');
       lngPush('-1');
       lngPrint('Main', 'error.cant.create');
       lngEnd;
       sSetExitNow;
       Exit;
      end;
     if cGetParam('EMail.Output')='' then
      begin
       lngBegin;
       lngPush('EMail.Output');
       lngPush('-1');
       lngPrint('Main', 'error.cant.create');
       lngEnd;
       sSetExitNow;
       Exit;
      end;
     EMails:=New(PEMails, Init(cGetParam('EMail.Base')));
    end;
   snStart: if (emailMake) and (EMails <> nil) and (not sExitNow) then EMails^.Make(cGetParam('EMail.Output'));
   snShutdown:
    begin
     if EMails<>Nil then Dispose(EMails, Done);
    end;
   snAfterStartup:
    begin
{     mCheckPlugin('E-MAIL', 'SCANNER');}
     mCheckPlugin('E-MAIL', 'USER');
    end;
   snQueryName: sSetSemaphore('Kernel.Plugins.Info.Name','E-MAIL');
   snQueryAuthor: sSetSemaphore('Kernel.Plugins.Info.Author','sergey korowkin');
   snQueryVersion: Service:=emailVersion;
   snQueryReqVer: Service:=kernelVersion;
   snsAreYouScanner: Service:=snrIamScanner;
   snsMessage:
    if emailCollect then
     begin
      msg:=Buffer;
      emMessage;
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
