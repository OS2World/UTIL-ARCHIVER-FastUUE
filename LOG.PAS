{$I-}
unit Log;

interface

procedure logInit;
procedure logDone;

procedure logCreate(Name, FName: String); {$IFNDEF SOLID}export;{$ENDIF}
procedure logWrite(Name, S: String); {$IFNDEF SOLID}export;{$ENDIF}
procedure logKill(Name: String); {$IFNDEF SOLID}export;{$ENDIF}

procedure _ssGetLogs(Proc: Pointer);
procedure _ssChangeLogStatus(S: Pointer; Open: Boolean);

implementation
{$IfDef DPMI}  uses Misc, Types, Dos, Wizard, Config; {$EndIF}
{$IfDef OS2}   uses Misc, Types, Dos, Wizard, Use32, Config; {$EndIF}
{$IfDef Win32} uses Misc, Types, Dos, Wizard, Config; {$EndIF}

{$I fastuue.inc}

var
 Logs: PCollection;
 DebugLog: Boolean;
const
 Working: Boolean = False;

type
 PLog = ^TLog;
 TLog = object(TObject)
 public
  Name: String;
  FName: String;
  Link: Text;
  Opened: Boolean;
  destructor Done; virtual;
 end;

destructor TLog.Done;
 begin
  if Opened then Close(Link);
  inherited Done;
 end;

procedure logInit;
 begin
  Logs:=New(PCollection, Init);
  DebugLog:=cGetBoolParam('Log.Flush');
 end;

procedure logCreate(Name, FName: String);
 var
  Log: PLog;
 procedure CheckLog(L: PLog); far;
  begin
   if Name=L^.Name then Log:=L;
  end;
 var
  K: Longint;
 begin
  if FName='' then Exit;
  TrimEx(Name);
  StUpcaseEx(Name);
  Log:=Nil;
  for K:=1 to Logs^.Count do CheckLog(Logs^.At(K));
  if Log<>Nil then Exit;
  Log:=New(PLog, Init);
  Log^.Name:=Name;
  Log^.FName:=FName;
  Log^.Opened:=False;
  Logs^.Insert(Log);
 end;

procedure logKill(Name: String);
 var
  Log: PLog;
 procedure CheckLog(L: PLog); far;
  begin
   if Name = L^.Name then Log:=L;
  end;
 var
  K: Longint;
 begin
  TrimEx(Name);
  StUpcaseEx(Name);
  Log:=Nil;
  for K:=1 to Logs^.Count do CheckLog(Logs^.At(K));
  if Log=Nil then Exit;
  if Log^.Opened then Close(Log^.Link);
  Logs^.Free(Log);
 end;

procedure logWrite(Name, S: String);
 const
  Dows: array[0..6] of string[15] = ('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday');
  Months: array[1..12] of string[15] = ('January','February','March','April','May','June','July','August','September',
   'October','November','December');
 var
  Log: PLog;
  {$IFDEF VIRTUALPASCAL}
  D,M,Y,Dow: Longint;
  Hour,Min,Sec,Sec1: Longint;
  {$ELSE}
  D,M,Y,Dow: Word;
  Hour,Min,Sec,Sec1: Word;
  {$ENDIF}
 procedure CheckLog(L: PLog); far;
  begin
   if Name = L^.Name then Log:=L;
  end;
 var
  K: Longint;
 begin
  if Working then Exit;
  Working:=True;
  GetTime(Hour, Min, Sec, Dow);
  GetDate(Y, M, D, Dow);
  if Logs=Nil then Exit;
  TrimEx(Name);
  StUpcaseEx(Name);
  Log:=Nil;
  for K:=1 to Logs^.Count do CheckLog(Logs^.At(K));
  if Log = Nil then Exit;
  if not Log^.Opened then
   begin
    mCreate(JustPathName(Log^.FName));
    InOutRes:=0;
    Assign(Log^.Link, Log^.FName);
    Append(Log^.Link);
    if IOResult<>0 then ReWrite(Log^.Link);
    if IOResult<>0 then Exit;
    System.WriteLn(Log^.Link,'');
    System.WriteLn(Log^.Link,'');
    System.WriteLn(Log^.Link,'컴컴컴컴컴컴컴컴컴컴 ',D,' ',Months[M],' ',Y,', ',Dows[Dow]);
    Log^.Opened:=True;
   end;
  InOutRes:=0;
  S:=LeftPadCh(Long2Str(Hour),'0',2)+':'+LeftPadCh(Long2Str(Min),'0',2)+':'+LeftPadCh(Long2Str(Sec),'0',2)+' '+S;
  System.WriteLn(Log^.Link,S);
  InOutRes:=0;
  if DebugLog then System.Flush(Log^.Link);
  Working:=False;
 end;

procedure logDone;
 begin
  if Logs <> Nil then Dispose(Logs, Done);
 end;

function logGet(Name: String): PLog;
 procedure CheckLog(L: PLog); far;
  begin
   if Name=L^.Name then logGet:=L;
  end;
 var
  K: Longint;
 begin
  TrimEx(Name);
  StUpcaseEx(Name);
  logGet:=Nil;
  for K:=1 to Logs^.Count do
   CheckLog(Logs^.At(K));
 end;

{$i secret.inc}

procedure _ssGetLogs(Proc: Pointer);
 var
  P: TGetLogsProc;
  K: Longint;
 begin
  @P:=Proc;
  for K:=1 to Logs^.Count do
   with PLog(Logs^.At(K))^ do
    P(Name, FName);
 end;

procedure _ssChangeLogStatus(S: Pointer; Open: Boolean);
 var
  L: PLog;
 begin
  if S=Nil then Exit;
  L:=logGet(GetPString(S));
  if L=Nil then Exit;
  if Open then
   begin
    if L^.Opened then Exit;
    mCreate(JustPathName(L^.FName));
    InOutRes:=0;
    Assign(L^.Link, L^.FName);
    Append(L^.Link);
    if IOResult <> 0 then ReWrite(L^.Link);
    if IOResult <> 0 then Exit;
    L^.Opened:=True;
   end
  else
   begin
    if not L^.Opened then Exit;
    Close(L^.Link);
    L^.Opened:=False;
   end;
 end;

end.