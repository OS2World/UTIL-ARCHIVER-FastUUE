unit Division;

{
  Division(tm) Unit for FastUUE(tm)
  (q) by sergey korowkin, 1999.
}

interface

procedure diInit;
procedure diDone;

function diSeek(const Identifier: Longint): Pointer; {$IFNDEF SOLID}export;{$ENDIF}
function diCreate(const Identifier: Longint): Pointer; {$IFNDEF SOLID}export;{$ENDIF}
function diDestroy(const Identifier: Longint): Boolean; {$IFNDEF SOLID}export;{$ENDIF}

function diSetString(const Structure: Pointer; const Name, Value: String): Boolean; {$IFNDEF SOLID}export;{$ENDIF}
function diSetBool(const Structure: Pointer; const Name: String; const Value: Boolean): Boolean; {$IFNDEF SOLID}export;{$ENDIF}
function diSetNum(const Structure: Pointer; const Name: String; const Value: Longint): Boolean; {$IFNDEF SOLID}export;{$ENDIF}

function diGetString(const Structure: Pointer; const Name: String): String; {$IFNDEF SOLID}export;{$ENDIF}
function diGetBool(const Structure: Pointer; const Name: String): Boolean; {$IFNDEF SOLID}export;{$ENDIF}
function diGetNum(const Structure: Pointer; const Name: String): Longint; {$IFNDEF SOLID}export;{$ENDIF}

function diDestroyString(const Structure: Pointer; const Name: String): Boolean; {$IFNDEF SOLID}export;{$ENDIF}

function diCreateList(const Structure: Pointer; const Name: String): Pointer; {$IFNDEF SOLID}export;{$ENDIF}
function diDestroyList(const Structure: Pointer; const Name: String): Boolean; {$IFNDEF SOLID}export;{$ENDIF}

implementation
uses
     Types,
     Video,
     Wizard;

{ TDivisionItem declaration }

type
 PDivisionItem = ^TDivisionItem;
 TDivisionItem = object(TObject)
  Name: PString;
  constructor Init(const AName: String);
  destructor Done; virtual;
 end;

{ TDivisionItem core }

constructor TDivisionItem.Init(const AName: String);
 begin
  inherited Init;
  Name:=NewStr(StUpcase(AName));
 end;

destructor TDivisionItem.Done;
 begin
  DisposeStr(Name);
  inherited Done;
 end;

{ TDivisionString declaration }

type
 PDivisionString = ^TDivisionString;
 TDivisionString = object(TDivisionItem)
  Data: PString;
  constructor Init(const AName, AData: String);
  procedure Change(const AData: String);
  destructor Done; virtual;
 end;

{ TDivisionString core }

constructor TDivisionString.Init(const AName, AData: String);
 begin
  inherited Init(AName);
  Data:=NewStr(AData);
 end;

procedure TDivisionString.Change(const AData: String);
 begin
  DisposeStr(Data);
  Data:=NewStr(AData);
 end;

destructor TDivisionString.Done;
 begin
  DisposeStr(Data);
  inherited Done;
 end;

{ TDivisionList declaration }

type
 PDivisionList = ^TDivisionList;
 TDivisionList = object(TDivisionItem)
  Data: PStrings;
  constructor Init(const AName: String);
  destructor Done; virtual;
 end;

{ TDivisionList core }

constructor TDivisionList.Init(const AName: String);
 begin
  inherited Init(AName);
  Data:=New(PStrings, Init);
 end;

destructor TDivisionList.Done;
 begin
  Dispose(Data, Done);
  inherited Done;
 end;

{ TDivision declaration }

type
 PDivision = ^TDivision;
 TDivision = object(TObject)
  Identifier: Longint;
  Items: PCollection;
  constructor Init(const AIdentifier: Longint);
  destructor Done; virtual;
 end;

{ TDivision core }

constructor TDivision.Init(const AIdentifier: Longint);
 begin
  inherited Init;
  Identifier:=AIdentifier;
  Items:=New(PCollection, Init);
 end;

destructor TDivision.Done;
 begin
  Dispose(Items, Done);
  inherited Done;
 end;

{ TStructure declaration }

type
 PStructure = ^TStructure;
 TStructure = object(TObject)
  Identifier: Longint;
  Items: PCollection;
  constructor Init(const AIdentifier: Longint);
  destructor Done; virtual;
 end;

{ TStructure core }

constructor TStructure.Init(const AIdentifier: Longint);
 begin
  inherited Init;
  Identifier:=AIdentifier;
  Items:=New(PCollection, Init);
 end;

destructor TStructure.Done;
 begin
  Dispose(Items, Done);
  inherited Done;
 end;

{ externals core }

const
 Structures: PCollection = Nil;

procedure diInit;
 begin
  Structures:=New(PCollection, Init);
 end;

procedure diDone;
 begin
  Dispose(Structures, Done);
 end;

function diSeek(const Identifier: Longint): Pointer;
 var
  K: Longint;
 begin
  for K:=1 to Structures^.Count do
   if PStructure(Structures^.At(K))^.Identifier = Identifier then
    begin
     diSeek:=Structures^.At(K);
     Exit;
    end;
  diSeek:=Nil;
 end;

function diCreate(const Identifier: Longint): Pointer;
 var
  Structure: PStructure;
 begin
  Structure:=diSeek(Identifier);
  if Structure = Nil then
   begin
    Structure:=New(PStructure, Init(Identifier));
    Structures^.Insert(Structure);
   end;
  diCreate:=Structure;
 end;

function diDestroy(const Identifier: Longint): Boolean;
 var
  Structure: PStructure;
 begin
  Structure:=diSeek(Identifier);
  if Structure = Nil then
   diDestroy:=False
  else
   begin
    Structures^.Free(Structure);
    diDestroy:=True;
   end;
 end;

function diSeekItem(const Structure: PStructure; Name: String): PDivisionItem;
 var
  K: Longint;
 begin
  StUpcaseEx(Name);
  for K:=1 to Structure^.Items^.Count do
   if PDivisionItem(Structure^.Items^.At(K))^.Name^ = Name then
    begin
     diSeekItem:=Structure^.Items^.At(K);
     Exit;
    end;
  diSeekItem:=Nil;
 end;

function diSetString(const Structure: Pointer; const Name, Value: String): Boolean;
 var
  Item: PDivisionString;
 begin
  Item:=PDivisionString(diSeekItem(Structure, Name));
  if Item = Nil then
   begin
    Item:=New(PDivisionString, Init(Name, Value));
    PStructure(Structure)^.Items^.Insert(Item);
    diSetString:=True;
   end
  else
   begin
    Item^.Change(Value);
    diSetString:=False;
   end;
 end;

function diSetBool(const Structure: Pointer; const Name: String; const Value: Boolean): Boolean;
 begin
  case Value of
   True: diSetBool:=diSetString(Structure, Name, 'Yes');
   False: diSetBool:=diSetString(Structure, Name, 'No');
  end;
 end;

function diSetNum(const Structure: Pointer; const Name: String; const Value: Longint): Boolean;
 begin
  diSetNum:=diSetString(Structure, Name, Long2Str(Value));
 end;

function diGetString(const Structure: Pointer; const Name: String): String;
 var
  Item: PDivisionString;
 begin
  Item:=PDivisionString(diSeekItem(Structure, Name));
  if Item <> Nil then
   if Item^.Data = Nil then
    diGetString:=''
   else
    diGetString:=Item^.Data^
  else
   diGetString:='';
 end;

function diGetBool(const Structure: Pointer; const Name: String): Boolean;
 var
  S: String;
 begin
  S:=diGetString(Structure, Name);
  diGetBool:=(S[0] <> #0) and (S[1] in ['1', 'Y', 'y', 'T', 't']);
 end;

function diGetNum(const Structure: Pointer; const Name: String): Longint;
 var
  S: String;
  L: Longint;
 begin
  S:=diGetString(Structure, Name);
  Str2Longint(S, L);
  diGetNum:=L;
 end;

function diDestroyString(const Structure: Pointer; const Name: String): Boolean;
 var
  Item: PDivisionString;
 begin
  Item:=PDivisionString(diSeekItem(Structure, Name));
  if Item <> Nil then
   begin
    PStructure(Structure)^.Items^.Free(Item);
    diDestroyString:=True;
   end
  else
   diDestroyString:=False;
 end;

function diCreateList(const Structure: Pointer; const Name: String): Pointer;
 var
  Item: PDivisionList;
 begin
  Item:=PDivisionList(diSeekItem(Structure, Name));
  if Item = Nil then
   begin
    Item:=New(PDivisionList, Init(Name));
    PStructure(Structure)^.Items^.Insert(Item);
    diCreateList:=Item^.Data;
   end
  else
   diCreateList:=Item^.Data;
 end;

function diDestroyList(const Structure: Pointer; const Name: String): Boolean;
 var
  Item: PDivisionList;
 begin
  Item:=PDivisionList(diSeekItem(Structure, Name));
  if Item <> Nil then
   begin
    PStructure(Structure)^.Items^.Free(Item);
    diDestroyList:=True;
   end
  else
   diDestroyList:=False;
 end;

end.