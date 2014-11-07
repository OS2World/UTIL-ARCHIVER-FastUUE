unit MacrozTV;

interface
uses
     Objects, Macroz, Wizard;

type
 PMacrosCollection = ^TMacrosCollection;
 TMacrosCollection = object(TCollection)
  procedure FreeItem(Item: Pointer); virtual;
 end;

 PMacrosEngine = ^TMacrosEngine;
 TMacrosEngine = object(TMacros)
  Container: PMacrosCollection;
  procedure AddAdditionalMacros; virtual;
  procedure ContainerInit; virtual;
  function ContainerSize: Longint; virtual;
  function ContainerAt(Index: Longint): PMacro; virtual;
  procedure ContainerInsert(Macro: PMacro); virtual;
  procedure ContainerFree(Macro: PMacro); virtual;
  procedure ContainerDone; virtual;
 end;

implementation

procedure TMacrosCollection.FreeItem(Item: Pointer);
 begin
  Dispose(PMacro(Item), Done);
 end;

procedure TMacrosEngine.AddAdditionalMacros;
 var
  Day, Month, Year, Hour, Min, Sec: Word;
 begin
  IWannaTime(Hour, Min, Sec);
  IWannaDate(Day, Month, Year);
  AddMacro('@curhour', LeftPadCh(Long2Str(Hour), '0', 2), mcUser);
  AddMacro('@curmin', LeftPadCh(Long2Str(Min), '0', 2), mcUser);
  AddMacro('@cursec', LeftPadCh(Long2Str(Sec), '0', 2), mcUser);
  AddMacro('@curday', LeftPadCh(Long2Str(Day), '0', 2), mcUser);
  AddMacro('@curmonth', LeftPadCh(Long2Str(Month), '0', 2), mcUser);
  AddMacro('@curyear', LeftPadCh(Long2Str(Year), '0', 2), mcUser);
 end;

procedure TMacrosEngine.ContainerInit;
 begin
  Container:=New(PMacrosCollection, Init(16, 16));
 end;

function TMacrosEngine.ContainerSize: Longint;
 begin
  ContainerSize:=Container^.Count;
 end;

function TMacrosEngine.ContainerAt(Index: Longint): PMacro;
 begin
  ContainerAt:=Container^.At(Index - 1);
 end;

procedure TMacrosEngine.ContainerInsert(Macro: PMacro);
 begin
  Container^.Insert(Macro);
 end;

procedure TMacrosEngine.ContainerFree(Macro: PMacro);
 begin
  Container^.Free(Macro);
 end;

procedure TMacrosEngine.ContainerDone;
 begin
  Dispose(Container, Done);
 end;

end.