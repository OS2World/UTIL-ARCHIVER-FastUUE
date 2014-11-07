{$IFDEF SOLID}
unit Twit;

interface

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint;

implementation
{$ELSE}
library Twit;
{$ENDIF}

{$IFDEF VIRTUALPASCAL}
uses Types, Consts_, Log, Video, Misc, Language, Config, Resource,
     Plugins, Semaphor, Wizard, Dos;
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

{$i common.inc}
{$i scan.inc}
{$i masks.inc}
{$i msgout.inc}

const
 twitVersion            = $00010100;
var
 TwitEnabled            : Boolean;
 TwitGroups             : PCollection;
 Msg                    : PMessage;
type
 PTwitRules = ^TTwitRules;
 TTwitRules = object(TObject)
 public
  SubjectsKill: PStrings;
  SubjectsRemain: PStrings;
  FromNameKill: PStrings;
  FromNameRemain: PStrings;
  ToNameKill: PStrings;
  ToNameRemain: PStrings;
  FromAddressKill: PStrings;
  FromAddressRemain: PStrings;
  ToAddressKill: PStrings;
  ToAddressRemain: PStrings;
  ContainsKill: PStrings;
  ContainsRemain: PStrings;
  Actions: PStrings;
  SaveHeader: PStrings;
  SaveFooter: PStrings;
  SaveExclude: PStrings;
  SaveRemain: PStrings;
  ContinueLoop: Boolean;
  SaveInvalidate: Boolean;
  KillMySelf: Boolean;
  constructor Init(Link: PStrings; const Prefix: String);
  destructor Done; virtual;
 end;

 PTwitGroup = ^TTwitGroup;
 TTwitGroup = object(TObject)
 public
  Link: PStrings;
  Enabled: Boolean;
  Rules: PCollection;
  destructor Done; virtual;
 end;
 PBackupCollection = ^TBackupCOllection;
 TBackupCollection = object(TCollection)
 public
  procedure FreeItem(Item: Pointer); virtual;
 end;

var
 Group                  : PTwitGroup;
 Backup                 : PBackupCollection;
 SrcFromAddress         : TAddress;
 SrcToAddress           : TAddress;

procedure TBackupCollection.FreeItem;
 begin
  scanKillMessage(Item);
 end;

procedure PrepareList(List: PStrings);
 var
  K: Longint;
  S: PString;
 begin
  for K:=1 to cmCount(List) do
   begin
    S:=cmAt(List, K);
    if S <> Nil then S^:=StUpcase(Trim(S^));
   end;
 end;

constructor TTwitRules.Init(Link: PStrings; const Prefix: String);
 begin
  inherited Init;
  cmCreateStrings(SubjectsKill);
  cmCreateStrings(SubjectsRemain);
  cmCreateStrings(FromNameKill);
  cmCreateStrings(FromNameRemain);
  cmCreateStrings(ToNameKill);
  cmCreateStrings(ToNameRemain);
  cmCreateStrings(FromAddressKill);
  cmCreateStrings(FromAddressRemain);
  cmCreateStrings(ToAddressKill);
  cmCreateStrings(ToAddressRemain);
  cmCreateStrings(Actions);
  cmCreateStrings(SaveHeader);
  cmCreateStrings(SaveFooter);
  cmCreateStrings(SaveExclude);
  cmCreateStrings(SaveRemain);
  cmCreateStrings(ContainsKill);
  cmCreateStrings(ContainsRemain);

  gProcessList(Link, Prefix + 'Subjects', SubjectsKill);
  gProcessList(Link, Prefix + 'Subjects.Remain', SubjectsRemain);
  PrepareList(SubjectsKill);
  PrepareList(SubjectsRemain);

  gProcessList(Link, Prefix + 'FromName', FromNameKill);
  gProcessList(Link, Prefix + 'FromName.Remain', FromNameRemain);
  PrepareList(FromNameKill);
  PrepareList(FromNameRemain);

  gProcessList(Link, Prefix + 'ToName', ToNameKill);
  gProcessList(Link, Prefix + 'ToName.Remain', ToNameRemain);
  PrepareList(ToNameKill);
  PrepareList(ToNameRemain);

  gProcessList(Link, Prefix + 'FromAddress', FromAddressKill);
  gProcessList(Link, Prefix + 'FromAddress.Remain', FromAddressRemain);
  PrepareList(FromAddressKill);
  PrepareList(FromAddressRemain);

  gProcessList(Link, Prefix + 'ToAddress', ToAddressKill);
  gProcessList(Link, Prefix + 'ToAddress.Remain', ToAddressRemain);
  PrepareList(ToAddressKill);
  PrepareList(ToAddressRemain);

  gProcessList(Link, Prefix + 'Contains', ContainsKill);
  gProcessList(Link, Prefix + 'Contains.Remain', ContainsRemain);
  PrepareList(ContainsKill);
  PrepareList(ContainsRemain);

  gProcessList(Link, Prefix + 'Actions', Actions);
  gProcessList(Link, Prefix + 'Save.Header', SaveHeader);
  gProcessList(Link, Prefix + 'Save.Footer', SaveFooter);
  gProcessList(Link, Prefix + 'Save.Exclude', SaveExclude);
  gProcessList(Link, Prefix + 'Save.Remain', SaveRemain);
  ContinueLoop:=gGetBoolParam(Link, Prefix + 'Continue.Loop');
  SaveInvalidate:=gGetBoolParam(Link, Prefix + 'Save.Invalidate');
  KillMySelf:=((cmCount(SubjectsKill) = 0) and
               (cmCount(FromNameKill) = 0) and
               (cmCount(ToNameKill) = 0) and
               (cmCount(FromAddressKill) = 0) and
               (cmCount(ContainsKill) = 0) and
               (cmCount(ToAddressKill) = 0)) or
               (cmCount(Actions) = 0);
 end;

destructor TTwitRules.Done;
 begin
  cmDisposeObject(SubjectsKill);
  cmDisposeObject(SubjectsRemain);
  cmDisposeObject(FromNameKill);
  cmDisposeObject(FromNameRemain);
  cmDisposeObject(ToNameKill);
  cmDisposeObject(ToNameRemain);
  cmDisposeObject(FromAddressKill);
  cmDisposeObject(FromAddressRemain);
  cmDisposeObject(ToAddressKill);
  cmDisposeObject(ToAddressRemain);
  cmDisposeObject(Actions);
  cmDisposeObject(SaveHeader);
  cmDisposeObject(SaveFooter);
  cmDisposeObject(SaveExclude);
  cmDisposeObject(SaveRemain);
  cmDisposeObject(ContainsKill);
  cmDisposeObject(ContainsRemain);
  inherited Done;
 end;

destructor TTwitGroup.Done;
 begin
  Dispose(Rules, Done);
  inherited Done;
 end;

function Startup: Longint;
 begin
  Startup:=srYes;
  TwitEnabled:=cGetBoolParam('Twit.Enabled');
  TwitGroups:=New(PCollection, Init);
  Backup:=New(PBackupCollection, Init);
 end;

procedure AfterStartup;
 begin
  mCheckPlugin('TWIT', 'USER');
  mCheckPlugin('TWIT', 'SCANNER');
 end;

procedure Shutdown;
 begin
  Dispose(TwitGroups, Done);
  Dispose(Backup, Done);
 end;

procedure Start;
 begin
 end;

procedure AddMacros(M: Pointer);
 begin
  umAddMacro(M, '@area', Msg^.iArea);
  umAddMacro(M, '@fromname', Msg^.iFrom);
  umAddMacro(M, '@toname', Msg^.iTo);
  umAddMacro(M, '@fromaddress', Address2Str(Msg^.iFromAddress));
  umAddMacro(M, '@toaddress', Address2Str(Msg^.iToAddress));
  umAddMacro(M, '@srcfromaddress', Address2Str(SrcFromAddress));
  umAddMacro(M, '@srctoaddress', Address2Str(SrcToAddress));
  umAddMacro(M, '@subject', Msg^.iSubj);
  umAddMacro(M, '@datetime', Msg^.iDate);
  umAddMacro(M, '@cdatetime', GetPktDateTime);
  umAddMacro(M, '@fromzone', Long2Str(Msg^.iFromAddress.Zone));
  umAddMacro(M, '@fromnet', Long2Str(Msg^.iFromAddress.Net));
  umAddMacro(M, '@fromnode', Long2Str(Msg^.iFromAddress.Node));
  umAddMacro(M, '@frompoint', Long2Str(Msg^.iFromAddress.Point));
  umAddMacro(M, '@tozone', Long2Str(Msg^.iToAddress.Zone));
  umAddMacro(M, '@tonet', Long2Str(Msg^.iToAddress.Net));
  umAddMacro(M, '@tonode', Long2Str(Msg^.iToAddress.Node));
  umAddMacro(M, '@topoint', Long2Str(Msg^.iToAddress.Point));
 end;

procedure DoMessage(Id: String; Param: String);
 begin
  lngBegin;
  lngPush(Msg^.iFrom);
  lngPush(Msg^.iTo);
  lngPush(Address2Str(Msg^.iFromAddress));
  lngPush(Address2Str(Msg^.iToAddress));
  lngPush(Msg^.iSubj);
  lngPush(Msg^.iDate);
  lngPush(Msg^.iArea);
  lngPush(Param);
  lngPrint('Main', 'twit.do.' + Id);
  lngEnd;
 end;

procedure DoNothing;
 begin
 end;

procedure DoMacros(var Value: String);
 var
  M: Pointer;
 begin
  M:=umCreateMacros;
  AddMacros(M);
  Value:=umProcessMacro(M, Value);
  umDestroyMacros(M);
 end;

procedure DoKill;
 begin
  DoMessage('Kill', '');
  sSetSemaphore('Scanner.Message.Kill', 'Yes');
 end;

procedure DoMove(Destination: String);
 var
  I: PString;
 begin
  DoMacros(Destination);

  Destination:=StUpcase(Destination);

  I:=cmAt(Msg^.Data, 1);

  if Destination = 'NETMAIL' then
   begin
    if (I <> Nil) and (Copy(I^, 1, 5) = 'AREA:') then
     cmAtFree(Msg^.Data, 1);

    DoMessage('Move', Destination);

    Exit;
   end;

  if (I = Nil) or (Copy(I^, 1, 5) <> 'AREA:') then
   cmAtInsert(Msg^.Data, cmNewStr('AREA:' + Destination), 1)
  else
   begin
    cmAtFree(Msg^.Data, 1);
    cmAtInsert(Msg^.Data, cmNewStr('AREA:' + Destination), 1)
   end;

  DoMessage('Move', Destination);
 end;

procedure DoSave(Group: PTwitRules; const FileName: String; Header, Append: Boolean);
 var
  F: Text;
  K: Longint;
  M: Pointer;
  S: String;
  B: Boolean;
 begin
  {$I-}
  if IOResult <> 0 then;
  Assign(F, FileName);
  if Append then
   begin
    System.Append(F);
    if IOResult <> 0 then ReWrite(F);
   end
  else
   ReWrite(F);
  if InOutRes <> 0 then
   begin
    lngBegin;
    lngPush(FileName);
    lngPush(Long2Str(IOResult));
    lngPrint('Main', 'error.cant.create');
    lngEnd;
    Exit;
   end;
  if Header then
   begin
    M:=umCreateMacros;
    AddMacros(M);
    for K:=1 to cmCount(Group^.SaveHeader) do
     begin
      S:=umProcessMacro(M, GetPString(cmAt(Group^.SaveHeader, K)));
      if not umEmptyLine(M) then
       WriteLn(F, S);
     end;
   end;
  for K:=1 to cmCount(Msg^.Data) do
   begin
    S:=GetPString(cmAt(Msg^.Data, K));
    if Group^.SaveInvalidate then
     S:=uInvalidateLine(S);
    B:=CheckForMask(S, Group^.SaveExclude);
    if B then B:=not CheckForMask(S, Group^.SaveRemain);
    if not B then WriteLn(F, S);
   end;
  if Header then
   begin
    for K:=1 to cmCount(Group^.SaveFooter) do
     begin
      S:=umProcessMacro(M, GetPString(cmAt(Group^.SaveFooter, K)));
      if not umEmptyLine(M) then
       WriteLn(F, S);
     end;
    umDestroyMacros(M);
   end;
  Close(F);
  DoMessage('Save', FileName);
 end;

procedure DoCopy(Destination: String);
 var
  Data: PStrings;
  Message: PMessage;
  K: Longint;
  I: PString;
 begin
  scanDupeMessage(Msg, Message);
  Destination:=Trim(StUpcase(Destination));
  I:=cmAt(Message^.Data, 1);
  if (I = Nil) or (Copy(I^, 1, 5) <> 'AREA:') then
   cmAtInsert(Message^.Data, cmNewStr('AREA:' + Destination), 1)
  else
   begin
    cmAtFree(Message^.Data, 1);
    cmAtInsert(Message^.Data, cmNewStr('AREA:' + Destination), 1)
   end;
  cmCreateStrings(Data);
  for K:=1 to cmCount(Message^.Data) do
   cmInsert(Data, cmNewStr(GetPString(cmAt(Message^.Data, K))));
  scanAddMessage(Message^.iFrom, Message^.iTo, Message^.iSubj, Destination, Message^.iFromAddress, Message^.iToAddress, Data);
  scanKillMessage(Message);
  DoMessage('Copy', Destination);
 end;

procedure DoBackup;
 var
  M: PMessage;
 begin
  scanDupeMessage(Msg, M);

  Backup^.Insert(M);

  DoMessage('Backup', '');
 end;

procedure DoRestore;
 var
  M: PMessage;
 begin
  if Backup^.Count = 0 then
   Exit;

  M:=Backup^.At(Backup^.Count);

  scanCopyMessage(M, Msg);

  Backup^.AtFree(Backup^.Count);

  DoMessage('Restore', '');
 end;

procedure DoSetFrom(Value: String);
 begin
  DoMacros(Value);
  Msg^.iFrom:=Value;
  DoMessage('Set.From', Value);
 end;

procedure DoSetTo(Value: String);
 begin
  DoMacros(Value);
  Msg^.iTo:=Value;
  DoMessage('Set.To', Value);
 end;

procedure DoSetSubject(Value: String);
 begin
  DoMacros(Value);
  Msg^.iSubj:=Value;
  DoMessage('Set.Subject', Value);
 end;

procedure DoSetFromAddress(Value: String; Show: Boolean);
 var
  Address: TAddress;
  Line: PString;
  LineN: Longint;
 procedure SearchFor(const S: String);
  var
   K: Longint;
   D: PString;
  begin
   Line:=Nil;
   if Msg^.iArea = 'NETMAIL' then
    LineN:=1
   else
    LineN:=2;
   for K:=1 to cmCount(Msg^.Data) do
    begin
     D:=cmAt(Msg^.Data, K);
     if D = Nil then Continue;
     if Copy(D^, 1, Length(S)) = S then
      begin
       LineN:=K;
       Line:=D;
       Break;
      end;
    end;
  end;
 begin
  DoMacros(Value);
  Str2Address(Value, Address);
  Msg^.iFromAddress:=Address;
  SearchFor('MSGID:');
  if Line <> Nil then cmAtFree(Msg^.Data, LineN);
  cmAtInsert(Msg^.Data, cmNewStr('MSGID: ' + Address2Str(Address) + ' ' + uGetMSGiD), LineN);
  if Msg^.iArea = 'NETMAIL' then
   begin
    SearchFor('FMPT');
    if Line <> Nil then cmAtFree(Msg^.Data, LineN);
    if Address.Point <> 0 then
     cmAtInsert(Msg^.Data, cmNewStr('FMPT ' + Long2Str(Address.Point)), LineN);
    SearchFor('INTL');
    if Line = Nil then
     Value:='0:0/0'
    else
     begin
      Value:=ExtractWord(2, Line^, [' ']);
      cmAtFree(Msg^.Data, LineN);
     end;
    cmAtInsert(Msg^.Data, cmNewStr('INTL ' + Value + ' ' + Address2StrPointLess(Address)), LineN);
    if Show then DoMessage('Set.From.Address', Address2Str(Address));
   end
  else
   if Show then DoMessage('Set.From.Address', Address2Str(Address));
 end;

procedure DoSetToAddress(Value: String; Show: Boolean);
 var
  Address: TAddress;
  Line: PString;
  LineN: Longint;
 procedure SearchFor(const S: String);
  var
   K: Longint;
   D: PString;
  begin
   Line:=Nil;
   LineN:=1;
   for K:=1 to cmCount(Msg^.Data) do
    begin
     D:=cmAt(Msg^.Data, K);
     if D = Nil then Continue;
     if Copy(D^, 1, Length(S)) = S then
      begin
       LineN:=K;
       Line:=D;
       Break;
      end;
    end;
  end;
 begin
  DoMacros(Value);
  Str2Address(Value, Address);
  if Msg^.iArea <> 'NETMAIL' then
   begin
    if Show then DoMessage('Only.Netmail', 'SETTOADDR');
    Exit;
   end;
  SearchFor('TOPT');
  if Line <> Nil then cmAtFree(Msg^.Data, LineN);
  if Address.Point <> 0 then
   cmAtInsert(Msg^.Data, cmNewStr('TOPT ' + Long2Str(Address.Point)), LineN);
  SearchFor('INTL');
  if Line = Nil then
   Value:='0:0/0'
  else
   begin
    Value:=ExtractWord(3, Line^, [' ']);
    cmAtFree(Msg^.Data, LineN);
   end;
  cmAtInsert(Msg^.Data, cmNewStr('INTL ' + Address2StrPointLess(Address) + ' ' +  Value), LineN);
  if Show then DoMessage('Set.To.Address', Address2Str(Address));
 end;

procedure DoSwapAddress;
 var
  FromAddress, ToAddress: TAddress;
 begin
  FromAddress:=Msg^.iFromAddress;
  ToAddress:=Msg^.iToAddress;
  DoSetFromAddress(Address2Str(ToAddress), False);
  DoSetToAddress(Address2Str(FromAddress), False);
  DoMessage('Swap.Address', '');
 end;

procedure DoSwapName;
 var
  S: String;
 begin
  S:=Msg^.iTo;
  Msg^.iTo:=Msg^.iFrom;
  Msg^.iFrom:=S;
  DoMessage('Swap.Name', '');
 end;

procedure DoInvalidate(InvalidateKludges: Boolean);
 var
  K: Longint;
  S: PString;
  D: String;
 begin
  for K:=1 to cmCount(Msg^.Data) do
   begin
    S:=cmAt(Msg^.Data, K);
    if S = Nil then Continue;
    if (S^[1] = #1) and (not InvalidateKludges) then Continue;
    D:=uInvalidateLine(S^);
    cmAtFree(Msg^.Data, K);
    cmAtInsert(Msg^.Data, cmNewStr(D), K);
   end;
  if InvalidateKludges then
   DoMessage('Invalidate.With.Kludges', '')
  else
   DoMessage('Invalidate', '');
 end;

procedure DoKillStrings(Line: String; Show, Match: Boolean);
 var
  K: Longint;
  S: String;
 begin
  K:=0;
  if not Match then Line:=StUpcase(Line);
  repeat
   Inc(K);
   if K > cmCount(Msg^.Data) then Break;
   GetPStringEx(cmAt(Msg^.Data, K), S);
   if not Match then Line:=StUpcase(Line);
   if mCheckWildCard(S, Line) then
    begin
     cmAtFree(Msg^.Data, K);
     Dec(K);
    end;
  until False;
  if Show then
   DoMessage('Kill.Strings', Line);
 end;

procedure DoMakeEchomail;
 begin
  DoKillStrings('INTL*', False, False);
  DoKillStrings('FMPT*', False, False);
  DoKillStrings('TOPT*', False, False);
  DoKillStrings('Via*', False, False);
  DoMessage('Make.Echomail', '');
 end;

function SeekFirstLine: Longint;
 var
  K: Longint;
  S: PString;
 begin
  for K:=1 to cmCount(Msg^.Data) do
   begin
    S:=cmAt(Msg^.Data, K);
    if (S = Nil) or ((S^[1] <> #1) and (Copy(S^, 1, 5) <> 'AREA:')) then
     begin
      SeekFirstLine:=K;
      Exit;
     end;
   end;
  SeekFirstLine:=cmCount(Msg^.Data) + 1;
 end;

procedure DoAddHeader(const FileName: String);
 var
  F: Text;
  M: Pointer;
  S: String;
  K: Longint;
 begin
  {$I-}
  if IOResult <> 0 then;
  Assign(F, FileName);
  Reset(F);
  if InOutRes <> 0 then
   begin
    lngBegin;
    lngPush(FileName);
    lngPush(Long2Str(IOResult));
    lngPrint('Main', 'error.cant.open');
    lngEnd;
    Exit;
   end;
  M:=umCreateMacros;
  AddMacros(M);
  K:=SeekFirstLine;
  while not Eof(F) do
   begin
    ReadLn(F, S);
    S:=umProcessMacro(M, S);
    if not umEmptyLine(M) then
     begin
      cmAtInsert(Msg^.Data, cmNewStr(S), K);
      Inc(K);
     end;
   end;
  umDestroyMacros(M);
  Close(F);
  DoMessage('Add.Header', FileName);
 end;

function SeekLastLine: Longint;
 var
  K: Longint;
  S: PString;
 begin
  for K:=cmCount(Msg^.Data) downto 1 do
   begin
    S:=cmAt(Msg^.Data, K);
    if (S = Nil) or (S^[1] <> #1) and (Copy(S^, 1, 7) <> 'SEEN-BY') then
     begin
      SeekLastLine:=K + 1;
      Exit;
     end;
   end;
  SeekLastLine:=cmCount(Msg^.Data) + 1;
 end;

procedure DoAddFooter(FileName: String);
 var
  F: Text;
  M: Pointer;
  S: String;
  K: Longint;
 begin
  {$I-}
  if IOResult <> 0 then;
  Assign(F, FileName);
  Reset(F);
  if InOutRes <> 0 then
   begin
    lngBegin;
    lngPush(FileName);
    lngPush(Long2Str(IOResult));
    lngPrint('Main', 'error.cant.open');
    lngEnd;
    Exit;
   end;
  M:=umCreateMacros;
  AddMacros(M);
  K:=SeekLastLine;
  while not Eof(F) do
   begin
    ReadLn(F, S);
    S:=umProcessMacro(M, S);
    if not umEmptyLine(M) then
     begin
      cmAtInsert(Msg^.Data, cmNewStr(S), K);
      Inc(K);
     end;
   end;
  umDestroyMacros(M);
  Close(F);
  DoMessage('Add.Footer', FileName);
 end;

procedure DoDisplay(const S: String);
 begin
  DoMessage('Display', S);
 end;

procedure DoCreate(const S: String);
 begin
  uCreateFlag(S);
  DoMessage('Create', S);
 end;

procedure DoExec(S: String);
 var
  M: Pointer;
 begin
  M:=umCreateMacros;
  AddMacros(M);
  S:=umProcessMacro(M, S);
  mExec(S);
  umDestroyMacros(M);
  DoMessage('Exec', S);
 end;

procedure DoCopyAnother(const BlockName: String);
 var
  Block: PStrings;
  K: Longint;
 begin
  Block:=bSearch(BlockName);
  if Block = Nil then Exit;
  sSetSemaphore('post.Format', gGetParam(Block, 'post.Format'));
  sSetSemaphore('post.Name', gGetParam(Block, 'post.Name'));
  sSetSemaphore('post.PathName', gGetParam(Block, 'post.PathName'));
  sSetSemaphore('post.Area.Tag', gGetParam(Block, 'post.Area.Tag'));
  sSetSemaphore('post.Area.Type', gGetParam(Block, 'post.Area.Type'));
  sSetSemaphore('post.Msg.From', Address2Str(Msg^.iFromAddress) + ',' + Msg^.iFrom);
  sSetSemaphore('post.Msg.To', Address2Str(Msg^.iToAddress) + ',' + Msg^.iTo);
  sSetSemaphore('post.Msg.Subj', Msg^.iSubj);
  sSetSemaphore('post.Flag', gGetParam(Block, 'post.Flag'));
  sSetSemaphore('post.Data', HexPtr(Msg^.Data));
  sSetSemaphore('post.pkt.From', gGetParam(Block, 'post.pkt.From'));
  sSetSemaphore('post.pkt.To', gGetParam(Block, 'post.pkt.To'));
  sSetSemaphore('post.pkt.Password', gGetParam(Block, 'post.pkt.Password'));
  sSetSemaphore('post.pkt.SinglePacket', 'No');
  sSetSemaphore('post.pkt.StripStuff', 'Yes');
  sSetSemaphore('post.SinglePacket', 'No');
  K:=moPost;
  if K <> srYes then
   begin
    lngBegin;
    lngPush(HexL(K));
    lngPrint('Main', 'twit.copyanother.error');
    lngEnd;
   end
  else
   DoMessage('CopyAnother', BlockName);
 end;

function ProcessAction(Group: PTwitRules; Action: String): Boolean;
 var
  uAction: String;
 begin
  ProcessAction:=False;
  uAction:=StUpcase(Trim(Action));
  if (Action = '') or (uAction = 'NOTHING') then DoNothing else
  if (uAction = 'KILL') then DoKill else
  if (uAction = 'BACKUP') then DoBackup else
  if (uAction = 'RESTORE') then DoRestore else
  if (uAction = 'SWAPADDRESS') then DoSwapAddress else
  if (uAction = 'SWAPNAME') then DoSwapName else
  if (uAction = 'INVALIDATE') then DoInvalidate(False) else
  if (uAction = 'INVALIDATEWITHKLUDGES') then DoInvalidate(True) else
  if (uAction = 'MAKEECHOMAIL') then DoMakeEchomail else
  if (Copy(uAction, 1, 8) = 'SETFROM ') then DoSetFrom(Copy(Action, 9, 255)) else
  if (Copy(uAction, 1, 6) = 'SETTO ') then DoSetTo(Copy(Action, 7, 255)) else
  if (Copy(uAction, 1, 8) = 'SETSUBJ ') then DoSetSubject(Copy(Action, 9, 255)) else
  if (Copy(uAction, 1, 11) = 'SETSUBJECT ') then DoSetSubject(Copy(Action, 12, 255)) else
  if (Copy(uAction, 1, 12) = 'SETFROMADDR ') then DoSetFromAddress(Copy(Action, 13, 255), True) else
  if (Copy(uAction, 1, 10) = 'SETTOADDR ') then DoSetToAddress(Copy(Action, 11, 255), True) else
  if (Copy(uAction, 1, 5) = 'MOVE ') then DoMove(Copy(Action, 6, 255)) else
  if (Copy(uAction, 1, 5) = 'COPY ') then DoCopy(Copy(Action, 6, 255)) else
  if (Copy(uAction, 1, 5) = 'SAVE ') then DoSave(Group, Copy(Action, 6, 255), False, False) else
  if (Copy(uAction, 1, 9) = 'SAVEHEAD ') then DoSave(Group, Copy(Action, 10, 255), True, False) else
  if (Copy(uAction, 1, 11) = 'SAVEAPPEND ') then DoSave(Group, Copy(Action, 12, 255), False, True) else
  if (Copy(uAction, 1, 15) = 'SAVEHEADAPPEND ') then DoSave(Group, Copy(Action, 16, 255), True, True) else
  if (Copy(uAction, 1, 11) = 'KILLSTRING ') then DoKillStrings(Copy(Action, 12, 255), True, False) else
  if (Copy(uAction, 1, 15) = 'KILLSTRINGCASE ') then DoKillStrings(Copy(Action, 12, 255), True, True) else
  if (Copy(uAction, 1, 10) = 'ADDHEADER ') then DoAddHeader(Copy(Action, 11, 255)) else
  if (Copy(uAction, 1, 10) = 'ADDFOOTER ') then DoAddFooter(Copy(Action, 11, 255)) else
  if (Copy(uAction, 1, 8) = 'DISPLAY ') then DoDisplay(Copy(Action, 9, 255)) else
  if (Copy(uAction, 1, 7) = 'CREATE ') then DoCreate(Copy(Action, 8, 255)) else
  if (Copy(uAction, 1, 5) = 'EXEC ') then DoExec(Copy(Action, 6, 255)) else
  if (Copy(uAction, 1, 12) = 'COPYANOTHER ') then DoCopyAnother(Copy(Action, 13, 255)) else
   begin
    lngBegin;
    lngPush(Action);
    lngPrint('Main', 'twit.unrecognized.action');
    lngEnd;
   end;
 end;

function CheckEx(const Victim: String; Kill, Remain: PStrings): Boolean;
 var
  K: Longint;
  Perform, Item: PString;
 begin
  if (Kill^.Count = 0) then
   begin
    CheckEx:=True;
    Exit;
   end;
  CheckEx:=False;
  Perform:=Nil;
  for K:=1 to cmCount(Kill) do
   begin
    Item:=cmAt(Kill, K);
    if Item = Nil then Continue;
    if mCheckWildcard(Victim, Item^) then
     begin
      Perform:=Item;
      Break;
     end;
   end;
  if Perform = Nil then Exit;
  for K:=1 to cmCount(Remain) do
   begin
    Item:=cmAt(Remain, K);
    if Item = Nil then Continue;
    if mCheckWildcard(Victim, Item^) then Exit;
   end;
  CheckEx:=True;
 end;

function Check(Victim: String; Kill, Remain: PStrings): Boolean;
 begin
  StUpcaseEx(Victim);
  Check:=CheckEx(Victim, Kill, Remain);
 end;

var
 MsgData: PStrings;

function CheckLines(Kill, Remain: PStrings): Boolean;
 var
  K: Longint;
  S: String;
 begin
  CheckLines:=True;
  if MsgData^.Count = 0 then Exit;
  K:=0;
  repeat
   Inc(K);
   if K > cmCount(MsgData) then Break;
   GetPStringEx(cmAt(MsgData, K), S);
   if CheckEx(S, Kill, Remain) then
    Exit;
  until False;
  CheckLines:=False;
 end;

procedure Scan(AMsg: PMessage);
 procedure SearchGroup(G: PTwitGroup); far;
  begin
   if G^.Link = msg^.Group then
    Group:=G;
  end;
 var
  K: Longint;
  J: Longint;
  M: Longint;
  S: PString;
  R: PTwitRules;
  L: PStrings;
  B: PStrings;
  E: PTwitRules;
  D: String;
  C: Boolean;
 begin
  msg:=AMsg;
  if msg^.Group = Nil then Exit;
  Group:=Nil;
  for K:=1 to TwitGroups^.Count do
   SearchGroup(TwitGroups^.At(K));
  if Group = Nil then
   begin
    Group:=New(PTwitGroup, Init);
    TwitGroups^.Insert(Group);
    with Group^ do
     begin
      Link:=msg^.Group;
      Enabled:=gGetDoubleBoolParam(Link, 'Twit.Enabled');
      Rules:=New(PCollection, Init);
{      E:=New(PTwitRules, Init(Link, 'Twit.Subjects', '', '', '', '', 'Twit.Subjects.Actions', 'Twit.Subjects.'));
      if E^.KillMySelf then Dispose(E, Done) else Rules^.Insert(E);
      E:=New(PTwitRules, Init(Link, '', 'Twit.FromName', '', '', '', 'Twit.FromName.Actions', 'Twit.FromName.'));
      if E^.KillMySelf then Dispose(E, Done) else Rules^.Insert(E);
      E:=New(PTwitRules, Init(Link, '', '', 'Twit.ToName', '', '', 'Twit.ToName.Actions', 'Twit.ToName.'));
      if E^.KillMySelf then Dispose(E, Done) else Rules^.Insert(E);
      E:=New(PTwitRules, Init(Link, '', '', '', 'Twit.FromAddress', '', 'Twit.FromAddress.Actions', 'Twit.FromAddress.'));
      if E^.KillMySelf then Dispose(E, Done) else Rules^.Insert(E);
      E:=New(PTwitRules, Init(Link, '', '', '', '', 'Twit.ToAddress', 'Twit.ToAddress.Actions', 'Twit.ToAddress.'));
      if E^.KillMySelf then Dispose(E, Done) else Rules^.Insert(E);}
      cmCreateStrings(L);
      gProcessList(Link, 'Twit.Extended', L);
      for K:=1 to cmCount(L) do
       begin
        B:=bSearch(GetPString(cmAt(L, K)));
        if B <> Nil then
         begin
          E:=New(PTwitRules, Init(B, ''));
          if E^.KillMySelf then Dispose(E, Done) else Rules^.Insert(E);
         end;
       end;
      cmDisposeObject(L);
     end;
   end;
  cmCreateStrings(MsgData);
  C:=False;
  SrcFromAddress:=Msg^.iFromAddress;
  SrcToAddress:=Msg^.iToAddress;
  for K:=1 to Group^.Rules^.Count do
   begin
    R:=Group^.Rules^.At(K);
    if (cmCount(R^.ContainsKill) <> 0) and (not C) then
     begin
      for J:=1 to cmCount(Msg^.Data) do
       begin
        GetPStringEx(cmAt(Msg^.Data, J), D);
        StUpcaseEx(D);
        cmInsert(MsgData, cmNewStr(D));
       end;
      C:=True;
     end;
    if CheckLines(R^.ContainsKill, R^.ContainsRemain) and
       Check(msg^.iSubj, R^.SubjectsKill, R^.SubjectsRemain) and
       Check(msg^.iFrom, R^.FromNameKill, R^.FromNameRemain) and
       Check(msg^.iTo, R^.ToNameKill, R^.ToNameRemain) and
       Check(Address2Str(msg^.iFromAddress), R^.FromAddressKill, R^.FromAddressRemain) and
       Check(Address2Str(msg^.iToAddress), R^.ToAddressKill, R^.ToAddressRemain) then
        begin
         for M:=1 to cmCount(R^.Actions) do
          if ProcessAction(R, GetPString(cmAt(R^.Actions, M))) then Break;
         if not R^.ContinueLoop then Break;
        end;
   end;

  if Backup^.Count <> 0 then
   begin
    lngPrint('Main', 'twit.backup/restore.bug');
    Backup^.FreeAll;
   end;
  cmDisposeObject(MsgData);
 end;

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint; {$IFNDEF SOLID}export;{$ENDIF}
 var
  S: String;
 begin
  Service:=srYes;
  case ServiceNumber of
   snStartup: Service:=Startup;
   snStart: Start;
   snShutdown: Shutdown;
   snAfterStartup: AfterStartup;
   snQueryName: sSetSemaphore('Kernel.Plugins.Info.Name','TWiT');
   snQueryAuthor: sSetSemaphore('Kernel.Plugins.Info.Author','sergey korowkin');
   snQueryVersion: Service:=twitVersion;
   snQueryReqVer: Service:=kernelVersion;
   snsMessage: if TwitEnabled then Scan(Buffer);
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
