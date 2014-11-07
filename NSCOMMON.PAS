unit nsCommon;

interface

{$IFDEF VIRTUALPASCAL}
 {$DEFINE USEUNITS}
{$ENDIF}
{$IFDEF SOLID}
 {$DEFINE USEUNITS}
{$ENDIF}

uses
{$IFDEF USEUNITS}
     Misc, Semaphor, Plugins, Config, Video, Language,
{$ELSE}
     Decl,
{$ENDIF}
     Types, Wizard, Dos;

{$DEFINE SCAN_DECL}
{$I SCAN.INC}

const
 nsVersion              = $00010000;

 MaxIntervals           = 32;
 IntervalDivider        : TCharSet = [' ', ','];

type
 TInterval = record
  Start, Finish: Longint;
 end;

 PPeriod = ^TPeriod;
 TPeriod = object(TObject)
  Interval: Array[1..MaxIntervals] of TInterval;
  Intervals: Longint;
  constructor Init(const ASource: String);
  function Check(const ADate: Longint): Boolean;
  destructor Done; virtual;
 end;

 PGroup = ^TGroup;
 TGroup = object(TObject)
  Areas: PCollection;
  Group: PStrings;
  Scan: Boolean;
  Make: Boolean;
  Disabled: Boolean;
  CountTotal: Boolean;
  CountHour: Boolean;
  CountSubject: Boolean;
  CountFrom: Boolean;
  CountTo: Boolean;
  ScanPeriod: PPeriod;
  MakePeriod: PPeriod;
  constructor Init(const AGroup: PStrings);
  procedure Store(var S: TStream);
  destructor Done; virtual;
 end;

 TUnit = record
  Messages, Size: Longint;
 end;

 PArea = ^TArea;
 TArea = object(TObject)
  Tag: PString;
  Events: PCollection;
  constructor Init(const ATag: String);
  procedure Store(var S: TStream);
  destructor Done; virtual;
 end;

 { the parts of TEvent }

 THour = array[0..23] of TUnit;

 { TListItem - the part of TEvent }

 PListItem = ^TListItem;
 TListItem = object(TObject)
  Title: PString;
  Address: TAddress;
  Total: TUnit;
  constructor Init(const ATitle: String; const AAddress: TAddress);
  procedure Update;
  procedure Store(var S: TStream);
  destructor Done; virtual;
 end;

 { TList - the most serious part of TEvent }

 TList = object(TCollection)
  procedure DoInsert(const ATitle: String; const AAddress: TAddress);
  procedure Store(var S: TStream);
 end;

 PEvent = ^TEvent;
 TEvent = object(TObject)
  Date: Longint;
  constructor Init(const ADate: Longint);
  procedure Store(var S: TStream);
  destructor Done; virtual;
 public
  Total: TUnit;          { overall statistics }
  Hour: THour;           { statistics by hours [0..23] }
  Subject: TList;        { statistics by subjects }
  Sender: TList;         { statistics by senders }
  Receiver: TList;       { statistics by receivers }
 end;

const
 nsCollect              : Boolean = False;
 nsBase                 : String = '';

 Groups                 : PCollection = Nil;

 msg                    : PMessage = Nil;
 msgGroup               : PStrings = Nil;

 Group                  : PGroup = Nil;
 Area                   : PArea = Nil;
 Event                  : PEvent = Nil;

procedure ZeroUnit(var AUnit: TUnit);
procedure UpdateUnit(var AUnit: TUnit);

implementation

{$DEFINE SCAN_CODE}
{$I SCAN.INC}

{** misc code **}

procedure ZeroUnit(var AUnit: TUnit);
 begin
  AUnit.Messages:=0;
  AUnit.Size:=0;
 end;

procedure UpdateUnit(var AUnit: TUnit);
 begin
  Inc(AUnit.Messages);
  Inc(AUnit.Size, msg^.iSize);
 end;

{** TPeriod's code **}

constructor TPeriod.Init(const ASource: String);
 function ParseInterval(const Source: String; var A: Longint): Boolean;
  var
   DT: DateTime;
  begin
   if Length(Source) <> 10 then
    begin
     lngBegin;
      lngPush(Source);
      lngPrint('Main', 'ns.wrong.interval');
     lngEnd;
     ParseInterval:=False;
     Exit;
    end;
   Str2XWord(ExtractWord(1, Source, ['/']), DT.Day);
   Str2XWord(ExtractWord(2, Source, ['/']), DT.Month);
   Str2XWord(ExtractWord(3, Source, ['/']), DT.Year);
   DT.Hour:=0;
   DT.Min:=0;
   DT.Sec:=0;
   PackTime(DT, A);
   ParseInterval:=True;
  end;
 var
  K: Longint;
  S: String;
 begin
  inherited Init;

  for K:=1 to MaxIntervals do
   begin
    Interval[K].Start:=0;
    Interval[K].Finish:=0;
   end;

  Intervals:=0;
  for K:=1 to WordCount(ASource, IntervalDivider) do
   begin
    S:=ExtractWord(K, ASource, IntervalDivider);
    Inc(Intervals);
    if Pos('-', S) = 0 then
     if (not ParseInterval(S, Interval[Intervals].Start)) or (not ParseInterval(S, Interval[Intervals].Finish)) then
      Dec(Intervals)
     else
    else
     if (not ParseInterval(ExtractWord(1, S, ['-']), Interval[Intervals].Start)) or
        (not ParseInterval(ExtractWord(2, S, ['-']), Interval[Intervals].Finish)) then
      Dec(Intervals);
   end;
 end;

function TPeriod.Check(const ADate: Longint): Boolean;
 var
  K: Longint;
 begin
  for K:=1 to Intervals do
   if (ADate >= Interval[K].Start) and (ADate <= Interval[K].Finish) then
    begin
     Check:=True;
     Exit;
    end;
  Check:=False;
 end;

destructor TPeriod.Done;
 begin
  inherited Done;
 end;

{** TGroup's code **}

constructor TGroup.Init(const AGroup: PStrings);
 begin
  inherited Init;
  Group:=AGroup;

  Scan:=gGetBoolParam(Group, 'ns.scan');
  Make:=gGetBoolParam(Group, 'ns.make');
  Disabled:=gGetBoolParam(Group, 'ns.disabled') or ((not Scan) and (not Make));

  Areas:=New(PCollection, Init);

  ScanPeriod:=New(PPeriod, Init(gGetParam(Group, 'ns.scan.period')));
  MakePeriod:=New(PPeriod, Init(gGetParam(Group, 'ns.make.period')));

  CountTotal:=gGetBoolParam(Group, 'ns.count.total');
  CountHour:=gGetBoolParam(Group, 'ns.count.hour');
  CountSubject:=gGetBoolParam(Group, 'ns.count.subject');
  CountFrom:=gGetBoolParam(Group, 'ns.count.from');
  CountTo:=gGetBoolParam(Group, 'ns.count.to');

  if (not Disabled) then
   begin
    lngBegin;
     lngPush(gGetParam(Group, 'Name'));

     if Scan         then lngPush('+') else lngPush('-');
     if Make         then lngPush('+') else lngPush('-');
     if CountTotal   then lngPush('+') else lngPush('-');
     if CountHour    then lngPush('+') else lngPush('-');
     if CountSubject then lngPush('+') else lngPush('-');
     if CountFrom    then lngPush('+') else lngPush('-');
     if CountTo      then lngPush('+') else lngPush('-');

     lngPrint('Main', 'ns.group.startup');
    lngEnd;
   end;
 end;

procedure TGroup.Store(var S: TStream);
 var
  K: Longint;
 begin
  for K:=1 to Areas^.Count do
   PArea(Areas^.At(K))^.Store(S);
 end;

destructor TGroup.Done;
 begin
  Dispose(MakePeriod, Done);
  Dispose(ScanPeriod, Done);

  Dispose(Areas, Done);
  inherited Done;
 end;

{** TArea's code **}

constructor TArea.Init(const ATag: String);
 begin
  inherited Init;
  Tag:=NewStr(ATag);
  Events:=New(PCollection, Init);
 end;

procedure TArea.Store(var S: TStream);
 var
  K: Longint;
 begin
  S.Write(Tag^, Length(Tag^) + 1);
  S.Write(Events^.Count, SizeOf(Events^.Count));
  for K:=1 to Events^.Count do
   PEvent(Events^.At(K))^.Store(S);
 end;

destructor TArea.Done;
 begin
  Dispose(Events, Done);
  DisposeStr(Tag);
  inherited Done;
 end;

{** TListItem's code **}

constructor TListItem.Init(const ATitle: String; const AAddress: TAddress);
 begin
  inherited Init;
  Title:=NewStr(ATitle);
  Address:=AAddress;
  ZeroUnit(Total);
  UpdateUnit(Total);
 end;

procedure TListItem.Update;
 begin
  UpdateUnit(Total);
 end;

procedure TListItem.Store(var S: TStream);
 begin
  S.Write(Total, SizeOf(Total));
  S.Write(Title^, Length(Title^) + 1);
  S.Write(Address, SizeOf(Address));
 end;

destructor TListItem.Done;
 begin
  DisposeStr(Title);
  inherited Done;
 end;

{** TList's code **}

procedure TList.DoInsert(const ATitle: String; const AAddress: TAddress);
 var
  K: Longint;
  S: String;
 begin
  if ATitle = '' then Exit;

  S:=StUpcase(ATitle);

  for K:=1 to Count do
   if StUpcase(PListItem(At(K))^.Title^) = S then
    begin
     PListItem(At(K))^.Update;
     PListItem(At(K))^.Address:=AAddress;
     Exit;
    end;
  Insert(New(PListItem, Init(ATitle, AAddress)));
 end;

procedure TList.Store(var S: TStream);
 var
  K: Longint;
 begin
  S.Write(Count, SizeOf(Count));
  for K:=1 to Count do
   PListItem(At(K))^.Store(S);
 end;

{** TEvent's code **}

constructor TEvent.Init(const ADate: Longint);
 procedure ZeroStructure(var Structure: array of TUnit);
  var
   K: Longint;
  begin
   for K:=Low(Structure) to High(Structure) do
    ZeroUnit(Structure[K]);
  end;
 begin
  inherited Init;
  Date:=ADate;
  ZeroUnit(Total);

  ZeroStructure(Hour);

  Subject.Init;
  Sender.Init;
  Receiver.Init;
 end;

procedure TEvent.Store(var S: TStream);
 begin
  S.Write(Date, SizeOf(Date));
  S.Write(Total, SizeOf(Total));
  S.Write(Hour, SizeOf(Hour));
  Subject.Store(S);
  Sender.Store(S);
  Receiver.Store(S);
 end;

destructor TEvent.Done;
 begin
  Receiver.Done;
  Sender.Done;
  Subject.Done;

  inherited Done;
 end;

end.