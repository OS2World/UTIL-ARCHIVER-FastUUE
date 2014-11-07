{
 Common stuff for any good programmer. ;-)

 version 2.50, 21/01/2000
  full DELPHI compatibility
  (don't forget to set DELPHI in conditional defines)
  global changes

 (q) by sergey korowkin aka sk // [rAN], 1999-2001.

 contact: 2:6033/27@fidonet, sk@fido.irk.ru, http://sk.elk.ru
}

{$IFDEF VIRTUALPASCAL}
{&Delphi+,CDecl-,Use32-}
{$ENDIF}
{$I-}

unit Wizard;

{$IFDEF DPMI}           {$DEFINE DOS}     {$ENDIF}
{$IFDEF MSDOS}          {$DEFINE DOS}     {$ENDIF}
{$IFDEF VIRTUALPASCAL}  {$DEFINE CODE32}  {$ENDIF}
{$IFDEF DELPHI}         {$DEFINE CODE32}
                        {$DEFINE WIN32}
                        {$DEFINE HUGEISON}{$ENDIF}

interface
uses
     {$IFDEF VIRTUALPASCAL}
     vpSysLow,
     Dos;
     {$ENDIF}

     {$IFDEF DELPHI}
     Windows,
     SysUtils;
     {$ENDIF}

     {$IFDEF DOS}
     Dos;
     {$ENDIF}

type
 PCharSet = ^TCharSet;
 TCharSet = set of Char;

 {$IFDEF VIRTUALPASCAL}
 xWord = Longint;
 xInteger = Longint;
 {$ELSE}
 xWord = Word;
 xInteger = Integer;
 {$ENDIF}

{$IFDEF DELPHI}
type
 TextRec = TTextRec;

 SearchRec = TSearchRec;

var
 DosError: Longint;

const
 ReadOnly          = faReadOnly;
 Hidden            = faHidden;
 SysFile           = faSysFile;
 VolumeID          = faVolumeID;
 Directory         = faDirectory;
 Archive           = faArchive;
 AnyFile           = faAnyFile;

{$HINTS OFF}
{$WARNINGS OFF}
{$ENDIF}

var
 Replaced: Boolean; { True if Replace/ReplaceEx did anything }

const
 Months: Array[1..12] Of String[3] =
  ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');

 Days: array[Boolean, 1..12] of Longint =
  ((31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31),
   (31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31));

const
 OSid  = {$IFDEF DPMI}  '/DPMI' {$ENDIF}
         {$IFDEF WIN32} '/W32'  {$ENDIF}
         {$IFDEF OS2}   '/OS2'  {$ENDIF}
         {$IFDEF MSDOS} '/DOS'  {$ENDIF};

 OSuid = {$IFDEF DPMI}   $0001  {$ENDIF}
         {$IFDEF WIN32}  $0002  {$ENDIF}
         {$IFDEF OS2}    $0003  {$ENDIF}
         {$IFDEF MSDOS}  $0004  {$ENDIF};

{ strings }

procedure LocaseAsm;
procedure UpcaseAsm;

function  Locase(const Ch: Char): Char;
function  Upcase(const Ch: Char): Char;

function  StLoCase(S: String): String; {*}
function  StUpCase(S: String): String; {*}
procedure StLocaseEx(var S: String); {*}
procedure StUpcaseEx(var S: String); {*}
procedure StrLocase(P: PChar); {*}
procedure StrUpcase(P: PChar); {*}

function  LeftPad(const S: String; const Len: Byte): String; {*}
function  LeftPadCh(const S: String; const Ch: Char; const Len: Byte): String; {*}
function  Center(const S: String; const Width: Byte): String; {*}
function  CenterCh(const S: String; const Ch: Char; const Width: Byte): String; {*}
function  Pad(const S: String; const Len: Byte): String; {*}
function  PadCh(const S: String; const Ch: Char; const Len: Byte): String; {*}

function  LTrim(S: String): String; {*}
function  Trim(S: String): String; {*}
procedure TrimEx(var S: String); {*}
function  RTrim(S: String): String; {*}

function  ExtractWord(const N: Byte; const S: String; const WordDelims: TCharSet): String; {*}
function  WordCount(const S: String; const WordDelims: TCharSet): Byte; {*}

function  GetAllAfterChar(const S: String; const Spc: Byte; const Ch: Char): String; {*}
function  GetAllAfterSpace(const S: String; const Spc: Byte): String; {*}

function  Replace(S: String; const A, B: String): String; {*}
procedure ReplaceChar(var S: String; const Source, Dest: Char); {*}
procedure ReplaceEx(var S: String; A: String; const B: String); {*}

procedure FixTabs(var S: String); {*}
procedure RepackString(var S: String; const Delims: TCharSet; const Divider: String); {*}

function  nlz(const S: String): String; {*}

{ pstrings }

function  GetPString(const S: Pointer): String; {*}
procedure GetPStringEx(const S: Pointer; var R: String); {*}

{ numbers: hex }

function  HexB(const B: Byte): String; {*}
function  HexT(const W: Word): String; {*}
function  HexW(const W: Word): String; {*}
function  HexL(const L: Longint): String; {*}
function  HexPtr(const P: Pointer): String; {*}

{ numbers to strings }

function  Long2Str(const L: Longint): String; {*}
function  Long2StrFmt(const L: Longint): String; {*}
function  Real2Str(const R: Real; const Width, Decimals: Byte): String;

function  Lz(const Number: Longint): String; {*}

{ strings to chars/numbers }

function  Str2Char(const S: String): Char;
function  Str2Number(const S: String): Boolean; {*}
function  Str2Byte(const S: String; var A: Byte): Boolean;
function  Str2Integer(const S: String; var A: Integer): Boolean;
function  Str2Word(const S: String; var A: Word): Boolean;
function  Str2xWord(const S: String; var A: xWord): Boolean;
function  Str2Longint(const S: String; var A: Longint): Boolean; {*}
function  Size2KB(const Size: Longint): String; {*}

{ files }

function  AddBackSlash(S: String): String; {*}
function  RemoveBackSlash(S: String): String; {*}
function  AddDot(const S: String): String; {*}
function  ExistDir(const S: String): Boolean; {*}
function  ExistFile(const S: String): Boolean; {*}
function  FExpand(const S: String): String; {*}

function  HasExtension(const Name: String; var DotPos: Word): Boolean; {*}
function  ForceExtension(const Name, Ext: String): String; {*}
function  JustExtension(const Name: String): String; {*}
function  JustFilename(const PathName: String): String; {*}
function  JustFilenameOnly(const PathName: String): String; {*}
function  JustPathname(const PathName: String): String; {*}

function  TextSeek(var F: Text; const Target: Longint): Boolean;
function  TextFileSize(var F: Text) : Longint;
function  TextPos(var F: Text): Longint;

function  FileLocked(const FName: String): Boolean; {*}
function  EraseFile(const FName: String): Boolean; {*}
function  TouchFile(const FName: String): Boolean; {*}
function  RenameFile(const AFName, BFName: String): Boolean; {*}
function  RenameFileEx(const AFName, BFName: String; var rc: Longint): Boolean; {*}
function  EmptyDirectory(const Path: String): Boolean; {*}
function  EmptyDirectoryEx(const Path: String; const OnlyFiles: Boolean): Boolean; {*}

function  DistortFileName(var FName: String; const DistortExtension: Boolean): Boolean; {*}
function  DistortFileExtension(var FName: String): Boolean; {*}
function  DistortFileExtensionLastLetter(var FName: String; Force: Boolean): Boolean; {*}

{ time & date }

function  Clock: Longint; {*}
procedure Wait(const ms: Longint); {*}
function  DayOfWeek(const Year, Month, Day: Longint): Word; {*}
Procedure IWannaDate (Var D, M, Y: Word);
Procedure IWannaTime (Var H, M, S: Word);
Function  TimeFix: LongInt;
Procedure TimeDif (L: LongInt; Var DT: DateTime);

{ wildcards }

function  CheckWildcard(const Src, Mask: String): Boolean; {*}
function  IsWildcard(const Mask: String): Boolean; {*}

{ misc }

function  GetBinkDateTime: String; {*}

{ multiplatform stuff }

{$IFNDEF DELPHI}
function  GetAttr(const FName: String): Longint; {*}
function  GetFileDate(const FName: String): Longint; {*}
function  GetFileSize(const S: String): Longint; {*}
function  GetStamp(const FName: String): Longint; {*}
procedure SetAttr(const FName: String; K: Longint); {*}
procedure SetStamp(const FName: String; K: Longint); {*}
function  StackOverflow: Boolean; {*}
{$ENDIF}

{$IFDEF DELPHI}
procedure GetDate(var Year, Month, Day, Dow: Word);
procedure GetTime(var Hour, Min, Sec, Sec100: Word);
procedure FindFirst(const Path: String; const Attrs: Integer; var SR: SearchRec);
procedure FindNext(var SR: SearchRec);
procedure FindClose(var SR: SearchRec);
{$ENDIF}

{$IFDEF DOS}
procedure FindClose(var SR: SearchRec);
procedure SetLength(var S: String; const NewLength: Byte);
{$ENDIF}

function _s(const Value: Longint): String; {*}
function _nz(const Value: Longint; const S: String): String; {*}

function NumberWidth(const Value: Longint): Byte; {*}

function CompareLongint(const L1, L2: Longint): xInteger; {*}

{ FidoNet stuff :-) }

Function  GetPktDateTime: String;
Function  GetPktDateTimeCustom (Day, Month, Year, Hour, Min, Sec: Word): String;
Procedure ParsePktDateTime (S: String; Var Day, Month, Year, Hour, Min, Sec, Dow: XWord);

implementation

const
 DosDelimSet    : set of Char           = ['\', ':', #0];
 Digits         : array[0..$F] of Char  = '0123456789ABCDEF';

var
 ValL: xInteger;

type
 Long = record
  LowWord, HighWord: System.Word;
 end;

 DateTimeRec = record
  FTime, FDate: System.Word;
 end;

{$IFNDEF CODE32}
 PTextBuffer = ^TTextBuffer;
 TTextBuffer = array[0..65520] of Byte;
 TText = record
  Handle: Word;
  Mode: Word;
  BufSize: Word;
  Priv: Word;
  BufPos: Word;
  BufEnd: Word;
  BufPtr: PTextBuffer;
  OpenProc: Pointer;
  InOutProc: Pointer;
  FlushProc: Pointer;
  CloseProc: Pointer;
  UserData: array[1..16] of Byte;
  Name: array[0..79] of Char;
  Buffer: array[0..127] of Char;
 end;

const
 FMClosed      = $D7B0;
 FMInput       = $D7B1;
 FMOutput      = $D7B2;
 FMInOut       = $D7B3;
{$ENDIF}

const
 LocaseTable: array[#$40..#$FF] of Byte = (
    $40,$61,$62,$63,$64,$65,$66,$67,$68,$69,$6A,$6B,$6C,$6D,$6E,$6F,
    $70,$71,$72,$73,$74,$75,$76,$77,$78,$79,$7A,$5B,$5C,$5D,$5E,$5F,
    $60,$61,$62,$63,$64,$65,$66,$67,$68,$69,$6A,$6B,$6C,$6D,$6E,$6F,
    $70,$71,$72,$73,$74,$75,$76,$77,$78,$79,$7A,$7B,$7C,$7D,$7E,$7F,
    $A0,$A1,$A2,$A3,$A4,$A5,$A6,$A7,$A8,$A9,$AA,$AB,$AC,$AD,$AE,$AF,
    $E0,$E1,$E2,$E3,$E4,$E5,$E6,$E7,$E8,$E9,$EA,$EB,$EC,$ED,$EE,$EF,
    $A0,$A1,$A2,$A3,$A4,$A5,$A6,$A7,$A8,$A9,$AA,$AB,$AC,$AD,$AE,$AF,
    $B0,$B1,$B2,$B3,$B4,$B5,$B6,$B7,$B8,$B9,$BA,$BB,$BC,$BD,$BE,$BF,
    $C0,$C1,$C2,$C3,$C4,$C5,$C6,$C7,$C8,$C9,$CA,$CB,$CC,$CD,$CE,$CF,
    $D0,$D1,$D2,$D3,$D4,$D5,$D6,$D7,$D8,$D9,$DA,$DB,$DC,$DD,$DE,$DF,
    $E0,$E1,$E2,$E3,$E4,$E5,$E6,$E7,$E8,$E9,$EA,$EB,$EC,$ED,$EE,$EF,
    $F1,$F1,$F2,$F3,$F4,$F5,$F6,$F7,$F8,$F9,$FA,$FB,$FC,$FD,$FE,$FF);

 UpcaseTable: array[#$40..#$FF] of Byte = (
    $40,$41,$42,$43,$44,$45,$46,$47,$48,$49,$4A,$4B,$4C,$4D,$4E,$4F,
    $50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$5A,$5B,$5C,$5D,$5E,$5F,
    $60,$41,$42,$43,$44,$45,$46,$47,$48,$49,$4A,$4B,$4C,$4D,$4E,$4F,
    $50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$5A,$7B,$7C,$7D,$7E,$7F,
    $80,$81,$82,$83,$84,$85,$86,$87,$88,$89,$8A,$8B,$8C,$8D,$8E,$8F,
    $90,$91,$92,$93,$94,$95,$96,$97,$98,$99,$9A,$9B,$9C,$9D,$9E,$9F,
    $80,$81,$82,$83,$84,$85,$86,$87,$88,$89,$8A,$8B,$8C,$8D,$8E,$8F,
    $B0,$B1,$B2,$B3,$B4,$B5,$B6,$B7,$B8,$B9,$BA,$BB,$BC,$BD,$BE,$BF,
    $C0,$C1,$C2,$C3,$C4,$C5,$C6,$C7,$C8,$C9,$CA,$CB,$CC,$CD,$CE,$CF,
    $D0,$D1,$D2,$D3,$D4,$D5,$D6,$D7,$D8,$D9,$DA,$DB,$DC,$DD,$DE,$DF,
    $90,$91,$92,$93,$94,$95,$96,$97,$98,$99,$9A,$9B,$9C,$9D,$9E,$9F,
    $F0,$F0,$F2,$F3,$F4,$F5,$F6,$F7,$F8,$F9,$FA,$FB,$FC,$FD,$FE,$FF);

{ strings }

function Locase(const Ch: Char): Char; assembler; {&USES EBX}
 asm
  mov al, &Ch
  cmp al, $40
  jb @@1
  sub al, 40h
  {$IFDEF CODE32}
  lea ebx, LocaseTable
  {$ELSE}
  mov bx, seg LocaseTable
  push bx
  pop ds
  mov bx, offset LocaseTable
  {$ENDIF}
  xlat
 @@1:
 end;

function Upcase(const Ch: Char): Char; assembler; {&USES EBX}
 asm
  mov al, &Ch
  cmp al, $40
  jb @@1
  sub al, 40h
  {$IFDEF CODE32}
  lea ebx, UpcaseTable
  {$ELSE}
  mov bx, seg UpcaseTable
  push bx
  pop ds
  mov bx, offset UpcaseTable
  {$ENDIF}
  xlat
 @@1:
 end;

procedure LocaseAsm; assembler; {&USES EBX}
 asm
  cmp   al, $40
  jb    @@1
  sub   al, 40h
  {$IFDEF CODE32}
  lea   ebx, LocaseTable
  {$ELSE}
  push  ds
  mov   bx, seg LocaseTable
  push  bx
  pop   ds
  mov   bx, offset LocaseTable
  {$ENDIF}
  xlat
  {$IFNDEF CODE32}
  pop   ds
  {$ENDIF}
 @@1:
 end;

procedure UpcaseAsm; assembler; {&USES EBX}
 asm
  cmp   al, $40
  jb    @@1
  sub   al, 40h
  {$IFDEF CODE32}
  lea   ebx, UpcaseTable
  {$ELSE}
  push  ds
  mov   bx, seg UpcaseTable
  push  bx
  pop   ds
  mov   bx, offset UpcaseTable
  {$ENDIF}
  xlat
  {$IFNDEF CODE32}
  pop   ds
  {$ENDIF}
 @@1:
 end;

function StLocase(S: String): String;
 begin
  StLocaseEx(S);

  StLocase:=S;
 end;

function StUpcase(S: String): String;
 begin
  StUpcaseEx(S);

  StUpcase:=S;
 end;

{$IFDEF HUGEISON}
procedure StLocaseEx(var S: String);
 var
  K: Byte;
 begin
  for K:=1 to Length(S) do
   S[K]:=Locase(S[K]);
 end;
{$ELSE}
procedure StLocaseEx(var S: String); assembler; {&USES ESI, EDI, EAX, ECX}
 asm
  {$IFNDEF CODE32}
  push ds
  {$ENDIF}
  cld
  {$IFDEF CODE32}
  mov esi, [S]
  mov edi, [S]
  {$ELSE}
  lds si, S
  les di, S
  {$ENDIF}
  lodsb
  stosb
  {$IFDEF CODE32}
  xor ah, ah
  movzx ecx, ax
  {$ELSE}
  xor ch, ch
  mov cl, al
  {$ENDIF}
  cmp al, 0
  jz @@2
 @@1:
  lodsb

  {$IFNDEF CODE32}
  push ds
  push ax
  {$ELSE}
  push eax
  {$ENDIF}
  call Locase
  {$IFNDEF CODE32}
  pop ds
  {$ENDIF}

  stosb
  loop @@1
 @@2:
  {$IFNDEF CODE32}
  pop ds
  {$ENDIF}
 end;
{$ENDIF}

{$IFDEF HUGEISON}
procedure StUpcaseEx(var S: String);
 var
  K: Byte;
 begin
  for K:=1 to Length(S) do
   S[K]:=Upcase(S[K]);
 end;
{$ELSE}
procedure StUpcaseEx(var S: String); assembler; {&USES ESI, EDI, EAX, ECX}
 asm
  {$IFNDEF CODE32}
  push ds
  {$ENDIF}
  cld
  {$IFDEF CODE32}
  mov esi, [S]
  mov edi, [S]
  {$ELSE}
  lds si, S
  les di, S
  {$ENDIF}
  lodsb
  stosb
  {$IFDEF CODE32}
  xor ah, ah
  movzx ecx, ax
  {$ELSE}
  xor ch, ch
  mov cl, al
  {$ENDIF}
  cmp al, 0
  jz @@2
 @@1:
  lodsb

  {$IFNDEF CODE32}
  push ds
  push ax
  {$ELSE}
  push eax
  {$ENDIF}
  call Upcase
  {$IFNDEF CODE32}
  pop ds
  {$ENDIF}

  stosb
  loop @@1
 @@2:
  {$IFNDEF CODE32}
  pop ds
  {$ENDIF}
 end;
{$ENDIF}

procedure StrLocase(P: PChar);
 begin
  while P[0] <> #0 do
   begin
    P[0]:=Locase(P[0]);

    Inc(P);
   end;
 end;

procedure StrUpcase(P: PChar);
 begin
  while P[0] <> #0 do
   begin
    P[0]:=Upcase(P[0]);

    Inc(P);
   end;
 end;


function LeftPad(const S: String; const Len: Byte): String;
 begin
  LeftPad:=LeftPadCh(S, ' ', Len);
 end;

function LeftPadCh(const S: String; const Ch: Char; const Len: Byte): String;
 {$IFDEF DOS}
 var
  Result: String;
 {$ENDIF}
 begin
  if Length(S) >= Len then
   Result:=S
  else
   if Length(S) < 255 then
    begin
     SetLength(Result, Len);

     Move(S[1], Result[Succ(Word(Len)) - Length(S)], Length(S));

     FillChar(Result[1], Len - Length(S), Ch);
    end;

  {$IFDEF DOS}
  LeftPadCh:=Result;
  {$ENDIF}
 end;

function Center(const S: String; const Width: Byte): String;
 begin
  Center:=CenterCh(S, ' ', Width);
 end;

function CenterCh(const S: String; const Ch: Char; const Width: Byte): String;
 {$IFDEF DOS}
 var
  Result: String;
 {$ENDIF}
 begin
  if Length(S) >= Width then
   Result:=S
  else
   if Length(S) < 255 then
    begin
     SetLength(Result, Width);

     FillChar(Result[1], Width, Ch);

     Move(S[1], Result[Succ((Width - Length(S)) shr 1)], Length(S));
    end;

  {$IFDEF DOS}
  CenterCh:=Result;
  {$ENDIF}
 end;

function Pad(const S: String; const Len: Byte): String;
 begin
  Pad:=PadCh(S, ' ', Len);
 end;

function PadCh(const S: String; const Ch: Char; const Len: Byte): String;
 {$IFDEF DOS}
 var
  Result: String;
 {$ENDIF}
 begin
  if Length(S) >= Len then
   Result:=S
  else
   begin
    SetLength(Result, Len);

    Move(S[1], Result[1], Length(S));

    if Length(S) < 255 then
     FillChar(Result[Succ(Length(S))], Len - Length(S), Ch);
   end;

  {$IFDEF DOS}
  PadCh:=Result;
  {$ENDIF}
 end;


function LTrim(S: String): String;
 var
  K: Byte;
 begin
  K:=1;

  while (K <= Length(S)) and (S[K] = ' ') do
   Inc(K);

  LTrim:=Copy(S, K, 255);
 end;

function Trim(S: String): String;
 begin
  TrimEx(S);

  Trim:=S;
 end;

procedure TrimEx(var S: String);
 var
  K, L: Byte;
 begin
  K:=1;

  while (K <= Length(S)) and (S[K] = ' ') do
   Inc(K);

  L:=Length(S);

  while (L <> 0) and (S[L] = ' ') do
   Dec(L);

  Dec(L, K);
  Inc(L);

  S:=Copy(S, K, L);
 end;

function RTrim(S: String): String;
 var
  L: Byte;
 begin
  L:=Length(S);

  while (L <> 0) and (S[L] = ' ') do
   Dec(L);

  RTrim:=Copy(S, 1, L);
 end;


function ExtractWord(const N: Byte; const S: String; const WordDelims: TCharSet): String;
 var
  I: Word;
  Count, Len: Byte;
  {$IFDEF DOS}
  Result: String;
  {$ENDIF}
 begin
  Count:=0;
  I:=1;
  Len:=0;
  Result:='';

  while (I <= Length(S)) and (Count <> N) do
   begin
    while (I <= Length(S)) and (S[I] in WordDelims) do
     Inc(I);

     if I <= Length(S) then
      Inc(Count);

     while (I <= Length(S)) and not (S[I] in WordDelims) do
      begin
       if Count = N then
        begin
         Inc(Len);

         SetLength(Result, Len);
         Result[Len]:=S[I];
        end;

       Inc(I);
      end;
   end;

  {$IFDEF DOS}
  ExtractWord:=Result;
  {$ENDIF}
 end;

function WordCount(const S: String; const WordDelims: TCharSet): Byte;
 var
  Count, I: Word;
 begin
  Count:=0;
  I:=1;

  while I <= Length(S) do
   begin
    while (I <= Length(S)) and (S[I] in WordDelims) do
     Inc(I);

    if I <= Length(S) then
     Inc(Count);

    while (I <= Length(S)) and not (S[I] in WordDelims) do
     Inc(I);
   end;

  WordCount:=Count;
 end;


function GetAllAfterChar(const S: String; const Spc: Byte; const Ch: Char): String;
 var
  K, L: Byte;
  {$IFDEF DOS}
  Result: String;
  {$ENDIF}
 begin
  Result:='';
  L:=0;

  for K:=1 to Length(S) do
   if S[K] = Ch then
    begin
     Inc(L);

     if L >= Spc then
      begin
       Result:=Copy(S, K + 1, Length(S));

       Break;
      end;
    end;

  {$IFDEF DOS}
  GetAllAfterChar:=Result;
  {$ENDIF}
 end;

function GetAllAfterSpace(const S: String; const Spc: Byte): String;
 begin
  GetAllAfterSpace:=GetAllAfterChar(S, Spc, ' ');
 end;


function Replace(S: String; const A, B: String): String;
 begin
  ReplaceEx(S, A, B);

  Replace:=S;
 end;

procedure ReplaceChar(var S: String; const Source, Dest: Char);
 var
  K: Byte;
 begin
  for K:=1 to Length(S) do
   if S[K] = Source then
    S[K]:=Dest;
 end;

procedure ReplaceEx(var S: String; A: String; const B: String);
 var
  K, L: Byte;
 begin
  StUpcaseEx(A);

  Replaced:=False;

  K:=Pos(A, StUpcase(S));

  while K <> 0 do
   begin
    Replaced:=True;

    Delete(S, K, Length(A));

    Insert(B, S, K);

    L:=K + Length(B);

    K:=Pos(A, StUpcase(Copy(S, L, 255)));

    if K <> 0 then
     begin
      Dec(K);

      Inc(K, L);
     end;
   end;
 end;


procedure FixTabs(var S: String);
 var
  O: String;
  K, L, M: Byte;
 begin
  if Pos(#9, S) = 0 then
   Exit;

  O:=S;

  S:='';

  M:=0;

  for K:=1 to Length(O) do
   case O[K] of
    #9:
     begin
      L:=8 - (M and 7);

      Inc(M, L);

      while L <> 0 do
       begin
        S:=Concat(S, ' ');

        Dec(L);
       end;
     end;
   else
    S:=Concat(S, O[K]);

    Inc(M);
   end;
 end;

procedure RepackString(var S: String; const Delims: TCharSet; const Divider: String);
 var
  R: String;
  K: Integer;
 begin
  R:=ExtractWord(1, S, Delims);

  for K:=2 to WordCount(S, Delims) do
   R:=Concat(R, Divider, ExtractWord(K, S, Delims));

  S:=R;
 end;

function nlz(const S: String): String;
 var
  K: Byte;
 begin
  K:=1;

  while (K < Length(S)) and (S[K] = '0') do
   Inc(K);

  nlz:=Copy(S, K, Length(S) - K + 1);
 end;

{ pstrings }

function GetPString(const S: Pointer): String;
 {$IFDEF CODE32}
 begin
  GetPStringEx(S, Result);
 end;
 {$ELSE}
 type
  PString = ^String;
 begin
  if S = nil then
   GetPString:=''
  else
   GetPString:=PString(S)^;
 end;
 {$ENDIF}

procedure GetPStringEx(const S: Pointer; var R: String);
 type
  PString = ^String;
 begin
  if S = nil then
   R:=''
  else
   R:=PString(S)^;
 end;

{ numbers: hex }

function HexB(const B: Byte): String;
 begin
  HexB:=Digits[B shr 4] + Digits[B and $F];
 end;

function HexT(const W: Word): String;
 begin
  HexT:=Digits[Hi(W) and $F] +
        Digits[Lo(W) shr 4] +
        Digits[Lo(W) and $F];
 end;

function HexW(const W: Word): String;
 begin
  HexW:=Digits[Hi(W) shr 4] +
        Digits[Hi(W) and $F] +
        Digits[Lo(W) shr 4] +
        Digits[Lo(W) and $F];
 end;

function HexL(const L: Longint): String;
 begin
  with Long(L) do
   HexL:=HexW(HighWord) + HexW(LowWord);
 end;

function HexPtr(const P: Pointer): String;
 begin
  with Long(P) do
   HexPtr:=HexW(LowWord) + ':' + HexW(HighWord);
 end;

{ numbers to strings }

function MakeFmt(const R: String): String;
 var
  K, L: Byte;
  Minus: Boolean;
  {$IFDEF DOS}
  Result: String;
  {$ENDIF}
 begin
  Result:='';

  L:=0;

  for K:=Length(R) downto 1 do
   begin
    Result:=R[K] + Result;

    Inc(L);

    if L = 3 then
     begin
      Result:=',' + Result;

      L:=0;
     end;
   end;

  Minus:=Copy(Result, 1, 1) = '-';

  if Minus then
   Delete(Result, 1, 1);

  while Copy(Result, 1, 1) = ',' do
   Delete(Result, 1, 1);

  if Minus then
   Result:='-' + Result;

  {$IFDEF DOS}
  MakeFmt:=Result;
  {$ENDIF}
 end;

function Long2Str(const L: Longint): String;
 {$IFDEF DOS}
 var
  Result: String;
 {$ENDIF}
 begin
  Str(L, Result);

  {$IFDEF DOS}
  Long2Str:=Result;
  {$ENDIF}
 end;

function Long2StrFmt(const L: Longint): String;
 begin
  Long2StrFmt:=MakeFmt(Long2Str(L));
 end;

function Real2Str(const R: Real; const Width, Decimals: Byte): String;
 {$IFDEF DOS}
 var
  Result: String;
 {$ENDIF}
 begin
  Str(R:Width:Decimals, Result);

  {$IFDEF DOS}
  Real2Str:=Result;
  {$ENDIF}
 end;


function lz(const Number: Longint): String;
 {$IFDEF DOS}
 var
  Result: String;
 {$ENDIF}
 begin
  Str(Number, Result);

  if Length(Result) = 1 then
   Result:=Concat('0', Result);

  {$IFDEF DOS}
  lz:=Result;
  {$ENDIF}
 end;

{ strings to chars/numbers }

function Str2Char(const S: String): Char;
 begin
  if Length(S) = 0 then
   Str2Char:=#0
  else
   Str2Char:=S[1];
 end;

function Str2Number(const S: String): Boolean;
 var
  X: Longint;
  C: xInteger;
 begin
  Val(S, X, C);

  Str2Number:=C = 0;
 end;

function Str2Byte(const S: String; var A: Byte): Boolean;
 begin
  if S = '' then
   begin
    A:=0;

    Str2Byte:=True;
   end
  else
   begin
    Val(S, A, ValL);

    Str2Byte:=ValL = 0;
   end;
 end;

function Str2Integer(const S: String; var A: Integer): Boolean;
 begin
  if S = '' then
   begin
    A:=0;

    Str2Integer:=True;
   end
  else
   begin
    Val(S, A, ValL);

    Str2Integer:=ValL = 0;
   end;
 end;

function Str2Word(const S: String; var A: Word): Boolean;
 begin
  if S = '' then
   begin
    A:=0;

    Str2Word:=True;
   end
  else
   begin
    Val(S, A, ValL);

    Str2Word:=ValL = 0;
   end;
 end;

function Str2xWord(const S: String; var A: XWord): Boolean;
 begin
  if S = '' then
   begin
    A:=0;

    Str2xWord:=True;
   end
  else
   begin
    Val(S, A, ValL);

    Str2xWord:=ValL = 0;
   end;
 end;

function Str2Longint(const S: String; var A: Longint): Boolean;
 begin
  if S = '' then
   begin
    A:=0;

    Str2Longint:=True;
   end
  else
   begin
    Val(S, A, ValL);

    Str2Longint:=ValL = 0;
   end;
 end;

function Size2KB(const Size: Longint): String;
 {$IFDEF DOS}
 var
  Result: String;
 {$ENDIF}
 begin
  Str((Size / 1024):1:1, Result);

  if Copy(Result, Length(Result) - 1, 2) = '.0' then
   SetLength(Result, Length(Result) - 2);

  Result:=Concat(Result, 'kb');

  {$IFDEF DOS}
  Size2KB:=Result;
  {$ENDIF}
 end;

{ files }

function AddBackSlash(S: String): String;
 begin
  if Length(S) <> 0 then
   if S[Length(S)] <> '\' then
    S:=S + '\';

  AddBackSlash:=S;
 end;

function RemoveBackSlash(S: String): String;
 begin
  if (Copy(S, Length(S) - 2, 2) <> ':\') and (S[Length(S)] = '\') then
   SetLength(S, Length(S) - 1);

  RemoveBackSlash:=S;
 end;

function AddDot(const S: String): String;
 begin
  if Copy(S, Length(S), 1) <> '.' then
   AddDot:=S + '.'
  else
   AddDot:=S;
 end;

function ExistDir(const S: String): Boolean;
 var
  SR: SearchRec;
 begin
  FindFirst(AddBackSlash(S) + '*.*', AnyFile, SR);

  ExistDir:=DosError = 0;

  FindClose(SR);
 end;

function ExistFile(const S: String): Boolean;
 {$IFDEF DELPHI}
 begin
  Result:=FileExists(S);
 end;
 {$ELSE}
 var
  F: File;
  A: xWord;
 begin
  Assign(F, S);

  GetFAttr(F, A);

  ExistFile:=DosError = 0;
 end;
 {$ENDIF}

function FExpand(const S: String): String;
 begin
  {$IFDEF DELPHI}
  Result:=ExpandFileName(S);
  {$ELSE}
  FExpand:=Dos.FExpand(S);
  {$ENDIF}
 end;


function HasExtension(const Name: String; var DotPos: Word): Boolean;
 var
  I: Word;
 begin
  DotPos:=0;

  for I:=Length(Name) downto 1 do
   if (Name[I] = '.') and (DotPos = 0) then
    DotPos:=I;

  HasExtension:=(DotPos > 0) and (Pos('\', Copy(Name, Succ(DotPos), 255)) = 0);
 end;

function ForceExtension(const Name, Ext: String): String;
 var
  DotPos: Word;
 begin
  if HasExtension(Name, DotPos) then
   ForceExtension:=Copy(Name, 1, DotPos) + Ext
  else
   ForceExtension:=Name + '.' + Ext;
 end;

function JustExtension(const Name: String): String;
 var
  DotPos: Word;
 begin
  if HasExtension(Name, DotPos) then
   JustExtension:=Copy(Name, Succ(DotPos), 255)
  else
   JustExtension:='';
 end;

function JustFilename(const PathName: String): String;
 var
  I: Word;
 begin
  I:=Succ(Word(Length(PathName)));

  repeat
   Dec(I);
  until (PathName[I] in DosDelimSet) or (I = 0);

  JustFilename:=Copy(PathName, Succ(I), 255);
 end;

function JustFilenameOnly(const PathName: String): String;
 var
  I: Integer;
  S: String;
 begin
  S:=JustFilename(PathName);

  I:=Length(S);

  if I>0 then 
  begin
   while (I <> 0) and (S[I] <> '.') do
    Dec(I);

   if I <= 1 then
    JustFileNameOnly:=S
   else
    JustFilenameOnly:=Copy(S, 1, I - 1);
  end else JustFileNameOnly:=''; 
 end;

function JustPathname(const PathName: String): String;
 var
  I: Word;
 begin
  I:=Succ(Word(Length(PathName)));

  repeat
   Dec(I);
  until (PathName[I] in DosDelimSet) or (I = 0);

  if I = 0 then
   JustPathname:=''
  else
   if I = 1 then
    JustPathname:=PathName[1]
   else
    if PathName[I] = '\' then
     if PathName[Pred(I)] = ':' then
      JustPathname:=Copy(PathName, 1, I)
     else
      JustPathname:=Copy(PathName, 1, Pred(I))
    else
     JustPathname:=Copy(PathName, 1, I);
 end;


{$IFDEF VIRTUALPASCAL}
function TextSeek(var F: Text; const Target: LongInt): Boolean;
 var
  P: LongInt;
  T: TextRec absolute F;
 begin
  TextSeek:=True;

  SysFileSeek(T.Handle, 0, 1, P);

  Dec(P, T.BufEnd);

  P:=Target - P;

  if (P >= 0) and (P < T.BufEnd) then
   T.BufPos:=P
  else
   begin
    SysFileSeek(T.Handle, Target, 0, P);

    T.BufEnd:=0;
    T.BufPos:=0;
   end;
 end;

function TextFileSize(var F: Text): LongInt;
 var
  T: TextRec absolute F;
  P: Longint;
 begin
  SysFileSeek(T.Handle, 0, 1, P);

  SysFileSeek(T.Handle, 0, 2, Result);

  SysFileSeek(T.Handle, P, 0, P);
 end;

function TextPos(var F: Text): LongInt;
 var
  T: TextRec absolute F;
 begin
  SysFileSeek(T.Handle, 0, 1, Result);

  if T.Mode = fmOutput then
   Inc(Result, T.BufPos)
  else
   if T.BufEnd <> 0 then
    Dec(Result, T.BufEnd - T.BufPos);
 end;
{$ENDIF}

{$IFDEF DELPHI}
function TextSeek(var F: Text; const Target: LongInt): Boolean;
 var
  T: TextRec absolute F;
  P: Longint;
 begin
  TextSeek:=True;

  P:=FileSeek(T.Handle, 0, 1);

  Dec(P, T.BufEnd);

  P:=Target - P;

  if (P >= 0) and (P < T.BufEnd) then
   T.BufPos:=P
  else
   begin
    FileSeek(T.Handle, Target, 0);

    T.BufEnd:=0;
    T.BufPos:=0;
   end;
 end;

function TextFileSize(var F: Text): LongInt;
 var
  T: TextRec absolute F;
  P: Longint;
 begin
  P:=FileSeek(T.Handle, 0, 1);

  Result:=FileSeek(T.Handle, 0, 2);

  FileSeek(T.Handle, P, 0);
 end;

function TextPos(var F: Text): LongInt;
 var
  T: TextRec absolute F;
 begin
  Result:=FileSeek(T.Handle, 0, 1);

  if T.Mode = fmOutput then
   Inc(Result, T.BufPos)
  else
   if T.BufEnd <> 0 then
    Dec(Result, T.BufEnd - T.BufPos);
 end;
{$ENDIF}

{$IFDEF DOS}
{ The following part of code has been cut from
  Turbo Professional 5.21 (c) by TurboPower Software, 1987, 1992. }

function TextSeek(var F: Text; const Target: LongInt): Boolean;
 var
  T: Long absolute Target;
  Pos: LongInt;
  Regs: Registers;
 begin
  TextSeek:=False;

  with Regs, TText(F) do
   begin
    if Mode <> FMInput then
     Exit;

    AX:=$4201;
    BX:=Handle;
    CX:=0;
    DX:=0;
    MsDos(Regs);

    if Odd(Flags) then
     Exit;

    Long(Pos).HighWord := DX;
    Long(Pos).LowWord := AX;

    Dec(Pos, BufEnd);

    Pos:=Target - Pos;

    if (Pos >= 0) and (Pos < BufEnd) then
     BufPos:=Pos
    else
     begin
      AX:=$4200;
      BX:=Handle;
      CX:=T.HighWord;
      DX:=T.LowWord;

      MsDos(Regs);

      if Odd(Flags) then
       Exit;

      BufEnd:=0;
      BufPos:=0;
     end;
   end;

  TextSeek:=True;
 end;

function TextFileSize(var F: Text) : LongInt;
 var
  OldHi, OldLow: Integer;
  Regs: Registers;
 begin
  with Regs, TText(F) do
   begin
    if Mode = FMClosed then
     begin
      TextFileSize:=-1;

      Exit;
     end;

    AX:=$4201;
    BX:=Handle;
    CX:=0;
    DX:=0;
    MsDos(Regs);

    if Odd(Flags) then
     begin
      TextFileSize:=-1;

      Exit;
     end;

    OldHi:=DX;
    OldLow:=AX;
    AX:=$4202;
    BX:=Handle;
    CX:=0;
    DX:=0;
    MsDos(Regs);

    if Odd(Flags) then
     begin
      TextFileSize:=-1;

      Exit;
     end;

    TextFileSize:=Longint(DX) shl 16 + AX;

    AX:=$4200;
    BX:=Handle;
    CX:=OldHi;
    DX:=OldLow;
    MsDos(Regs);

    if Odd(Flags) then
     TextFileSize:=-1;
   end;
 end;

function TextPos(var F: Text): LongInt;
 var
  Position: LongInt;
  Regs: Registers;
 begin
  with Regs, TText(F) do
   begin
    if Mode = FMClosed then
     begin
      TextPos := -1;

      Exit;
     end;

    AX:=$4201;
    BX:=Handle;
    CX:=0;
    DX:=0;
    MsDos(Regs);

    if Odd(Flags) then
     begin
      TextPos:=-1;

      Exit;
     end;

    Long(Position).HighWord := DX;
    Long(Position).LowWord := AX;

    if Mode = FMOutput then
     Inc(Position, BufPos)
    else
     if BufEnd <> 0 then
      Dec(Position, BufEnd - BufPos);

    TextPos:=Position;
   end;
 end;
{$ENDIF}


function FileLocked(const FName: String): Boolean;
 var
  AFileMode: Integer;
  F: File;
 begin
  if not ExistFile(FName) then
   begin
    FileLocked:=False;

    Exit;
   end;

  AFileMode:=FileMode;

  FileMode:=$12;

  if IOResult <> 0 then;

  Assign(F, FName);
  Reset(F);

  if IOResult = 0 then
   begin
    FileLocked:=False;

    Close(F);
   end
  else
   FileLocked:=True;

  if IOResult <> 0 then;

  FileMode:=AFileMode;
 end;

function EraseFile(const FName: String): Boolean;
 var
  F: Text;
 begin
  if IOResult <> 0 then;

  Assign(F, FName);
  Erase(F);

  EraseFile:=IOResult = 0;
 end;

function TouchFile(const FName: String): Boolean;
 var
  F: Text;
 begin
  if IOResult <> 0 then;

  Assign(F, FName);
  Rewrite(F);

  if IOResult = 0 then
   begin
    Close(F);

    TouchFile:=True;
   end
  else
   TouchFile:=False;
 end;

function RenameFile(const AFName, BFName: String): Boolean;
 var
  F: Text;
 begin
  if IOResult <> 0 then;

  Assign(F, AFName);
  Rename(F, BFName);

  RenameFile:=IOResult = 0;
 end;

function RenameFileEx(const AFName, BFName: String; var rc: Longint): Boolean;
 var
  F: Text;
 begin
  if IOResult <> 0 then;

  Assign(F, AFName);
  Rename(F, BFName);

  rc:=IOResult;

  RenameFileEx:=rc = 0;
 end;

function EmptyDirectory(const Path: String): Boolean;
 var
  SR: SearchRec;
 begin
  FindFirst(AddBackSlash(Path) + '*.*', AnyFile, SR);

  EmptyDirectory:=True;

  while DosError = 0 do
   begin
    if (SR.Name <> '.') and (SR.Name <> '..') then
     begin
      EmptyDirectory:=False;

      Break;
     end;

    FindNext(SR);
   end;

  FindClose(SR);
 end;

function EmptyDirectoryEx(const Path: String; const OnlyFiles: Boolean): Boolean;
 var
  SR: SearchRec;
 begin
  FindFirst(AddBackSlash(Path) + '*.*', AnyFile, SR);

  EmptyDirectoryEx:=True;

  while DosError = 0 do
   begin
    if (SR.Name <> '.') and (SR.Name <> '..') and (not OnlyFiles or (SR.Attr and Directory = 0)) then
     begin
      EmptyDirectoryEx:=False;

      Break;
     end;

    FindNext(SR);
   end;

  FindClose(SR);
 end;


function DistortFileName(var FName: String; const DistortExtension: Boolean): Boolean;
 var
  K: Word;
 begin
  if DistortExtension then
   K:=Length(FName)
  else
   if HasExtension(FName, K) then
    begin
     if K > 0 then
      Dec(K);

     if (K <= 0) or (FName[K] in [':', '\']) then
      begin
       DistortFileName:=False;

       Exit;
      end;
    end
   else
    K:=Length(FName);

  repeat
   if not ExistFile(FName) then
    begin
     DistortFileName:=True;

     Exit;
    end;

   FName[K]:=Locase(FName[K]);

   Inc(FName[K]);

   if (FName[K] > '9') and (FName[K] < 'a') then
    FName[K]:='a';

   if FName[K] < '0' then
    FName[K]:='0';

   if FName[K] > 'z' then
    begin
     FName[K]:='z';

     Dec(K);

     if K < 1 then
      Break;
    end;

   if FName[K] = '.' then
    begin
     Dec(K);

     if K < 1 then
      Break;
    end;

   if FName[K] in ['\', ':'] then
    Break;
  until False;

  DistortFileName:=False;
 end;

function DistortFileExtension(var FName: String): Boolean;
 var
  K: Word;
 begin
  DistortFileExtension:=False;

  if HasExtension(FName, K) and (K <> Length(FName)) then
   K:=Length(FName)
  else
   Exit;

  repeat
   if not ExistFile(FName) then
    begin
     DistortFileExtension:=True;

     Exit;
    end;

   FName[K]:=Locase(FName[K]);

   Inc(FName[K]);

   if (FName[K] > '9') and (FName[K] < 'a') then
    FName[K]:='a';

   if FName[K] < '0' then
    FName[K]:='0';

   if FName[K] > 'z' then
    begin
     FName[K]:='z';

     Dec(K);

     if K < 1 then
      Break;
    end;

   if FName[K] in ['\', ':', '.'] then
    Break;
  until False;
 end;

function DistortFileExtensionLastLetter(var FName: String; Force: Boolean): Boolean;
 var
  K: Word;
 begin
  DistortFileExtensionLastLetter:=False;

  if HasExtension(FName, K) and (K <> Length(FName)) then
   K:=Length(FName)
  else
   Exit;

  repeat
   if not Force and not ExistFile(FName) then
    begin
     DistortFileExtensionLastLetter:=True;

     Exit;
    end;

   Force:=False;

   FName[K]:=Locase(FName[K]);

   Inc(FName[K]);

   if (FName[K] > '9') and (FName[K] < 'a') then
    FName[K]:='a';

   if FName[K] < '0' then
    FName[K]:='0';

   if FName[K] > 'z' then
    begin
     FName[K]:='z';

     Break;
    end;
  until False;
 end;

{ time & date }

function Clock: Longint;
 {$IFDEF VIRTUALPASCAL}
 begin
  Clock:=SysSysMsCount;
 end;
 {$ENDIF}
 {$IFDEF DELPHI}
 begin
  Clock:=GetTickCount;
 end;
 {$ENDIF}
 {$IFDEF DOS}
 assembler;
  asm
             push    ds              { save caller's data segment }
             mov     ds, seg0040     {  access ticker counter }
             mov     bx, 6ch         { offset of ticker counter in segm.}
             mov     dx, 43h         { timer chip control port }
             mov     al, 4           { freeze timer 0 }
             pushf                   { save caller's int flag setting }
             cli                     { make reading counter an atomic operation}
             mov     di, ds:[bx]     { read bios ticker counter }
             mov     cx, ds:[bx+2]
             sti                     { enable update of ticker counter }
             out     dx, al          { latch timer 0 }
             cli                     { make reading counter an atomic operation}
             mov     si, ds:[bx]     { read bios ticker counter }
             mov     bx, ds:[bx+2]
             in      al, 40h         { read latched timer 0 lo-byte }
             mov     ah, al          { save lo-byte }
             in      al, 40h         { read latched timer 0 hi-byte }
             popf                    { restore caller's int flag }
             xchg    al, ah          { correct order of hi and lo }
             cmp     di, si          { ticker counter updated ? }
             je      @no_update      { no }
             or      ax, ax          { update before timer freeze ? }
             jns     @no_update      { no }
             mov     di, si          { use second }
             mov     cx, bx          {  ticker counter }
@no_update:  not     ax              { counter counts down }
             mov     bx, 36edh       { load multiplier }
             mul     bx              { w1 * m }
             mov     si, dx          { save w1 * m (hi) }
             mov     ax, bx          { get m }
             mul     di              { w2 * m }
             xchg    bx, ax          { ax = m, bx = w2 * m (lo) }
             mov     di, dx          { di = w2 * m (hi) }
             add     bx, si          { accumulate }
             adc     di, 0           {  result }
             xor     si, si          { load zero }
             mul     cx              { w3 * m }
             add     ax, di          { accumulate }
             adc     dx, si          {  result in dx:ax:bx }
             mov     dh, dl          { move result }
             mov     dl, ah          {  from dl:ax:bx }
             mov     ah, al          {   to }
             mov     al, bh          {    dx:ax:bh }
             mov     di, dx          { save result }
             mov     cx, ax          {  in di:cx }
             mov     ax, 25110       { calculate correction }
             mul     dx              {  factor }
             sub     cx, dx          { subtract correction }
             sbb     di, si          {  factor }
             xchg    ax, cx          { result back }
             mov     dx, di          {  to dx:ax }
             pop     ds              { restore caller's data segment }
  end;
 {$ENDIF}

procedure Wait(const ms: Longint);
 {$IFDEF VIRTUALPASCAL}
 begin
  SysCtrlSleep(ms);
 end;
 {$ENDIF}
 {$IFDEF DELPHI}
 begin
  Sleep(ms);
 end;
 {$ENDIF}
 {$IFDEF DOS}
 var
  Anchor1, Anchor2, Current: Longint;
 begin
  Anchor2:=Clock;
  Anchor1:=Anchor2 + ms;

  repeat
   Current:=Clock;
  until (Current > Anchor1) or (Current < Anchor2);
 end;
 {$ENDIF}

function DayOfWeek(const Year, Month, Day: Longint): Word;
 var
  Temp1, Temp2: Longint;
 begin
  Temp1:=Month + 10;
  Temp2:=Year + (Month - 14) div 12;
  DayOfWeek:=((13 *  (Temp1 - Temp1 div 13 * 12) - 1) div 5 +
              Day + 77 + 5 * (Temp2 - Temp2 div 100 * 100) div 4 +
              Temp2 div 400 - Temp2 div 100 * 2) mod 7;
 end;

{ wildcards }

{
  CheckWildcard (WildEqu)
  (c) by Vladimir S. Lokhov <vsl@tula.net> <2:5022/18.14>, 1994-2000.
}

type
 TCheckWildcardStack = packed record
  Src, Mask: Byte;
 end;

function CheckWildcard(const Src, Mask: String): Boolean;
 var
  Stack: array[1..128] of TCheckWildcardStack;
  StackPointer,
  SrcPosition, MaskPosition,
  SrcLength, MaskLength: Byte;
 begin
  CheckWildcard:=False;

  if (Mask = '') and (Src <> '') then
   Exit;

  MaskLength:=Length(Mask);
  SrcLength:=Length(Src);

  if Mask[MaskLength] <> '*' then
   while (MaskLength > 1) and (SrcLength > 1) do
    begin
     if (Mask[MaskLength] = '*') or (Mask[MaskLength] = '?') then
      Break;

     if Mask[MaskLength] <> Src[SrcLength] then
      Exit;

     Dec(MaskLength);
     Dec(SrcLength);
    end;

  if Mask[MaskLength] = '*' then
   while (Mask[MaskLength - 1] = '*') and (MaskLength > 1) do
    Dec(MaskLength);

  StackPointer:=0;

  SrcPosition:=1;
  MaskPosition:=1;

  while (SrcPosition <= SrcLength) and (MaskPosition <= MaskLength) do
   begin
    case Mask[MaskPosition] of
     '?':
      begin
       Inc(SrcPosition);
       Inc(MaskPosition);
      end;
     '*':
      begin
       if (MaskPosition = 1) or (Mask[MaskPosition - 1] <> '*') then
        Inc(StackPointer);

       Stack[StackPointer].Mask:=MaskPosition;

       Inc(MaskPosition);

       if MaskPosition <= MaskLength then
        if (Mask[MaskPosition] <> '?') and (Mask[MaskPosition] <> '*') then
         while (SrcPosition <= Length(Src)) and (Src[SrcPosition] <> Mask[MaskPosition]) do
          Inc(SrcPosition);

       Stack[StackPointer].Src:=SrcPosition + 1;
      end;
    else
     if Src[SrcPosition] = Mask[MaskPosition] then
      begin
       Inc(SrcPosition);
       Inc(MaskPosition);
      end
     else
      begin
       if StackPointer = 0 then
        Exit;

       SrcPosition:=Stack[StackPointer].Src;
       MaskPosition:=Stack[StackPointer].Mask;

       Dec(StackPointer)
      end;
    end;

    while not ((SrcPosition <= SrcLength) xor (MaskPosition > MaskLength)) do
     begin
      if (MaskPosition >= MaskLength) and (Mask[MaskLength] = '*') then
       Break;

      if StackPointer = 0 then
       Exit;

      SrcPosition:=Stack[StackPointer].Src;
      MaskPosition:=Stack[StackPointer].Mask;

      Dec(StackPointer)
     end;
   end;

  CheckWildcard:=True;
 end;

function IsWildcard(const Mask: String): Boolean;
 begin
  IsWildcard:=(Pos('*', Mask) > 0) or (Pos('?', Mask) > 0);
 end;

{ misc }

function GetBinkDateTime: String;
 var
  Year, Month, Day, Dow, Hour, Min, Sec, Sec100: xWord;
 begin
  GetDate(Year, Month, Day, Dow);
  GetTime(Hour, Min, Sec, Sec100);

  GetBinkDateTime:=LeftPadCh(Long2Str(Day), '0', 2) + ' ' +
                   Months[Month] + ' ' +
                   LeftPadCh(Long2Str(Hour), '0', 2) + ':' +
                   LeftPadCh(Long2Str(Min), '0', 2) + ':' +
                   LeftPadCh(Long2Str(Sec), '0', 2);
 end;

{ multiplatform stuff }

{$IFNDEF DELPHI}
function GetAttr(const FName: String): Longint;
 var
  F: File;
  K: XWord;
 begin
  Assign(F, FName);

  GetFAttr(F, K);

  GetAttr:=K;
 end;

function GetFileDate(const FName: String): Longint;
 var
  SR: SearchRec;
 begin
  FindFirst(FName, AnyFile, SR);

  if DosError <> 0 then
   GetFileDate:=-1
  else
   GetFileDate:=SR.Time;

  FindClose(SR);
 end;

function GetFileSize(const S: String): Longint;
 var
  SR: SearchRec;
 begin
  FindFirst(S, AnyFile, SR);

  if DosError <> 0 then
   GetFileSize:=-1
  else
   GetFileSize:=SR.Size;

  FindClose(SR);
 end;

function GetStamp(const FName: String): Longint;
 var
  F: File;
  K: Longint;
 begin
  if IOResult <> 0 then;

  Assign(F, FName);
  Reset(F);

  if IOResult <> 0 then
   begin
    GetStamp:=-1;

    Exit;
   end;

  GetFTime(F, K);

  Close(F);

  GetStamp:=K;

  if IOResult <> 0 then;
 end;

procedure SetAttr(const FName: String; K: Longint);
 var
  F: File;
 begin
  Assign(F, FName);

  SetFAttr(F, K);

  if IOResult <> 0 then;
 end;

procedure SetStamp(const FName: String; K: Longint);
 var
  F: File;
 begin
  if IOResult <> 0 then;

  Assign(F, FName);
  Reset(F);

  if IOResult <> 0 then
   Exit;

  SetFTime(F, K);

  Close(F);

  if IOResult <> 0 then;
 end;

function StackOverflow: boolean;
 begin
  StackOverflow:=SPtr < $1000;
 end;
{$ENDIF}


{$IFDEF DELPHI}
procedure GetDate(var Year, Month, Day, Dow: Word);
 begin
  DecodeDate(Date, Year, Month, Day);

  Dow:=DayOfWeek(Year, Month, Day);
 end;

procedure GetTime(var Hour, Min, Sec, Sec100: Word);
 begin
  DecodeTime(Time, Hour, Min, Sec, Sec100);

  Sec100:=Sec100 div 10;
 end;

procedure FindFirst(const Path: String; const Attrs: Integer; var SR: SearchRec);
 begin
  DosError:=SysUtils.FindFirst(Path, Attrs, SR);
 end;

procedure FindNext(var SR: SearchRec);
 begin
  DosError:=SysUtils.FindNext(SR);
 end;

procedure FindClose(var SR: SearchRec);
 begin
  SysUtils.FindClose(SR);
 end;
{$ENDIF}


{$IFDEF DOS}
procedure FindClose(var SR: SearchRec);
 begin
 end;

procedure SetLength(var S: String; const NewLength: Byte);
 begin
  Byte(S[0]):=NewLength;
 end;
{$ENDIF}


function _s(const Value: Longint): String;
 begin
  if Value = 1 then
   _s:=''
  else
   _s:='s';
 end;

function _nz(const Value: Longint; const S: String): String;
 begin
  if Value = 0 then
   _nz:=''
  else
   _nz:=S;
 end;


function NumberWidth(const Value: Longint): Byte;
 begin
  if Value < 0 then
   NumberWidth:=2 + Trunc(Ln(-Value + 1)/Ln(10))
  else
   NumberWidth:=Trunc(Ln(Value + 1)/Ln(10)) + 1;
 end;


{$IFDEF VIRTUALPASCAL}
function CompareLongint(const L1, L2: Longint): xInteger; assembler; {&USES ebx,ecx}
 asm
  xor eax, eax
  mov ebx, L1
  mov ecx, L2
  cmp ebx, ecx
  jle @@2
  inc eax
  jmp @@quit
@@2:
  jge @@Quit
  dec eax
@@Quit:
 end;
{$ELSE}
function CompareLongint(const L1, L2: Longint): xInteger;
 begin
  if L1 < L2 then CompareLongint:=-1 else
  if L1 > L2 then CompareLongint:=1 else
   CompareLongint:=0;
 end;
{$ENDIF}

{ FidoNet stuff :-) }

Function GetPktDateTime: String;
 Var
   Day, Month, Year, Hour, Min, Sec: Word;
 Begin
   iWannaTime (Hour, Min, Sec);
   iWannaDate (Day, Month, Year);
   GetPktDateTime := LeftPadCh (Long2Str (Day), '0', 2) + ' ' + Copy (Months [Month], 1, 3) + ' ' +
     Copy (Long2Str (Year), 3, 2) + '  ' +
   LeftPadCh (Long2Str (Hour), '0', 2) + ':' + LeftPadCh (Long2Str (Min), '0', 2) + ':' + LeftPadCh (Long2Str (Sec), '0', 2);
 End;

Function GetPktDateTimeCustom (Day, Month, Year, Hour, Min, Sec: Word): String;
 Begin
   GetPktDateTimeCustom := LeftPadCh (Long2Str (Day), '0', 2) + ' ' + Copy (Months [Month], 1, 3) + ' ' +
     Copy (Long2Str (Year), 3, 2) + '  ' +
   LeftPadCh (Long2Str (Hour), '0', 2) + ':' + LeftPadCh (Long2Str (Min), '0', 2) + ':' + LeftPadCh (Long2Str (Sec), '0', 2);
 End;

Procedure ParsePktDateTime (S: String; Var Day, Month, Year, Hour, Min, Sec, Dow: XWord);
 Const
   MonthsU: Array [1..12] Of String [3] = ('JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC');
 Var
   K: Byte;
 Begin
   StUpcaseEx (S);
   Str2XWord (ExtractWord (1, S, [' ', ':'] ), Day);
   Month := 0;
   For K := 1 To 12 Do
     If Copy (S, 4, 3) = MonthsU [K] Then Month := K;
   Str2XWord (ExtractWord (3, S, [' ', ':'] ), Year); If Year < 81 Then Inc (Year, 2000) Else Inc (Year, 1900);
   Str2XWord (ExtractWord (4, S, [' ', ':'] ), Hour);
   Str2XWord (ExtractWord (5, S, [' ', ':'] ), Min);
   Str2XWord (ExtractWord (6, S, [' ', ':'] ), Sec);
   Dow := DayOfWeek (Year, Month, Day);
 End;

Procedure IWannaDate (Var D, M, Y: Word);
{.$IFnDEF VIRTUALPASCAL
 begin
  DecodeDate(Date, Y, M, D);
 end;
$ELSE}
 Var
   aY, aM, aD, aT: xWord;
 Begin
   GetDate (aY, aM, aD, aT);
   D := aD;
   M := aM;
   Y := aY;
 End;
{.$ENDIF}

Procedure IWannaTime (Var H, M, S: Word);
{.$IFnDEF VIRTUALPASCAL
 var
  T: Word;
 begin
  DecodeTime(Time, H, M, S, T);
 end;
$ELSE}
 Var
   AH, aM, _aS, _aT: xWord;
 Begin
   GetTime (AH, aM, _aS, _aT);
   H := AH;
   M := aM;
   S := _aS;
 End;
{.$ENDIF}

Function TimeFix: LongInt;
 Var
   DT: DateTime;
   L: LongInt;
   Hour, Min, Sec, Day, Month, Year: Word;
 Begin
   IWannaTime (Hour, Min, Sec);
   IWannaDate (Day, Month, Year);
   DT. Hour := Hour;
   DT. Min := Min;
   DT. Sec := Sec;
   DT. Day := Day;
   DT. Month := Month;
   DT. Year := Year;
   PackTime (DT, L);
   TimeFix := L;
 End;

Procedure TimeDif (L: LongInt; Var DT: DateTime);
 Begin
   UnpackTime (L, DT);
   With DT Do
     If Year >= 1980 Then Dec (Year, 1980);
 End;

end.
