unit Semaphor;

interface

procedure sInit; {$IFNDEF SOLID}export;{$ENDIF}
procedure sDone; {$IFNDEF SOLID}export;{$ENDIF}

procedure sSetSemaphore(Name, Value: String); {$IFNDEF SOLID}export;{$ENDIF}
function sGetSemaphore(Name: String): String; {$IFNDEF SOLID}export;{$ENDIF}
function sGetBoolSemaphore(Name: String): Boolean; {$IFNDEF SOLID}export;{$ENDIF}
function sGetNumSemaphore(Name: String): Longint; {$IFNDEF SOLID}export;{$ENDIF}
function sGetPtrSemaphore(Name: String): Pointer; {$IFNDEF SOLID}export;{$ENDIF}
function sExitNow: Boolean; {$IFNDEF SOLID}export;{$ENDIF}
procedure sSetExitNow; {$IFNDEF SOLID}export;{$ENDIF}

implementation
uses Types, Log, Config, Wizard;

{$I fastuue.inc}

var
 Semaphores: PCollection;
 ExitNow: Boolean;
 DebugSemaphores: Boolean;

type
 PSemaphore = ^TSemaphore;
 TSemaphore = object(TObject)
  Name: PString;
  Value: PString;
  constructor Init(const AName, AValue: String);
  destructor Done; virtual;
 end;

constructor TSemaphore.Init;
 begin
  inherited Init;
  Name:=NewStr(AName);
  Value:=NewStr(AValue);
 end;

destructor TSemaphore.Done;
 begin
  DisposeStr(Name);
  DisposeStr(Value);
  inherited Done;
 end;

procedure sDebug(S: String);
 begin
  logWrite('Main', 'sDebug: ' + S);
 end;

procedure sInit;
 begin
  Semaphores:=New(PCollection, Init);

  ExitNow:=False;

  DebugSemaphores:=cGetBoolParam('Debug.Semaphores');
 end;

function SeekSemaphore(var Name: String): PSemaphore;
 var
  K: Longint;
  S: PSemaphore;
 begin
  for K:=1 to Semaphores^.Count do
   begin
    S:=Semaphores^.At(K);
    if S^.Name^ = Name then
     begin
      SeekSemaphore:=S;
      Exit;
     end;
   end;
  SeekSemaphore:=Nil;
 end;

procedure sSetSemaphore(Name, Value: String);
 var
  S: PSemaphore;
 var
  K: Longint;
 begin
  StUpcaseEx(Name);
  S:=SeekSemaphore(Name);
  if S = Nil then
   begin
    S:=New(PSemaphore, Init(Name, Value));
    Semaphores^.Insert(S);
    if DebugSemaphores then
     sDebug('Created ''' + Name + ''', value ''' + Value + '''');
   end
  else
   begin
    if DebugSemaphores then
     sDebug('Changed ''' + Name + ''', value ''' + Value + '''');
    DisposeStr(S^.Value);
    S^.Value:=NewStr(Value);
   end;
 end;

function sGetSemaphore(Name: String): String;
 var
  S: PSemaphore;
 begin
  if Semaphores = Nil then
   begin
    sGetSemaphore:='';
    Exit;
   end;
  StUpcaseEx(Name);
  S:=SeekSemaphore(Name);
  if S = Nil then
   begin
    sGetSemaphore:='';
    if DebugSemaphores then
     sDebug('NULL ''' + Name + '''');
   end
  else
   begin
    if S^.Value = Nil then
     sGetSemaphore:=''
    else
     sGetSemaphore:=S^.Value^;
    if DebugSemaphores then
     sDebug('Get ''' + Name + ''', value ''' + GetPString(S^.Value) + '''');
   end;
 end;

function sGetBoolSemaphore(Name: String): Boolean;
 begin
  Name:=sGetSemaphore(Name);
  TrimEx(Name);
  StUpcaseEx(Name);
  sGetBoolSemaphore:=(Name[0] <> #0) and (Name[1] in ['1','Y']);
 end;

function sGetNumSemaphore(Name: String): Longint;
 var
  A: Longint;
 begin
  Name:=sGetSemaphore(Name);
  TrimEx(Name);
  StUpcaseEx(Name);
  Str2Longint(Name, A);
  sGetNumSemaphore:=A;
 end;

function sGetPtrSemaphore(Name: String): Pointer;
 var
  P: Pointer;
  D: record s, o: word; end absolute P;
 begin
  Name:=sGetSemaphore(Name);
  Str2Word('$'+Copy(Name,1,4), D.S);
  Str2Word('$'+Copy(Name,6,4), D.O);
  sGetPtrSemaphore:=P;
 end;

procedure sDone;
 begin
  if Semaphores <> nil then
   Dispose(Semaphores, Done);
 end;

function sExitNow: boolean;
 begin
  sExitNow:=ExitNow;
 end;

procedure sSetExitNow;
 begin
  if DebugSemaphores then sDebug('ExitNow ON');
  ExitNow:=True;
 end;

end.
