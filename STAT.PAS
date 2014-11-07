{$IFDEF SOLID}
unit Stat;

interface

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint;

implementation
{$ELSE}
library Stat;
{$ENDIF}

{$IFDEF VIRTUALPASCAL}
uses Types, Consts_, Log, Video, Wizard, Misc, Language, Config, Semaphor,
     Plugins, Dos;
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
 statVersion = $00010200;
 _baseVersion: array[1..4] of char = 'Vera';
 statCollect: boolean = False;

var
 baseVersion: longint absolute _baseVersion;

type
 TItem = record
  messages: longint;
  size: longint;
 end;

 PStatItem = ^TStatItem;
 TStatItem = object(TObject)
 public
  name: PString;
  addr: TAddress;
  msgs: longint;
  size: longint;
  constructor Init(AName: String; AAddr: TAddress; AMsgs, ASize: Longint);
  constructor Load(var S: TStream);
  procedure Store(var S: TStream);
  destructor Done; virtual;
 end;

 PStatCollection = ^TStatCollection;
 TStatCollection = object(TCollection)
 public
  procedure Ins(Name: String; Addr: TAddress; Size: Longint);
  procedure Load(var S: TStream);
  procedure Store(var S: TStream);
 end;

 PData = ^TData;
 TData = object(TObject)
 public
  _subject: PStatCollection;
  _from: PStatCollection;
  _to: PStatCollection;
  _day: array[1..31] of TItem;
  _dow: array[1..7] of TItem;
  _hour: array[0..23] of TItem;
  _total: TItem;
  _area: PString;
  _base: PString;
  _output: PString;
  _start: TDate;
  _end: TDate;
  _block: PStrings;
  constructor Init(Area, Base, Output: String; pStart, pEnd: TDate);
  procedure Load(var S: TStream);
  procedure Store(var S: TStream);
  destructor Done; virtual;
 end;

var
 Datas: PCollection;

{$i scan.inc}
{$i common.inc}

constructor TStatItem.Init;
 begin
  inherited Init;
  Name:=NewStr(AName);
  Addr:=AAddr;
  Msgs:=AMsgs;
  Size:=ASize;
 end;

constructor TStatItem.Load;
 begin
  Name:=NewStr(S.ReadStr);
  S.Read(Addr, SizeOf(Addr));
  S.Read(Msgs, SizeOf(Msgs));
  S.Read(Size, SizeOf(Size));
 end;

procedure TStatItem.Store;
 begin
  S.WriteStr(GetPString(Name));
  S.Write(Addr, SizeOf(Addr));
  S.Write(Msgs, SizeOf(Msgs));
  S.Write(Size, SizeOf(Size));
 end;

destructor TStatItem.Done;
 begin
  DisposeStr(Name);
  inherited Done;
 end;

constructor TData.Init;
 begin
  inherited Init;
  _Area:=NewStr(Area);
  _Base:=NewStr(Base);
  _Output:=NewStr(Output);
  _Subject:=New(PStatCollection, Init);
  _From:=New(PStatCollection, Init);
  _To:=New(PStatCollection, Init);
  _Start:=pStart;
  _End:=pEnd;
  FillChar(_day, SizeOf(_day), 0);
  FillChar(_dow, SizeOf(_dow), 0);
  FillChar(_hour, SizeOf(_hour), 0);
  FillChar(_total, SizeOf(_total), 0);
 end;

procedure TData.Load;
 begin
  _Subject^.Load(S);
  _From^.Load(S);
  _To^.Load(S);
  S.Read(_day, SizeOf(_day));
  S.Read(_dow, SizeOf(_dow));
  S.Read(_hour, SizeOf(_hour));
  S.Read(_total, SizeOf(_total));
 end;

procedure TData.Store;
 begin
  _Subject^.Store(S);
  _From^.Store(S);
  _To^.Store(S);
  S.Write(_day, SizeOf(_day));
  S.Write(_dow, SizeOf(_dow));
  S.Write(_hour, SizeOf(_hour));
  S.Write(_total, SizeOf(_total));
 end;

destructor TData.Done;
 begin
  Dispose(_Subject, Done);
  Dispose(_From, Done);
  Dispose(_To, Done);
  DisposeStr(_Area);
  DisposeStr(_Base);
  DisposeStr(_Output);
  inherited Done;
 end;

procedure TStatCollection.Load(var S: TStream);
 var
  K, C: Longint;
 begin
  S.Read(C, SizeOf(C));
  for K:=1 to C do
   Insert(New(PStatItem, Load(S)));
 end;

procedure TStatCollection.Store(var S: TStream);
 var
  K: Longint;
 begin
  S.Write(Count, SizeOf(Count));
  for K:=1 to Count do
   PStatItem(At(K))^.Store(S);
 end;

procedure TStatCollection.Ins;
 var
  K: Longint;
  I: PStatItem;
  S1: String;
 begin
  I:=Nil;
  S1:=StUpcase(Name);
  for K:=1 to Count do
   if StUpcase(GetPString(PStatItem(At(K))^.Name))=S1 then
    begin
     Inc(PStatItem(At(K))^.Msgs);
     Inc(PStatItem(At(K))^.Size, Size);
     Exit;
    end;
  I:=New(PStatItem, Init(Name, Addr, 1, Size));
  Insert(I);
 end;

procedure LoadBlock(Name: String);
 var
  B: PStrings;
  D: PData;
  Area, Database, Output, Period, KeyWord: String;
  pStart: TDate;
  pEnd: TDate;
  S: TBufStream;
  ID: Longint;
 begin
  B:=bSearch(Name);
  if B=Nil then
   begin
    lngBegin;
    lngPush(Name);
    lngPrint('Main', 'stat.unknown.block');
    lngEnd;
    sSetExitNow;
    Exit;
   end;
  Area:=Trim(iGetParam(B, 'Area'));
  Database:=Trim(iGetParam(B, 'Database'));
  Output:=Trim(iGetParam(B, 'Statistics'));
  Period:=Trim(iGetParam(B, 'Period'));
  if Area='' then KeyWord:='Area' else
  if Database='' then KeyWord:='Database' else
  if Output='' then KeyWord:='Statistics' else
  if Period='' then KeyWord:='Period' else KeyWord:='';
  if KeyWord<>'' then
   begin
    lngBegin;
    lngPush(KeyWord);
    lngPrint('Main', 'stat.bad.keyword');
    lngEnd;
    sSetExitNow;
    Exit;
   end;
  ParseDate(ExtractWord(1, Period, [' ']), pStart);
  ParseDate(ExtractWord(2, Period, [' ']), pEnd);
  if (not ValidDate(pStart)) or (not ValidDate(pEnd)) then
   begin
    lngBegin;
    lngPush(Period);
    lngPrint('Main', 'stat.bad.period');
    lngEnd;
    sSetExitNow;
    Exit;
   end;
  Database:=FExpand(Database);
  D:=New(PData, Init(Area, Database, Output, pStart, pEnd));
  D^._block:=B;
  Datas^.Insert(D);
  mCreate(JustPathName(Database));
  S.Init(Database, stOpenRead, 2048);
  if S.Status<>stOk then
   begin
    lngBegin;
    lngPush(Database);
    lngPrint('Main', 'stat.db.created');
    lngEnd;
    S.Done;
    Exit;
   end;
  S.Read(ID, SizeOf(ID));
  if ID=baseVersion then
   D^.Load(S)
  else
   begin
    lngBegin;
    lngPush(Database);
    lngPrint('Main', 'stat.db.id');
    lngEnd;
    S.Done;
    Exit;
   end;
  S.Done;
  lngBegin;
  lngPush(Database);
  lngPrint('Main', 'stat.db.loaded');
  lngEnd;
 end;

procedure SaveData(D: PData);
 var
  S: TBufStream;
  FName: String;
 begin
  FName:=GetPString(D^._Base);
  S.Init(FName, stCreate, 2048);
  if S.Status<>stOk then
   begin
    lngBegin;
    lngPush(FName);
    lngPrint('Main', 'stat.db.error.creating');
    lngEnd;
    S.Done;
    sSetExitNow;
    Exit;
   end;
  S.Write(baseVersion, SizeOf(baseVersion));
  D^.Store(S);
  S.Done;
  lngBegin;
  lngPush(FName);
  lngPrint('Main', 'stat.db.saved');
  lngEnd;
 end;

procedure Startup;
 var
  Blocks: PStrings;
  K: Longint;
 begin
  Datas:=New(PCollection, Init);
  cmCreateStrings(Blocks);
  cProcessList('Stat.Define', Blocks);
  for K:=1 to cmCount(Blocks) do
   LoadBlock(GetPString(cmAt(Blocks, K)));
  cmDisposeObject(Blocks);
  statCollect:=cGetBoolParam('Stat.Collect');
 end;

procedure Shutdown;
 var
  K: Longint;
 begin
  for K:=1 to Datas^.Count do
   SaveData(Datas^.At(K));
  Dispose(Datas, Done);
 end;

procedure Statify(D: PData; Msg: PMessage);
 var
  Day, Month, Year, Hour, Min, Sec, Dow: XWord;
 procedure Update(var I: TItem);
  begin
   Inc(I.Messages);
   Inc(I.Size, Msg^.iSize);
  end;
 begin
  ParsePktDateTime(Msg^.iDate, Day, Month, Year, Hour, Min, Sec, Dow);
  if (Day<1) or (Day>31) or (Month<1) or (Month>12) or (Hour<0) or (Hour>23) or (Min<0) or (Min>59) or
     (Dow<0) or (Dow>6) then
      begin
       lngBegin;
       lngPush(Msg^.iDate);
       lngPrint('Main', 'stat.timestamp');
       lngEnd;
       Exit;
      end;
  if not InDate(D^._Start, D^._End, Day, Month, Year) then Exit;
  if Dow=0 then Dow:=7;
  D^._subject^.Ins(uCleanupSubj(Msg^.iSubj), Msg^.iFromAddress, Msg^.iSize);
  D^._from^.Ins(Msg^.iFrom, Msg^.iFromAddress, Msg^.iSize);
  D^._to^.Ins(Msg^.iTo, Msg^.iToAddress, Msg^.iSize);
  Update(D^._day[Day]);
  Update(D^._dow[Dow]);
  Update(D^._hour[Hour]);
  Update(D^._total);
 end;

procedure Scan(Msg: PMessage);
 var
  K: Longint;
  D: PData;
 begin
  for K:=1 to Datas^.Count do
   begin
    D:=Datas^.At(K);
    if mCheckWildCard(Msg^.iArea, D^._area^) then
     Statify(D, Msg);
   end;
 end;

var
 Macros: Pointer;
 Data: PData;
 Cache: PStrings;
 F: Text;

procedure ReInitMacros;
 begin
  umDestroyMacros(Macros);
  Macros:=umCreateMacros;
  umAddMacro(Macros, '@echo', GetPString(Data^._Area));
  umAddMacro(Macros, '@startdate', Date2Str(Data^._Start));
  umAddMacro(Macros, '@enddate', Date2Str(Data^._End));
  umAddMacro(Macros, '@totalmessages', Long2Str(Data^._Total.Messages));
  umAddMacro(Macros, '@totalsize', Long2Str(Data^._Total.Size));
  if Data^._Total.Messages=0 then
   umAddMacro(Macros, '@averagesize', '0')
  else
   umAddMacro(Macros, '@averagesize', Long2Str(Round(Data^._Total.Size/(Data^._Total.Messages+1))));
 end;

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
  iProcessList(Data^._block, Key, List);
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
  iProcessList(Data^._block, Key, Cache);
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

function GetNumValue(Key: String): longint;
 var
  K: Longint;
 begin
  K:=iGetNumParam(Data^._block, Key);
  if K=0 then K:=16383;
  GetNumValue:=K;
 end;

procedure AddMacro(ID, Data: String);
 begin
  umAddMacro(Macros, ID, Data);
 end;

function SortHandler_Msgs(C: PCollection; Key1, Key2: Longint): Longint; Far;
 var
  I1, I2: PStatItem;
  R: Longint;
 begin
  I1:=C^.At(Key1);
  I2:=C^.At(Key2);
  if (I1=Nil) and (I2<>Nil) then R:=1 else
  if (I1<>Nil) and (I2=Nil) then R:=-1 else
  if (I1=Nil) and (I2=Nil) then R:=0 else
  if I1^.Msgs>I2^.Msgs then R:=-1 else
  if I1^.Msgs<I2^.Msgs then R:=1 else
   if I1^.Size>I2^.Size then R:=-1 else
   if I1^.Size<I2^.Size then R:=1 else
    if GetPString(I1^.Name)<GetPString(I2^.Name) then R:=-1 else
    if GetPString(I1^.Name)>GetPString(I2^.Name) then R:=1 else
     R:=0;
  SortHandler_Msgs:=R;
 end;

function SortHandler_Size(C: PCollection; Key1, Key2: Longint): Longint; Far;
 var
  I1, I2: PStatItem;
  R: Longint;
 begin
  I1:=C^.At(Key1);
  I2:=C^.At(Key2);
  if (I1=Nil) and (I2<>Nil) then R:=1 else
  if (I1<>Nil) and (I2=Nil) then R:=-1 else
  if (I1=Nil) and (I2=Nil) then R:=0 else
  if I1^.Size>I2^.Size then R:=-1 else
  if I1^.Size<I2^.Size then R:=1 else
   if I1^.Msgs>I2^.Msgs then R:=-1 else
   if I1^.Msgs<I2^.Msgs then R:=1 else
    if GetPString(I1^.Name)<GetPString(I2^.Name) then R:=-1 else
    if GetPString(I1^.Name)>GetPString(I2^.Name) then R:=1 else
     R:=0;
  SortHandler_Size:=R;
 end;

procedure Build(D: PData);
 function Init: boolean;
  var
   S: String;
  begin
   Macros:=umCreateMacros;
   Data:=D;
   cmCreateStrings(Cache);
   S:=FExpand(Trim(iGetParam(D^._block, 'Statistics')));
   mCreate(JustPathName(S));
   {$i-}
   InOutRes:=0;
   Assign(F, S);
   Rewrite(F);
   if InOutRes<>0 then
    begin
     lngBegin;
     lngPush(S);
     lngPrint('Main', 'stat.error.creating');
     lngEnd;
     Init:=False;
     Exit;
    end;
   Init:=True;
  end;
 procedure Header;
  begin
   ReInitMacros; ProcessStrings('Header');
  end;
 procedure Overall;
  begin
   ReInitMacros; ProcessStrings('Overall');
  end;
 procedure SendersMsgs;
  var
   K: Longint;
   S: PStatItem;
  begin
   ReInitMacros; ProcessStrings('Senders.Msgs.Header');
   Data^._From^.Sort(SortHandler_Msgs);
   CacheStrings('Senders.Msgs.Center');
   ReInitMacros;
    for K:=1 to GetNumValue('Senders.Msgs.Count') do
     begin
      S:=Data^._From^.At(K);
      if S=Nil then Break;
      AddMacro('@no', Long2Str(K));
      AddMacro('@name', GetPString(S^.Name));
      AddMacro('@address', Address2Str(S^.Addr));
      AddMacro('@msgs', Long2Str(S^.Msgs));
      AddMacro('@size', Long2Str(S^.Size));
      ProcessCachedStrings;
     end;
   ReInitMacros; ProcessStrings('Senders.Msgs.Footer');
  end;
 procedure SendersSize;
  var
   K: Longint;
   S: PStatItem;
  begin
   ReInitMacros; ProcessStrings('Senders.Size.Header');
   Data^._From^.Sort(SortHandler_Size);
   CacheStrings('Senders.Size.Center');
   ReInitMacros;
    for K:=1 to GetNumValue('Senders.Size.Count') do
     begin
      S:=Data^._From^.At(K);
      if S=Nil then Break;
      AddMacro('@no', Long2Str(K));
      AddMacro('@name', GetPString(S^.Name));
      AddMacro('@address', Address2Str(S^.Addr));
      AddMacro('@msgs', Long2Str(S^.Msgs));
      AddMacro('@size', Long2Str(S^.Size));
      ProcessCachedStrings;
     end;
   ReInitMacros; ProcessStrings('Senders.Size.Footer');
  end;
 procedure ReceiversMsgs;
  var
   K: Longint;
   S: PStatItem;
  begin
   ReInitMacros; ProcessStrings('Receivers.Msgs.Header');
   Data^._To^.Sort(SortHandler_Msgs);
   CacheStrings('Receivers.Msgs.Center');
   ReInitMacros;
    for K:=1 to GetNumValue('Receivers.Msgs.Count') do
     begin
      S:=Data^._To^.At(K);
      if S=Nil then Break;
      AddMacro('@no', Long2Str(K));
      AddMacro('@name', GetPString(S^.Name));
      AddMacro('@address', Address2Str(S^.Addr));
      AddMacro('@msgs', Long2Str(S^.Msgs));
      AddMacro('@size', Long2Str(S^.Size));
      ProcessCachedStrings;
     end;
   ReInitMacros; ProcessStrings('Receivers.Msgs.Footer');
  end;
 procedure ReceiversSize;
  var
   K: Longint;
   S: PStatItem;
  begin
   ReInitMacros; ProcessStrings('Receivers.Size.Header');
   Data^._To^.Sort(SortHandler_Size);
   CacheStrings('Receivers.Size.Center');
   ReInitMacros;
    for K:=1 to GetNumValue('Receivers.Size.Count') do
     begin
      S:=Data^._To^.At(K);
      if S=Nil then Break;
      AddMacro('@no', Long2Str(K));
      AddMacro('@name', GetPString(S^.Name));
      AddMacro('@address', Address2Str(S^.Addr));
      AddMacro('@msgs', Long2Str(S^.Msgs));
      AddMacro('@size', Long2Str(S^.Size));
      ProcessCachedStrings;
     end;
   ReInitMacros; ProcessStrings('Receivers.Size.Footer');
  end;
 procedure SubjsMsgs;
  var
   K: Longint;
   S: PStatItem;
  begin
   ReInitMacros; ProcessStrings('Subjs.Msgs.Header');
   Data^._Subject^.Sort(SortHandler_Msgs);
   CacheStrings('Subjs.Msgs.Center');
   ReInitMacros;
    for K:=1 to GetNumValue('Subjs.Msgs.Count') do
     begin
      S:=Data^._Subject^.At(K);
      if S=Nil then Break;
      AddMacro('@no', Long2Str(K));
      AddMacro('@subj', GetPString(S^.Name));
      AddMacro('@msgs', Long2Str(S^.Msgs));
      AddMacro('@size', Long2Str(S^.Size));
      ProcessCachedStrings;
     end;
   ReInitMacros; ProcessStrings('Subjs.Msgs.Footer');
  end;
 procedure SubjsSize;
  var
   K: Longint;
   S: PStatItem;
  begin
   ReInitMacros; ProcessStrings('Subjs.Size.Header');
   Data^._Subject^.Sort(SortHandler_Size);
   CacheStrings('Subjs.Size.Center');
   ReInitMacros;
    for K:=1 to GetNumValue('Subjs.Size.Count') do
     begin
      S:=Data^._Subject^.At(K);
      if S=Nil then Break;
      AddMacro('@no', Long2Str(K));
      AddMacro('@subj', GetPString(S^.Name));
      AddMacro('@msgs', Long2Str(S^.Msgs));
      AddMacro('@size', Long2Str(S^.Size));
      ProcessCachedStrings;
     end;
   ReInitMacros; ProcessStrings('Subjs.Size.Footer');
  end;
 procedure DowMsgs;
  var
   K, M: Longint;
  begin
   ReInitMacros;
   AddMacro('@size', Long2Str(D^._total.size));
   AddMacro('@msgs', Long2Str(D^._total.messages));
   M:=0;
   for K:=1 to 7 do
    if D^._dow[K].size > M then M:=D^._dow[K].size;
   AddMacro('@maxsize', Long2Str(M));
   M:=0;
   for K:=1 to 7 do
    if D^._dow[K].messages > M then M:=D^._dow[K].messages;
   AddMacro('@maxmsgs', Long2Str(M));
   for K:=1 to 7 do
    begin
     AddMacro('@d'+Long2Str(K)+'msgs', Long2Str(D^._dow[K].messages));
     AddMacro('@d'+Long2Str(K)+'size', Long2Str(D^._dow[K].size));
    end;
   ProcessStrings('Dow.Msgs');
  end;
 procedure DowSize;
  var
   K, M: Longint;
  begin
   ReInitMacros;
   AddMacro('@size', Long2Str(D^._total.size));
   AddMacro('@msgs', Long2Str(D^._total.messages));
   M:=0;
   for K:=1 to 7 do
    if D^._dow[K].size > M then M:=D^._dow[K].size;
   AddMacro('@maxsize', Long2Str(M));
   M:=0;
   for K:=1 to 7 do
    if D^._dow[K].messages > M then M:=D^._dow[K].messages;
   AddMacro('@maxmsgs', Long2Str(M));
   for K:=1 to 7 do
    begin
     AddMacro('@d'+Long2Str(K)+'msgs', Long2Str(D^._dow[K].messages));
     AddMacro('@d'+Long2Str(K)+'size', Long2Str(D^._dow[K].size));
    end;
   ProcessStrings('Dow.Size');
  end;
 procedure DayMsgs;
  var
   I: ^TItem;
   K, M: Longint;
  begin
   ReInitMacros; ProcessStrings('Day.Msgs.Header');
   ReInitMacros; CacheStrings('Day.Msgs.Center');
   M:=0;
   for K:=1 to 31 do
    if D^._day[K].size > M then M:=D^._day[K].size;
   AddMacro('@maxsize', Long2Str(M));
   M:=0;
   for K:=1 to 31 do
    if D^._day[K].messages > M then M:=D^._day[K].messages;
   AddMacro('@maxmsgs', Long2Str(M));
   for K:=1 to 31 do
    begin
     I:=@D^._day[K];
     AddMacro('@msgs', Long2Str(D^._total.Messages));
     AddMacro('@size', Long2Str(D^._total.Size));
     AddMacro('@daymsgs', Long2Str(I^.Messages));
     AddMacro('@daysize', Long2Str(I^.Size));
     AddMacro('@day', Long2Str(K));
     ProcessCachedStrings;
    end;
   ReInitMacros; ProcessStrings('Day.Msgs.Footer');
  end;
 procedure DaySize;
  var
   I: ^TItem;
   K, M: Longint;
  begin
   ReInitMacros; ProcessStrings('Day.Size.Header');
   ReInitMacros; CacheStrings('Day.Size.Center');
   M:=0;
   for K:=1 to 31 do
    if D^._day[K].size > M then M:=D^._day[K].size;
   AddMacro('@maxsize', Long2Str(M));
   M:=0;
   for K:=1 to 31 do
    if D^._day[K].messages > M then M:=D^._day[K].messages;
   AddMacro('@maxmsgs', Long2Str(M));
   for K:=1 to 31 do
    begin
     I:=@D^._day[K];
     AddMacro('@msgs', Long2Str(D^._total.Messages));
     AddMacro('@size', Long2Str(D^._total.Size));
     AddMacro('@daymsgs', Long2Str(I^.Messages));
     AddMacro('@daysize', Long2Str(I^.Size));
     AddMacro('@day', Long2Str(K));
     ProcessCachedStrings;
    end;
   ReInitMacros; ProcessStrings('Day.Size.Footer');
  end;
 procedure HourMsgs;
  var
   I: ^TItem;
   K, M: Longint;
  begin
   ReInitMacros; ProcessStrings('Hour.Msgs.Header');
   ReInitMacros; CacheStrings('Hour.Msgs.Center');
   M:=0;
   for K:=0 to 23 do
    if D^._hour[K].size > M then M:=D^._hour[K].size;
   AddMacro('@maxsize', Long2Str(M));
   M:=0;
   for K:=0 to 23 do
    if D^._hour[K].messages > M then M:=D^._hour[K].messages;
   AddMacro('@maxmsgs', Long2Str(M));
   for K:=0 to 23 do
    begin
     I:=@D^._hour[K];
     AddMacro('@msgs', Long2Str(D^._total.Messages));
     AddMacro('@size', Long2Str(D^._total.Size));
     AddMacro('@hourmsgs', Long2Str(I^.Messages));
     AddMacro('@hoursize', Long2Str(I^.Size));
     AddMacro('@hour', Long2Str(K));
     ProcessCachedStrings;
    end;
   ReInitMacros; ProcessStrings('Hour.Msgs.Footer');
  end;
 procedure HourSize;
  var
   I: ^TItem;
   K, M: Longint;
  begin
   ReInitMacros; ProcessStrings('Hour.Size.Header');
   ReInitMacros; CacheStrings('Hour.Size.Center');
   M:=0;
   for K:=0 to 23 do
    if D^._hour[K].size > M then M:=D^._hour[K].size;
   AddMacro('@maxsize', Long2Str(M));
   M:=0;
   for K:=0 to 23 do
    if D^._hour[K].messages > M then M:=D^._hour[K].messages;
   AddMacro('@maxmsgs', Long2Str(M));
   for K:=0 to 23 do
    begin
     I:=@D^._hour[K];
     AddMacro('@msgs', Long2Str(D^._total.Messages));
     AddMacro('@size', Long2Str(D^._total.Size));
     AddMacro('@hourmsgs', Long2Str(I^.Messages));
     AddMacro('@hoursize', Long2Str(I^.Size));
     AddMacro('@hour', Long2Str(K));
     ProcessCachedStrings;
    end;
   ReInitMacros; ProcessStrings('Hour.Size.Footer');
  end;
 procedure Footer;
  begin
   ReInitMacros; ProcessStrings('Footer');
  end;
 procedure Done;
  begin
   umDestroyMacros(Macros);
   cmDisposeObject(Cache);
   Close(F);
  end;
 var
  S: String;
  K: Byte;
 begin
  if D=Nil then Exit;
  if not Init then Exit;
  S:=Trim(StUpcase(iGetParam(D^._block, 'Order')));
  lngBegin;
  lngPush(GetPString(D^._area));
  lngPrint('Main', 'stat.start');
  lngEnd;
  for K:=1 to Length(S) do
   begin
    case S[K] of
     '1': Header;
     '2': Overall;
     '3': SendersMsgs;
     '4': SendersSize;
     '5': ReceiversMsgs;
     '6': ReceiversSize;
     '7': SubjsMsgs;
     '8': SubjsSize;
     '9': DowMsgs;
     'A': DowSize;
     'B': DayMsgs;
     'C': DaySize;
     'D': HourMsgs;
     'E': HourSize;
     'F': Footer;
    else
     lngBegin;
     lngPush(S[K]);
     lngPrint('Main', 'stat.dot.error');
     lngEnd;
     continue;
    end;
    lngBegin;
    lngPush(S[K]);
    lngPrint('Main', 'stat.dot');
    lngEnd;
   end;
  lngPrint('Main', 'stat.end');
  Done;
 end;

procedure Start;
 var
  K: Longint;
 begin
  if sExitNow then Exit;
  if not cGetBoolParam('Stat.Make') then EXit;
  for K:=1 to Datas^.Count do
   begin
    mCheckBreak;
    if sExitNow then Break;
    Build(Datas^.At(K));
   end;
 end;

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint; {$IFNDEF SOLID}export;{$ENDIF}
 begin
  Service:=srYes;
  case ServiceNumber of
   snAfterStartup:
    begin
     mCheckPlugin('STAT', 'USER');
    end;
   snStartup: Startup;
   snShutdown: Shutdown;
   snStart: Start;
   snQueryName: sSetSemaphore('Kernel.Plugins.Info.Name','STATISTIX');
   snQueryAuthor: sSetSemaphore('Kernel.Plugins.Info.Author','sergey korowkin');
   snQueryVersion: Service:=statVersion;
   snQueryReqVer: Service:=kernelVersion;
   snsMessage:
    if statCollect then Scan(Buffer);
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
