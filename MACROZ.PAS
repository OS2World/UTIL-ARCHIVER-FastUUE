unit Macroz;

{
 FastUUE Macros Engine
 version 1.1

 1.1
  + @length macro

 (c) by Sergey Korowkin, 1998.
}

interface
uses
     Wizard;

const
 mcSystem     = 1;
 mcUser       = 2;

type
 PMacros = ^TMacros;
 TMacroFunction = procedure(M: PMacros; const Line: String);

 PString = ^String;

 PMacro = ^TMacro;
 TMacro = object
 public
  ID, Data: PString;
  ClassID: Byte;
  IsFunc: Boolean;
  Func: TMacroFunction;
  constructor Init(AID: String; const AData: String; AClassID: Byte; AIsFunc: Boolean; AFunc: TMacroFunction);
  destructor Done; virtual;
 end;

 TMacros = object
 public
  EmptyLine: Boolean;

  constructor Init;
  procedure   AddMacro(const ID, Data: String; ClassID: Byte); virtual;
  procedure   AddFunction(const ID: String; Func: TMacroFunction; ClassID: Byte); virtual;
  function    GetMacro(ID: String): PMacro; virtual;
  function    GetMacroAndClass(ID: String; ClassID: Byte): PMacro; virtual;
  procedure   SetMacroData(M: PMacro; const NewData: String); virtual;
  procedure   RemoveMacro(const ID: String); virtual;
  function    Process(S: String): String; virtual;
  function    MacroProcess(const S: String): String; virtual;

  procedure   AddAdditionalMacros; virtual;

  procedure   ContainerInit; virtual;
  function    ContainerSize: Longint; virtual;
  function    ContainerAt(Index: Longint): PMacro; virtual;
  procedure   ContainerInsert(Macro: PMacro); virtual;
  procedure   ContainerFree(Macro: PMacro); virtual;
  procedure   ContainerDone; virtual;

  procedure   Abstract;

  destructor  Done; virtual;
 end;

implementation

(* Default macros *)
{$IFNDEF VIRTUALPASCAL}
{$F+}
{$ENDIF}
procedure mcAssign(M: PMacros; const Line: String);
 begin
  M^.AddMacro(ExtractWord(2, Line, [' ']), GetAllAfterSpace(Line, 2), mcUser);
 end;

procedure mcAddF(M: PMacros; const Line: String);
 var
  S: String;
  A: PMacro;
 begin
  A:=M^.GetMacroAndClass(ExtractWord(2, Line, [' ']), mcUser);
  if A = Nil then Exit;
  M^.SetMacroData(A, GetPString(A^.Data) + GetAllAfterSpace(Line, 2));
 end;

procedure mcAddB(M: PMacros; const Line: String);
 var
  S: String;
  A: PMacro;
 begin
  A:=M^.GetMacroAndClass(ExtractWord(2, Line, [' ']), mcUser);
  if A = Nil then Exit;
  S:=GetPString(A^.Data);
  M^.SetMacroData(A, GetAllAfterSpace(Line, 2) + GetPString(A^.Data));
 end;

procedure mcPad(M: PMacros; const Line: String);
 var
  Count: Longint;
  A: PMacro;
 begin
  A:=M^.GetMacroAndClass(ExtractWord(2, Line, [' ']), mcUser);
  if A = Nil then Exit;
  Str2Longint(M^.MacroProcess(ExtractWord(3, Line, [' '])), Count);
  M^.SetMacroData(A, Pad(Copy(M^.MacroProcess(GetPString(A^.Data)), 1, Count), Count));
 end;

procedure mcLPad(M: PMacros; const Line: String);
 var
  Count: Longint;
  A: PMacro;
 begin
  A:=M^.GetMacroAndClass(ExtractWord(2, Line, [' ']), mcUser);
  if A = Nil then Exit;
  Str2Longint(M^.MacroProcess(ExtractWord(3, Line, [' '])), Count);
  M^.SetMacroData(A, LeftPad(Copy(M^.MacroProcess(GetPString(A^.Data)), 1, Count), Count));
 end;

procedure mcPadCh(M: PMacros; const Line: String);
 var
  Count: Longint;
  Ch: Char;
  A: PMacro;
 begin
  A:=M^.GetMacroAndClass(ExtractWord(2, Line, [' ']), mcUser);
  if A = Nil then Exit;
  Str2Longint(M^.MacroProcess(ExtractWord(3, Line, [' '])), Count);
  Ch:=Str2Char(M^.MacroProcess(ExtractWord(4, Line, [' '])));
  M^.SetMacroData(A, PadCh(Copy(M^.MacroProcess(GetPString(A^.Data)), 1, Count), Ch, Count));
 end;

procedure mcLPadCh(M: PMacros; const Line: String);
 var
  Count: Longint;
  Ch: Char;
  A: PMacro;
 begin
  A:=M^.GetMacroAndClass(ExtractWord(2, Line, [' ']), mcUser);
  if A = Nil then Exit;
  Str2Longint(M^.MacroProcess(ExtractWord(3, Line, [' '])), Count);
  Ch:=Str2Char(M^.MacroProcess(ExtractWord(4, Line, [' '])));
  M^.SetMacroData(A, LeftPadCh(Copy(M^.MacroProcess(GetPString(A^.Data)), 1, Count), Ch, Count));
 end;

procedure mcCopy(M: PMacros; const Line: String);
 var
  S1, S2: Longint;
  A: PMacro;
 begin
  A:=M^.GetMacroAndClass(ExtractWord(2, Line, [' ']), mcUser);
  if A = Nil then Exit;
  Str2Longint(M^.MacroProcess(ExtractWord(3, Line, [' '])), S1);
  Str2Longint(M^.MacroProcess(ExtractWord(4, Line, [' '])), S2);
  M^.SetMacroData(A, Copy(M^.MacroProcess(GetPString(A^.Data)), S1, S2));
 end;

procedure mcCenter(M: PMacros; const Line: String);
 var
  Count: Longint;
  A: PMacro;
 begin
  A:=M^.GetMacroAndClass(ExtractWord(2, Line, [' ']), mcUser);
  if A = Nil then Exit;
  Str2Longint(M^.MacroProcess(ExtractWord(3, Line, [' '])), Count);
  M^.SetMacroData(A, Center(Copy(M^.MacroProcess(GetPString(A^.Data)), 1, Count), Count));
 end;

procedure mcCenterCh(M: PMacros; const Line: String);
 var
  Count: Longint;
  Ch: Char;
  A: PMacro;
 begin
  A:=M^.GetMacroAndClass(ExtractWord(2, Line, [' ']), mcUser);
  if A = Nil then Exit;
  Str2Longint(M^.MacroProcess(ExtractWord(3, Line, [' '])), Count);
  Ch:=Str2Char(M^.MacroProcess(ExtractWord(4, Line, [' '])));
  M^.SetMacroData(A, CenterCh(Copy(M^.MacroProcess(GetPString(A^.Data)), 1, Count), Ch, Count));
 end;

procedure mcScale(M: PMacros; const Line: String);
 var
  A: PMacro;
  Cur, Max, Need: Longint;
 begin
  A:=M^.GetMacroAndClass(ExtractWord(2, Line, [' ']), mcUser);
  if A = Nil then Exit;
  Str2Longint(M^.MacroProcess(ExtractWord(3, Line, [' '])), Cur);
  Str2Longint(M^.MacroProcess(ExtractWord(4, Line, [' '])), Max);
  Str2Longint(M^.MacroProcess(ExtractWord(5, Line, [' '])), Need);
  if Max = 0 then Max:=1;
  M^.SetMacroData(A, Long2Str(Round(Cur / Max * Need)));
 end;

procedure mcNumFormat(M: PMacros; const Line: String);
 var
  A: PMacro;
  K: Longint;
 begin
  A:=M^.GetMacroAndClass(ExtractWord(2, Line, [' ']), mcUser);
  if A = Nil then Exit;
  Str2Longint(M^.MacroProcess(ExtractWord(2, Line, [' '])), K);
  M^.SetMacroData(A, Long2StrFmt(K));
 end;

procedure mcConvSize(M: PMacros; const Line: String);
 var
  A: PMacro;
  K: Longint;
  Z: Longint;
  S: String;
 begin
  A:=M^.GetMacroAndClass(ExtractWord(2, Line, [' ']), mcUser);
  if A = Nil then Exit;
  Str2Longint(M^.MacroProcess(ExtractWord(2, Line, [' '])), K);
  Str2Longint(M^.MacroProcess(ExtractWord(3, Line, [' '])), Z);
  S:=Long2StrFmt(K) + 'b';
  if Length(S) > Z then S:=Long2StrFmt(K div 1024) + 'K';
  if Length(S) > Z then S:=Long2StrFmt(K div 1024 div 1024) + 'M';
  if Length(S) > Z then S:=Long2StrFmt(K div 1024 div 1024 div 1024) + 'G';
  M^.SetMacroData(A, S);
 end;

procedure mcLength(M: PMacros; const Line: String);
 var
  A: PMacro;
  K: Longint;
  Z: Longint;
  S: String;
 begin
  A:=M^.GetMacroAndClass(ExtractWord(2, Line, [' ']), mcUser);
  if A = Nil then Exit;
  S:=M^.MacroProcess(GetAllAfterSpace(Line, 2));
  M^.SetMacroData(A, Long2Str(Length(S)));
 end;

procedure mcDestroy(M: PMacros; const Line: String);
 begin
  M^.RemoveMacro(ExtractWord(2, Line, [' ']));
 end;
{$IFNDEF VIRTUALPASCAL}
{$F-}
{$ENDIF}

(* Service functions *)
function NewStr(const S: String): PString;
 var
  P: PString;
 begin
  if S = '' then
   P:=Nil
  else
   begin
    GetMem(P, Length(S) + 1);
    P^:=S;
   end;
  NewStr:=P;
 end;

procedure DisposeStr(P: PString);
 begin
  if P <> Nil then FreeMem(P, Length(P^) + 1);
 end;

(* TMacro methods *)
constructor TMacro.Init(AID: String; const AData: String; AClassID: Byte; AIsFunc: Boolean; AFunc: TMacroFunction);
 begin
  StUpcaseEx(AID);
  TrimEx(AID);
  ID:=NewStr(AID);
  Data:=NewStr(AData);
  IsFunc:=AIsFunc;
  Func:=AFunc;
  ClassID:=AClassID;
 end;

destructor TMacro.Done;
 begin
  DisposeStr(ID);
  DisposeStr(Data);
 end;

(* TMacros methods *)
constructor TMacros.Init;
 begin
  ContainerInit;
  AddMacro('@nothing', '', mcUser);
  AddFunction('@assign', mcAssign, mcSystem);
  AddFunction('@destroy', mcDestroy, mcSystem);
  AddFunction('@addb', mcAddB, mcSystem);
  AddFunction('@addf', mcAddF, mcSystem);
  AddFunction('@pad', mcPad, mcSystem);
  AddFunction('@padch', mcPadCh, mcSystem);
  AddFunction('@leftpad', mcLPad, mcSystem);
  AddFunction('@leftpadch', mcLPadCh, mcSystem);
  AddFunction('@copy', mcCopy, mcSystem);
  AddFunction('@centerch', mcCenterCh, mcSystem);
  AddFunction('@center', mcCenter, mcSystem);
  AddFunction('@scale', mcScale, mcSystem);
  AddFunction('@numformat', mcNumFormat, mcSystem);
  AddFunction('@convsize', mcConvSize, mcSystem);
  AddFunction('@length', mcLength, mcSystem);
  AddAdditionalMacros;
 end;

procedure TMacros.AddMacro(const ID, Data: String; ClassID: Byte);
 var
  M: PMacro;
 begin
  RemoveMacro(ID);
  M:=New(PMacro, Init(ID, Data, ClassID, False, Nil));
  ContainerInsert(M);
 end;

procedure TMacros.AddFunction(const ID: String; Func: TMacroFunction; ClassID: Byte);
 var
  M: PMacro;
 begin
  RemoveMacro(ID);
  M:=New(PMacro, Init(ID, '', ClassID, True, Func));
  ContainerInsert(M);
 end;

function TMacros.GetMacro(ID: String): PMacro;
 var
  K: Longint;
 begin
  TrimEx(ID);
  StUpcaseEx(ID);
  for K:=1 to ContainerSize do
   if GetPString(ContainerAt(K)^.ID) = ID then
    begin
     GetMacro:=ContainerAt(K);
     Exit;
    end;
  GetMacro:=Nil;
 end;

function TMacros.GetMacroAndClass(ID: String; ClassID: Byte): PMacro;
 var
  K: Longint;
  M: PMacro;
 begin
  TrimEx(ID);
  StUpcaseEx(ID);
  for K:=1 to ContainerSize do
   begin
    M:=ContainerAt(K);
    if (GetPString(M^.ID) = ID) and (M^.ClassID = ClassID) then
     begin
      GetMacroAndClass:=M;
      Exit;
     end;
   end;
  GetMacroAndClass:=Nil;
 end;

procedure TMacros.SetMacroData(M: PMacro; const NewData: String);
 begin
  if M = Nil then Exit;
  DisposeStr(M^.Data);
  M^.Data:=NewStr(NewData);
 end;

procedure TMacros.RemoveMacro(const ID: String);
 var
  M: PMacro;
 begin
  M:=GetMacro(ID);
  if M = Nil then Exit;
  ContainerFree(M);
 end;

function TMacros.Process(S: String): String;
 var
  C: String;
  O: String;
  M: PMacro;
  K: Longint;
  Ok: Boolean;
 begin
  C:=ExtractWord(1, S, [' ']);
  TrimEx(C);
  StUpcaseEx(C);
  if (Str2Char(C) = '@') and (GetMacroAndClass(C, mcSystem) <> Nil) then
   begin
    EmptyLine:=True;
    Process:='';
    M:=GetMacroAndClass(C, mcSystem);
    if M^.IsFunc then
     M^.Func(@Self, Ltrim(S));
    Exit;
   end;
  EmptyLine:=False;
  repeat
   Ok:=True;
   for K:=1 to ContainerSize do
    begin
     M:=ContainerAt(K);
     if (M^.IsFunc) or (M^.ClassID <> mcUser) then Continue;
     ReplaceEx(S, GetPString(M^.ID), GetPString(M^.Data));
     if Replaced then
      Ok:=False;
    end;
  until Ok;
  Process:=S;
 end;

function TMacros.MacroProcess(const S: String): String;
 var
  OldEmptyLine: Boolean;
 begin
  OldEmptyLine:=EmptyLine;
  MacroProcess:=Process(S);
  EmptyLine:=OldEmptyLine;
 end;

procedure TMacros.AddAdditionalMacros;
 begin
{var
  Day, Month, Year, Hour, Min, Sec, Dow: Word;
  IWannaTime(Hour, Min, Sec);
  IWannaDate(Day, Month, Year);
  Dow:=DayOfWeek(Year, Month, Day);
  AddMacro('@curhour', LeftPadCh(Long2Str(Hour), '0', 2), mcUser);
  AddMacro('@curmin', LeftPadCh(Long2Str(Min), '0', 2), mcUser);
  AddMacro('@cursec', LeftPadCh(Long2Str(Sec), '0', 2), mcUser);
  AddMacro('@curday', LeftPadCh(Long2Str(Day), '0', 2), mcUser);
  AddMacro('@curmonth', LeftPadCh(Long2Str(Month), '0', 2), mcUser);
  AddMacro('@curyear', LeftPadCh(Long2Str(Year), '0', 2), mcUser);
  AddMacro('@curdow', GetDow(Dow), mcUser);
  AddMacro('@curshortdow', GetShortDow(Dow), mcUser);}
 end;

procedure TMacros.ContainerInit;
 begin
  Abstract;
 end;

function TMacros.ContainerSize: Longint;
 begin
  Abstract;
 end;

function TMacros.ContainerAt(Index: Longint): PMacro;
 begin
  Abstract;
 end;

procedure TMacros.ContainerInsert(Macro: PMacro);
 begin
  Abstract;
 end;

procedure TMacros.ContainerFree(Macro: PMacro);
 begin
  Abstract;
 end;

procedure TMacros.ContainerDone;
 begin
  Abstract;
 end;

procedure TMacros.Abstract;
 begin
  RunError(217);
 end;

destructor TMacros.Done;
 begin
  ContainerDone;
 end;

end.
