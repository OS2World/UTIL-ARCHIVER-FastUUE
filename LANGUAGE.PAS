unit Language;

interface
uses Types;

type
 PLangItem = ^TLangItem;
 TLangItem = object(TObject)
  Name, Value: PString;
  constructor Init(const AName, AValue: String);
  destructor Done; virtual;
 end;

const
 Quiet: Boolean = False;
 LanguagePool: PCollection = Nil;

procedure lngInit;
function  lngLoad: Boolean;
procedure lngDone;
procedure lngAddToPool(const Key, Value: String);

procedure lngBegin; {$IFNDEF SOLID}export;{$ENDIF}
procedure lngPush(const Value: String); {$IFNDEF SOLID}export;{$ENDIF}
procedure lngPrint(const LogName, Key: String); {$IFNDEF SOLID}export;{$ENDIF}
procedure lngEnd; {$IFNDEF SOLID}export;{$ENDIF}
function  lngGet(Key: String): String; {$IFNDEF SOLID}export;{$ENDIF}

procedure lngDump;

implementation
uses Wizard, Dos, Video, Config, Log, Semaphor;

{$I fastuue.inc}

const
 Pool: PStrings = Nil;

constructor TLangItem.Init;
 begin
  inherited Init;

  Name:=NewStr(AName);
  Value:=NewStr(AValue);
 end;

destructor TLangItem.Done;
 begin
  DisposeStr(Name);
  DisposeStr(Value);

  inherited Done;
 end;

function lngGet(Key: String): String;
 var
  L: PLangItem;
  K: Longint;
 begin
  if LanguagePool = Nil then
   begin
    lngGet:='';
    Exit;
   end;

  StUpcaseEx(Key);

  for K:=1 to LanguagePool^.Count do
   begin
    L:=LanguagePool^.At(K);

    if L^.Name^ = Key then
     begin
      if L^.Value = Nil then
       lngGet:=''
      else
       lngGet:=L^.Value^;

      Exit;
     end;
   end;

  lngGet:='';
 end;

procedure lngInit;
 begin
  LanguagePool:=New(PCollection, Init);
  Pool:=New(PStrings, Init);
 end;

function lngLoad;
 var
  Langs: PStrings;
  Param, Value: String;
 procedure CompileLang(S: String); far;
  var
   F: Text;
  begin
   TrimEx(S);
   S:=ForceExtension(S, 'LNG');
   {$I-}
   if IOResult <> 0 then;
   Assign(F, S);
   Reset(F);
   if InOutRes <> 0 then
    begin
     vSetAttr($0C);
     vPrintLn('    Error while opening "' + S + '", rc=#' + Long2Str(IOResult));
     vSetAttr($07);
     lngLoad:=False;
     Exit;
    end;

   while not Eof(F) do
    begin
     ReadLn(F, S);
     TrimEx(S);

     if (S[0] = #0) or (S[1] in [';', '/']) then
      Continue;

     Param:=ExtractWord(1, S, ['=']);

     TrimEx(Param);
     StUpcaseEx(Param);

     Value:=ExtractWord(2, S, ['"']);

     if Param <> '' then
      LanguagePool^.Insert(New(PLangItem, Init(Param, Value)));
    end;

   Close(F);

   if IOResult <> 0 then;
  end;
 var
  K: Longint;
  S: String;
  SR: SearchRec;
 begin
  lngLoad:=True;

  Langs:=New(PStrings, Init);

  cProcessList('Language', Langs);

  for K:=1 to Langs^.Count do
   begin
    S:=AddBackSlash(JustPathName(GetPString(Langs^.At(K))));

    FindFirst(GetPString(Langs^.At(K)), AnyFile, SR);
    while DosError = 0 do
     begin
      CompileLang(S + SR.Name);
      FindNext(SR);
     end;
    FindClose(SR);
   end;

  Dispose(Langs, Done);
 end;

procedure lngDone;
 begin
  Dispose(Pool, Done);
  Dispose(LanguagePool, Done);
 end;

procedure lngBegin;
 begin
  if Pool = Nil then
   Exit;

  Pool^.FreeAll;
 end;

procedure lngEnd;
 begin
  if Pool = Nil then
   Exit;

  Pool^.FreeAll;
 end;

procedure lngPush(const Value: String);
 begin
  if Pool = Nil then
   Exit;

  Pool^.Insert(NewStr(Value));
 end;

procedure lngAddToPool(const Key, Value: String);
 begin
  if LanguagePool = Nil then
   Exit;

  LanguagePool^.Insert(New(PLangItem, Init(StUpcase(Trim(Key)), Value)));
 end;

procedure lngDump;
 var
  K: Longint;
  I: PLangItem;
 begin
  logWrite('Main', '*** LANGUAGE POOL DUMP [start]');

  for K:=1 to LanguagePool^.Count do
   begin
    I:=LanguagePool^.At(K);

    logWrite('Main', '"' + GetPString(I^.Name) + '": "' + GetPString(I^.Value) + '"');
   end;

  logWrite('Main', '*** LANGUAGE POOL DUMP [end]');
 end;

{ core of videosubsystem }

type
 TCharacter = record
  Character: Char;
  Attribute: Byte;
 end;

const
 Color: Byte = $07;
 BufferSize: Integer = 0;

var
 Buffer: Array[1..256] of TCharacter;

procedure FlushBuffer;
 var
  K: Integer;
  S: String;
  Color: Byte;
 begin
  S:='';
  Color:=0;

  for K:=1 to BufferSize do
   begin
    if Buffer[K].Attribute <> Color then
     begin
      if S <> '' then
       vPrint(S);

      S:='';

      Color:=Buffer[K].Attribute;

      vSetAttr(Color);
     end;

    S:=Concat(S, Buffer[K].Character);
   end;

  if S <> '' then
   vPrint(S);

  BufferSize:=0;
 end;

procedure PutCharacter(const Character: Char; const Attribute: Byte);
 begin
  Inc(BufferSize);

  Buffer[BufferSize].Character:=Character;
  Buffer[BufferSize].Attribute:=Attribute;

  if BufferSize = 256 then
   FlushBuffer;
 end;

function lngProcess(const Key: String): String;
 function Check(const S: String): String;
  var
   K: Byte;
   O: String;
  begin
   if Key[1] = 'l' then
    begin
     Check:=S;

     Exit;
    end;

   O:='';

   for K:=1 to Length(S) do
    case S[K] of
     '$': O:=Concat(O, '$$');
     '#': O:=Concat(O, '##');
    else
     O:=Concat(O, S[K]);
    end;

   Check:=O;
  end;
 var
  S, O: String;
  K, B: Byte;
 begin
  S:=lngGet(Key);

  O:='';
  K:=0;

  repeat
   Inc(K);

   if K > Length(S) then
    Break;

   if (S[K] = '%') and (K <> Length(S)) and (S[K + 1] in ['0'..'9']) then
    begin
     Str2Byte(S[K + 1], B);

     Inc(K);

     O:=Concat(O, Check(GetPString(Pool^.At(B))));
    end
   else
    O:=Concat(O, S[K]);
  until False;

  S:='';
  K:=0;

  repeat
   Inc(K);

   if K > Length(O) then
    Break;

   case O[K] of
    '%':
     if O[K + 1] = '%' then
      begin
       S:=Concat(S, '%');

       Inc(K);
      end
     else
      begin
       B:=Pos('%', Copy(O, K + 1, 255));

       if B = 0 then
        Continue;

       S:=Concat(S, lngGet(Copy(O, K + 1, B - 1)));

       Inc(K, B);
      end;
   else
    S:=Concat(S, O[K]);
   end;
  until False;

  O:='';
  K:=0;

  repeat
   Inc(K);

   if K > Length(S) then
    Break;

   case S[K] of
    '#':
     if S[K + 1] = '#' then
      begin
       O:=Concat(O, '#');

       Inc(K);
      end
     else
      begin
       Str2Byte('$' + Copy(S, K + 1, 2), B);

       O:=Concat(O, Chr(B));

       Inc(K, 2);
      end;
   else
    O:=Concat(O, S[K]);
   end;
  until False;

  lngProcess:=O;
 end;

procedure lngPrint(const LogName, Key: String);
 var
  S: String;
  K: Byte;
 begin
  if not Quiet then
   begin
    S:=lngProcess(Concat('scr.', Key));

    if S <> '' then
     begin
      K:=0;

      repeat
       Inc(K);

       if K > Length(S) then
        Break;

       if Copy(S, K, 2) = '$$' then
        begin
         PutCharacter('$', Color);

         Inc(K);
        end else
       if S[K] = '$' then
        begin
         Str2Byte(Concat('$', Copy(S, K + 1, 2)), Color);

         Inc(K, 2);
        end else
       PutCharacter(S[K], Color);
      until False;
     end;

    FlushBuffer;
   end;

  S:=lngProcess(Concat('log.', Key));

  if S <> '' then
   logWrite(LogName, S);
 end;

end.
