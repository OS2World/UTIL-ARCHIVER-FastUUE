unit nsScan;

interface

{$IFDEF VIRTUALPASCAL}
 {$DEFINE USEUNITS}
{$ENDIF}
{$IFDEF SOLID}
 {$DEFINE USEUNITS}
{$ENDIF}

uses
{$IFDEF USEUNITS}
     Misc, Semaphor, Plugins, Video, Language,
{$ELSE}
     Decl,
{$ENDIF}
     nsCommon,
     Types, Wizard, Dos;

procedure nsMessage;

implementation

{$I SCAN.INC}

var
 TempSubject: String;

procedure nsMessage;
 var
  K, Date: Longint;
  DT: DateTime;
  Dow: XWord;
 begin
  ParsePktDateTime(msg^.iDate, DT.Day, DT.Month, DT.Year, DT.Hour, DT.Min, DT.Sec, Dow);

  if (DT.Day < 1) or (DT.Day > 31) or
     (DT.Month < 1) or (DT.Month > 12) or
     (DT.Hour < 0) or (DT.Hour > 23) or
     (DT.Min < 0) or (DT.Min > 59) or
     (Dow < 0) or (Dow > 6) then
      begin
       lngBegin;
        lngPush(msg^.iDate);
        lngPrint('Main', 'ns.wrong.timestamp');
       lngEnd;

       Exit;
      end;

  PackTime(DT, Date);

  msgGroup:=msg^.Group;

  if msgGroup = Nil then
   begin
    lngBegin;
     lngPush(msg^.iArea);
     lngPrint('Main', 'stuff.unknown.group');
    lngEnd;

    Exit;
   end;

  if (msg^.iArea = 'NETMAIL') or (msg^.iArea = '') then
   Exit;

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

  if Group^.Disabled or (not Group^.Scan) then
   Exit;

  Area:=Nil;

  for K:=1 to Group^.Areas^.Count do
   if PArea(Group^.Areas^.At(K))^.Tag^ = msg^.iArea then
    begin
     Area:=Group^.Areas^.At(K);

     Break;
    end;

  if Area = Nil then
   begin
    Area:=New(PArea, Init(msg^.iArea));

    Group^.Areas^.Insert(Area);
   end;

  if not Group^.ScanPeriod^.Check(Date) then
   Exit;

  DT.Hour:=0;
  DT.Min:=0;
  DT.Sec:=0;

  PackTime(DT, Date);

  Event:=Nil;

  for K:=1 to Area^.Events^.Count do
   if PEvent(Area^.Events^.At(K))^.Date = Date then
    begin
     Event:=Area^.Events^.At(K);

     Break;
    end;

  if Event = Nil then
   begin
    Event:=New(PEvent, Init(Date));

    Area^.Events^.Insert(Event);
   end;

  if Group^.CountTotal then
   UpdateUnit(Event^.Total);

  if Group^.CountHour then
   UpdateUnit(Event^.Hour[DT.Hour]);

  if Group^.CountSubject then
   begin
    TempSubject:=msg^.iSubj;
    if (TempSubject[0] > #1) and (TempSubject[1] = 'R') and (TempSubject[2] = 'e') then
     begin
      K:=Pos(':', TempSubject);

      if (K > 0) and (K < 7) then
       begin
        Delete(TempSubject, 1, K);

        if (TempSubject[0] <> #0) and (TempSubject[1] = ' ') then
         Delete(TempSubject, 1, 1);
       end;
     end;

    ReplaceChar(TempSubject, #224, #112);
    ReplaceChar(TempSubject, #227, #121);

    Event^.Subject.DoInsert(TempSubject, msg^.iFromAddress);
   end;

  if Group^.CountFrom then
   Event^.Sender.DoInsert(msg^.iFrom, msg^.iFromAddress);

  if Group^.CountTo then
   Event^.Receiver.DoInsert(msg^.iTo, msg^.iToAddress);
 end;

end.