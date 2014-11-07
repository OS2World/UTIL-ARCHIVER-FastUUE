{$I-,F+}
unit Types;

{
 FASTUUE COMMON UNIT
 (c) by sergey korowkin, 1998-99.
}

interface
uses
{$IFDEF VIRTUALPASCAL}
     Strings, VpSysLow,
{$IFDEF WIN32}
     Windows,
{$ENDIF}
{$IFDEF OS2}
     OS2Base,
{$ENDIF}
{$ENDIF}
     Wizard, Dos;

{$IFNDEF VIRTUALPASCAL}
 {$DEFINE DOS}
{$ELSE}
 {$H-}
{$ENDIF}

type
 PAddress = ^TAddress;
 TAddress = record
  Zone, Net, Node, Point: Longint;
 end;

 PDate = ^TDate;
 TDate = record
  Day, Month, Year: word;
 end;

const
{$IFDEF DPMI}
 OldExitProc: Pointer = nil;
{$ENDIF}
 RTEFile = '\$fastuue.err';

type
 PScreen = ^TScreen;
 TScreen = array[1..25, 1..80] of record Ch: Char; Attr: Byte end;

const
{$IFDEF VIRTUALPASCAL}
 MaxCollection                          = 1024 * 1024;
{$ELSE}
 MaxCollection                          = 16300;
{$ENDIF}
 AlignCollection                        = 1024;
 BlockSize: Longint                     = 1024 * 4;

 DateDivider                            = ['/'];
 DateCharacter                          = '/';

{$IFDEF VIRTUALPASCAL}
 stCreate    = $0100;
 stOpenRead  = $0000;
 stOpenWrite = $0001;
 stOpen      = $0002;
{$ELSE}
 stCreate    = $3C00;
 stOpenRead  = $3D00;
 stOpenWrite = $3D01;
 stOpen      = $3D02;
{$ENDIF}

 stOk         =  0;                     { No error }
 stError      = -1;                     { Access error }
 stInitError  = -2;                     { Cannot initialize stream }
 stReadError  = -3;                     { Read beyond end of stream }
 stWriteError = -4;                     { Cannot expand stream }
 stStrError   = -5;                     { String reading error }

 coIndexError = -1;                     { Index out of range }
 coOverflow   = -2;                     { Overflow }

const
 StreamError                  : Pointer = Nil;

type
{$IFDEF VIRTUALPASCAL}
 OSWord = Longint;
 OSInteger = Longint;
{$ELSE}
 OSWord = Word;
 OSInteger = Integer;
{$ENDIF}

 PObject = ^TObject;
 TObject = object
  constructor Init;
  procedure Free;
  destructor Done; virtual;
 end;

 PCollectionData = ^TCollectionData;
 TCollectionData = Array[1..MaxCollection] of Pointer;

 PCollection = ^TCollection;
 TSortHandler = function(C: PCollection; Key1, Key2: Longint): Longint;

 PItemList = ^TItemList;
 TItemList = array[1..MaxCollection] of Pointer;

 TCollection = object(TObject)
 public
  Data: PCollectionData;
  DataSize: Longint;
  Count: Longint;
  constructor Init;
  procedure Insert(Item: Pointer); virtual;
  procedure Delete(Item: Pointer); virtual;
  procedure Free(Item: Pointer); virtual;
  procedure AtFree(N: Longint); virtual;
  procedure AtInsert(N: Longint; Item: Pointer); virtual;
  procedure AtDelete(N: Longint); virtual;
  procedure DeleteAll; virtual;
  procedure FreeAll; virtual;
  function At(Item: Longint): Pointer; virtual;
  function IndexOf(Item: Pointer): Longint; virtual;
  procedure FreeItem(Item: Pointer); virtual;
  procedure Sort(Handler: TSortHandler); virtual;
  procedure AddMoreItems; virtual;
  destructor Done; virtual;
 end;

 PStrings = ^TStrings;
 TStrings = object(TCollection)
  procedure FreeItem(Item: Pointer); virtual;
 end;

 PStream = ^TStream;
 TStream = object(TObject)
 public
  Status: Integer;
  ErrorInfo: Integer;
  constructor Init;
  procedure Error(Code, Info: Integer); virtual;
  procedure Flush; virtual;
  function GetPos: Longint; virtual;
  function GetSize: Longint; virtual;
  procedure Read(var Buf; Count: OSWord); virtual;
  function ReadStr: String; virtual;
  procedure Reset;
  procedure Seek(Pos: Longint); virtual;
  procedure Truncate; virtual;
  procedure Write(var Buf; Count: OSWord); virtual;
  procedure WriteStr(S: String); virtual;
  procedure CopyFrom(var S: TStream; Count: Longint); virtual;
 end;

 PDosStream = ^TDosStream;
 TDosStream = object(TStream)
 public
  Handle: OSInteger;
  constructor Init(FileName: String; Mode: OSWord);
  destructor Done; virtual;
  function GetPos: Longint; virtual;
  function GetSize: Longint; virtual;
  procedure Read(var Buf; Count: OSWord); virtual;
  procedure Seek(Pos: Longint); virtual;
  procedure Truncate; virtual;
  procedure Write(var Buf; Count: OSWord); virtual;
 end;

 PBufStream = ^TBufStream;
 TBufStream = object(TDosStream)
 public
{$IFNDEF VIRTUALPASCAL}
  Buffer: Pointer;
  BufSize: OSWord;
  BufPtr: OSWord;
  BufEnd: OSWord;
{$ENDIF}
  constructor Init(FileName: String; Mode, Size: OSWord);
{$IFNDEF VIRTUALPASCAL}
  destructor Done; virtual;
  procedure Flush; virtual;
  function GetPos: Longint; virtual;
  function GetSize: Longint; virtual;
  procedure Read(var Buf; Count: OSWord); virtual;
  procedure Seek(Pos: Longint); virtual;
  procedure Truncate; virtual;
  procedure Write(var Buf; Count: OSWord); virtual;
{$ENDIF}
 end;

 PString = ^String;

 PRamBuffer = ^TRamBuffer;
 TRamBuffer = array[0..65521] of byte;

 PRamBlock = ^TRamBlock;
 TRamBlock = record
  Buffer: PRamBuffer;
  Size: Longint;
  Next: PRamBlock;
 end;

 PMemoryStream = ^TMemoryStream;
 TMemoryStream = object(TStream)
  First: PRamBlock;
  CurPos, CurSize: Longint;
  constructor Init;
  destructor Done; virtual;
  function GetPos: Longint; virtual;
  function GetSize: Longint; virtual;
  procedure Read(var Buf; Count: OSWord); virtual;
  procedure Seek(Pos: Longint); virtual;
  procedure Truncate; virtual;
  procedure Write(var Buf; Count: OSWord); virtual;
  procedure CopyFrom(var S: TStream; Count: Longint); virtual;
  procedure SetSize(NewSize: Longint);
 private
  procedure GetPosEx(Position: Longint; var Block: PRamBlock; var Offset, Remain: Longint);
 end;

function NewStr(const S: String): PString;
procedure DisposeStr(S: PString);
function Version2Str(L: Longint): String;
function Address2Str(const A: TAddress): String;
function Address2StrTrim(const A: TAddress): String;
function Address2StrPointLess(const A: TAddress): String;
procedure Str2Address(S: String; var A: TAddress);
procedure ParseDate(S: String; var Date: TDate);
function Date2Str(const D: TDate): String;
function ValidDate(const D: TDate): Boolean;
function InDate(const D1, D2: TDate; const Day, Month, Year: Word): boolean;
procedure ClearAddress(var A: TAddress);

implementation
uses Consts_, Video;

{$I FastUUE.Inc}

constructor TObject.Init;
 type
  Image = record
   Link: OSWord;
   Data: record end;
  end;
 begin
  FillChar(Image(Self).Data, SizeOf(Self) - SizeOf(TObject), 0);
 end;

procedure TObject.Free;
 begin
  Dispose(PObject(@Self), Done);
 end;

destructor TObject.Done;
 begin
 end;

procedure TStrings.FreeItem;
 begin
  if Item <> Nil then DisposeStr(Item);
 end;

function NewStr(const S: String): PString;
 var
  P: PString;
 begin
  if S[0] = #0 then
   NewStr:=Nil
  else
   begin
    GetMem(P, Length(S) + 1);
    Move(S, P^, Length(S) + 1);
    NewStr:=P;
   end;
 end;

procedure DisposeStr;
 begin
  if S <> Nil then
   FreeMem(S, Length(S^) + 1);
 end;

function Version2Str(L: Longint): String;
 type
  TVersion = record
   SubVersion: System.Byte;
   Build: System.Byte;
   Minor: System.Byte;
   Major: System.Byte;
  end;
 var
  V: TVersion absolute L;
 begin
  if V.Build <> 0 then
   Version2Str:=Long2Str(V.Major) + '.' + Long2Str(V.Minor) + '.' + Long2Str(V.Build)
  else
   Version2Str:=Long2Str(V.Major) + '.' + Long2Str(V.Minor);
 end;

function Address2Str(const A: TAddress): String;
 begin
  if (A.Zone = 0) and (A.Net = 0) and (A.Node = 0) and (A.Point = 0) then
   Address2Str:='?:?/?.?'
  else
   Address2Str:=Long2Str(A.Zone) + ':' + Long2Str(A.Net) + '/' + Long2Str(A.Node) + '.' + Long2Str(A.Point);
 end;

function Address2StrTrim(const A: TAddress): String;
 begin
  if A.Point <> 0 then
   Address2StrTrim:=Long2Str(A.Zone) + ':' + Long2Str(A.Net) + '/' + Long2Str(A.Node) + '.' + Long2Str(A.Point)
  else
   Address2StrTrim:=Long2Str(A.Zone) + ':' + Long2Str(A.Net) + '/' + Long2Str(A.Node);
 end;

function Address2StrPointLess(const A: TAddress): String;
 begin
  Address2StrPointLess:=Long2Str(A.Zone) + ':' + Long2Str(A.Net) + '/' + Long2Str(A.Node);
 end;

procedure Str2Address(S: String; var A: TAddress);
 begin
  S:=ExtractWord(1, Trim(S), ['@',' ']);
  Str2Longint(ExtractWord(1, S, [':','/','.']), A.Zone);
  Str2Longint(ExtractWord(2, S, [':','/','.']), A.Net);
  Str2Longint(ExtractWord(3, S, [':','/','.']), A.Node);
  Str2Longint(ExtractWord(4, S, [':','/','.']), A.Point);
 end;

procedure ParseDate(S: String; var Date: TDate);
 begin
  TrimEx(S);
  Str2Word(ExtractWord(1, S, DateDivider), Date.Day);
  Str2Word(ExtractWord(2, S, DateDivider), Date.Month);
  Str2Word(ExtractWord(3, S, DateDivider), Date.Year);
 end;

function Date2Str(const D: TDate): String;
 begin
  Date2Str:= LeftPadCh(Long2Str(D.Day), '0', 2) + DateCharacter +
             LeftPadCh(Long2Str(D.Month), '0', 2) + DateCharacter +
             LeftPadCh(Long2Str(D.Year), '0', 4);
 end;

function ValidDate(const D: TDate): Boolean;
 begin
  ValidDate:= (D.Day>=1) and (D.Day<=31) and
              (D.Month>=1) and (D.Month<=12) and
              (D.Year<>0);
 end;

function InDate(const D1, D2: TDate; const Day, Month, Year: Word): boolean;
 begin
  InDate:=(Day>=D1.Day) and (Day<=D2.Day) and
          (Month>=D1.Month) and (Month<=D2.Month) and
          (Year>=D1.Year) and (Year<=D2.Year);
 end;

procedure ClearAddress(var A: TAddress);
 begin
  FillChar(A, SizeOf(A), 0);
 end;

{* TStream code *}

{$IFDEF DPMI}
const
 TStream_Error = $8 + $4;

procedure DoStreamError; near; assembler;
asm
        PUSH    ES
        PUSH    DI
        PUSH    DX
        PUSH    AX
        PUSH    ES
        PUSH    DI
        MOV     DI,ES:[DI]
        CALL    DWORD PTR [DI].TStream_Error
        POP     DI
        POP     ES
end;
{$ENDIF}

constructor TStream.Init;
begin
  inherited Init;
  Status := 0;
  ErrorInfo := 0;
end;

procedure TStream.CopyFrom(var S: TStream; Count: Longint);
var
  N: Word;
  Buffer: array[0..1023] of Byte;
begin
  while Count > 0 do
  begin
    if Count > SizeOf(Buffer) then N := SizeOf(Buffer) else N := Count;
    S.Read(Buffer, N);
    Write(Buffer, N);
    Dec(Count, N);
  end;
end;

procedure TStream.Error(Code, Info: Integer);
type
  TErrorProc = procedure(var S: TStream);
begin
  Status := Code;
  ErrorInfo := Info;
  if StreamError <> nil then TErrorProc(StreamError)(Self);
end;

procedure TStream.Flush;
begin
end;

function TStream.GetPos: Longint;
begin
 GetPos:=0;
end;

function TStream.GetSize: Longint;
begin
 GetSize:=0;
end;

procedure TStream.Read(var Buf; Count: OSWord);
begin
end;

procedure TStream.Reset;
begin
  Status:=0;
  ErrorInfo:=0;
end;

procedure TStream.Seek(Pos: Longint);
begin
end;

procedure TStream.Truncate;
begin
end;

procedure TStream.Write(var Buf; Count: OSWord);
begin
end;

procedure TStream.WriteStr(S: String);
 var
  PitStop: System.Byte;
 begin
  PitStop:=$FF;
  Write(PitStop, 1);
  Write(S, Length(S)+1);
 end;

function TStream.ReadStr: String;
 var
  S: String;
  PitStop: System.Byte;
 begin
  Read(PitStop, 1);
  if PitStop <> $FF then
   begin
    Status:=stStrError;
    Exit;
   end;
  Read(S[0], 1);
  Read(S[1], Byte(S[0]));
  ReadStr:=S;
 end;

{* TDosStream Code *}

{$IFNDEF VIRTUALPASCAL}
constructor TDosStream.Init(FileName: String; Mode: Word); assembler;
var
  NameBuf: array[0..255] of Char;
asm
        XOR     AX,AX
        PUSH    AX
        LES     DI,Self
        PUSH    ES
        PUSH    DI
        CALL    TStream.Init
{$IfDef Windows}
        LEA     DI,NameBuf
        PUSH    SS
        PUSH    DI
        LES     DI,FileName
        PUSH    ES
        PUSH    DI
        MOV     AX,79
        PUSH    AX
        CALL    StrLCopy
        PUSH    DS
        LEA     DX,NameBuf
{$Else}
        PUSH    DS
        LDS     SI,FileName
        LEA     DI,NameBuf
        MOV     DX,DI
        PUSH    SS
        POP     ES
        CLD
        LODSB
        CMP     AL,79
        JB      @@1
        MOV     AL,79
@@1:    CBW
        XCHG    AX,CX
        REP     MOVSB
        XCHG    AX,CX
        STOSB
{$EndIF}
        PUSH    SS
        POP     DS
        XOR     CX,CX
        MOV     AX,Mode
        INT     21H
        POP     DS
        JNC     @@2
        LES     DI,Self
        MOV     DX,stInitError
        CALL    DoStreamError
        MOV     AX,-1
@@2:    LES     DI,Self
        MOV     ES:[DI].TDosStream.Handle,AX
end;

destructor TDosStream.Done; assembler;
asm
        LES     DI,Self
        MOV     BX,ES:[DI].TDosStream.Handle
        CMP     BX,-1
        JE      @@1
        MOV     AH,3EH
        INT     21H
@@1:    XOR     AX,AX
        PUSH    AX
        PUSH    ES
        PUSH    DI
        CALL    TStream.Done
end;

function TDosStream.GetPos: Longint; assembler;
asm
        LES     DI,Self
        XOR     DX,DX
        CMP     DX,ES:[DI].TDosStream.Status
        JNE     @@1
        MOV     CX,DX
        MOV     BX,ES:[DI].TDosStream.Handle
        MOV     AX,4201H
        INT     21H
        JNC     @@2
        MOV     DX,stError
        CALL    DoStreamError
@@1:    MOV     AX,-1
        CWD
@@2:
end;

function TDosStream.GetSize: Longint; assembler;
asm
        LES     DI,Self
        XOR     DX,DX
        CMP     DX,ES:[DI].TDosStream.Status
        JNE     @@1
        MOV     CX,DX
        MOV     BX,ES:[DI].TDosStream.Handle
        MOV     AX,4201H
        INT     21H
        PUSH    DX
        PUSH    AX
        XOR     DX,DX
        MOV     CX,DX
        MOV     AX,4202H
        INT     21H
        POP     SI
        POP     CX
        PUSH    DX
        PUSH    AX
        MOV     DX,SI
        MOV     AX,4200H
        INT     21H
        POP     AX
        POP     DX
        JNC     @@2
        MOV     DX,stError
        CALL    DoStreamError
@@1:    MOV     AX,-1
        CWD
@@2:
end;

procedure TDosStream.Read(var Buf; Count: Word); assembler;
asm
        LES     DI,Self
        CMP     ES:[DI].TDosStream.Status,0
        JNE     @@2
        PUSH    DS
        LDS     DX,Buf
        MOV     CX,Count
        MOV     BX,ES:[DI].TDosStream.Handle
        MOV     AH,3FH
        INT     21H
        POP     DS
        MOV     DX,stError
        JC      @@1
        CMP     AX,CX
        JE      @@3
        XOR     AX,AX
        MOV     DX,stReadError
@@1:    CALL    DoStreamError
@@2:    LES     DI,Buf
        MOV     CX,Count
        XOR     AL,AL
        CLD
        REP     STOSB
@@3:
end;

procedure TDosStream.Seek(Pos: Longint); assembler;
asm
        LES     DI,Self
        CMP     ES:[DI].TDosStream.Status,0
        JNE     @@2
        MOV     DX,Pos.Word[0]
        MOV     CX,Pos.Word[2]
        OR      CX,CX
        JNS     @@1
        XOR     DX,DX
        XOR     CX,CX
@@1:    MOV     BX,ES:[DI].TDosStream.Handle
        MOV     AX,4200H
        INT     21H
        JNC     @@2
        MOV     DX,stError
        CALL    DoStreamError
@@2:
end;

procedure TDosStream.Truncate; assembler;
asm
        LES     DI,Self
        XOR     CX,CX
        CMP     CX,ES:[DI].TDosStream.Status
        JNE     @@1
        MOV     BX,ES:[DI].TDosStream.Handle
        MOV     AH,40H
        INT     21H
        JNC     @@1
        MOV     DX,stError
        CALL    DoStreamError
@@1:
end;

procedure TDosStream.Write(var Buf; Count: Word); assembler;
asm
        LES     DI,Self
        CMP     ES:[DI].TDosStream.Status,0
        JNE     @@2
        PUSH    DS
        LDS     DX,Buf
        MOV     CX,Count
        MOV     BX,ES:[DI].TDosStream.Handle
        MOV     AH,40H
        INT     21H
        POP     DS
        MOV     DX,stError
        JC      @@1
        CMP     AX,CX
        JE      @@2
        XOR     AX,AX
        MOV     DX,stWriteError
@@1:    CALL    DoStreamError
@@2:
end;

{* TBufStream *}

procedure FlushBuffer; near; assembler;
asm
        MOV     CX,ES:[DI].TBufStream.BufPtr
        SUB     CX,ES:[DI].TBufStream.BufEnd
        JE      @@3
        MOV     BX,ES:[DI].TDosStream.Handle
        JA      @@1
        CMP     AL,1
        JE      @@4
        MOV     DX,CX
        MOV     CX,-1
        MOV     AX,4201H
        INT     21H
        JMP     @@3
@@1:    CMP     AL,0
        JE      @@4
        PUSH    DS
        LDS     DX,ES:[DI].TBufStream.Buffer
        MOV     AH,40H
        INT     21H
        POP     DS
        MOV     DX,stError
        JC      @@2
        CMP     AX,CX
        JE      @@3
        XOR     AX,AX
        MOV     DX,stWriteError
@@2:    CALL    DoStreamError
@@3:    XOR     AX,AX
        MOV     ES:[DI].TBufStream.BufPtr,AX
        MOV     ES:[DI].TBufStream.BufEnd,AX
        CMP     AX,ES:[DI].TStream.Status
@@4:
end;

constructor TBufStream.Init(FileName: String; Mode, Size: Word);
begin
  inherited Init(FileName, Mode);
  BufSize := Size;
  if Size = 0 then Error(stInitError, 0)
  else GetMem(Buffer, Size);
  BufPtr := 0;
  BufEnd := 0;
end;

destructor TBufStream.Done;
begin
  TBufStream.Flush;
  TDosStream.Done;
  FreeMem(Buffer, BufSize);
end;

procedure TBufStream.Flush; assembler;
asm
        LES     DI,Self
        CMP     ES:[DI].TBufStream.Status,0
        JNE     @@1
        MOV     AL,2
        CALL    FlushBuffer
@@1:
end;

function TBufStream.GetPos: Longint; assembler;
asm
        LES     DI,Self
        PUSH    ES
        PUSH    DI
        CALL    TDosStream.GetPos
        OR      DX,DX
        JS      @@1
        LES     DI,Self
        SUB     AX,ES:[DI].TBufStream.BufEnd
        SBB     DX,0
        ADD     AX,ES:[DI].TBufStream.BufPtr
        ADC     DX,0
@@1:
end;

function TBufStream.GetSize: Longint; assembler;
asm
        LES     DI,Self
        PUSH    ES
        PUSH    DI
        PUSH    ES
        PUSH    DI
        CALL    TBufStream.Flush
        CALL    TDosStream.GetSize
end;

procedure TBufStream.Read(var Buf; Count: Word); assembler;
asm
        LES     DI,Self
        CMP     ES:[DI].TBufStream.Status,0
        JNE     @@6
        MOV     AL,1
        CALL    FlushBuffer
        JNE     @@6
        XOR     BX,BX
@@1:    MOV     CX,Count
        SUB     CX,BX
        JE      @@7
        LES     DI,Self
        MOV     AX,ES:[DI].TBufStream.BufEnd
        SUB     AX,ES:[DI].TBufStream.BufPtr
        JA      @@2
        PUSH    DS
        PUSH    CX
        PUSH    BX
        LDS     DX,ES:[DI].TBufStream.Buffer
        MOV     CX,ES:[DI].TBufStream.BufSize
        MOV     BX,ES:[DI].TBufStream.Handle
        MOV     AH,3FH
        INT     21H
        POP     BX
        POP     CX
        POP     DS
        MOV     DX,stError
        JC      @@5
        MOV     ES:[DI].TBufStream.BufPtr,0
        MOV     ES:[DI].TBufStream.BufEnd,AX
        OR      AX,AX
        JE      @@4
@@2:    CMP     CX,AX
        JB      @@3
        MOV     CX,AX
@@3:    PUSH    DS
        LDS     SI,ES:[DI].TBufStream.Buffer
        ADD     SI,ES:[DI].TBufStream.BufPtr
        ADD     ES:[DI].TBufStream.BufPtr,CX
        LES     DI,Buf
        ADD     DI,BX
        ADD     BX,CX
        CLD
        REP     MOVSB
        POP     DS
        JMP     @@1
@@4:    MOV     DX,stReadError
@@5:    CALL    DoStreamError
@@6:    LES     DI,Buf
        MOV     CX,Count
        XOR     AL,AL
        CLD
        REP     STOSB
@@7:
end;

procedure TBufStream.Seek(Pos: Longint); assembler;
asm
        LES     DI,Self
        PUSH    ES
        PUSH    DI
        CALL    TDosStream.GetPos
        OR      DX,DX
        JS      @@2
        LES     DI,Self
        SUB     AX,Pos.Word[0]
        SBB     DX,Pos.Word[2]
        JNE     @@1
        OR      AX,AX
        JE      @@1
        MOV     DX,ES:[DI].TBufStream.BufEnd
        SUB     DX,AX
        JB      @@1
        MOV     ES:[DI].TBufStream.BufPtr,DX
        JMP     @@2
@@1:    PUSH    Pos.Word[2]
        PUSH    Pos.Word[0]
        PUSH    ES
        PUSH    DI
        PUSH    ES
        PUSH    DI
        CALL    TBufStream.Flush
        CALL    TDosStream.Seek
@@2:
end;

procedure TBufStream.Truncate;
begin
  TBufStream.Flush;
  TDosStream.Truncate;
end;

procedure TBufStream.Write(var Buf; Count: Word); assembler;
asm
        LES     DI,Self
        CMP     ES:[DI].TBufStream.Status,0
        JNE     @@4
        MOV     AL,0
        CALL    FlushBuffer
        JNE     @@4
        XOR     DX,DX
@@1:    MOV     CX,Count
        SUB     CX,DX
        JE      @@4
        LES     DI,Self
        MOV     AX,ES:[DI].TBufStream.BufSize
        SUB     AX,ES:[DI].TBufStream.BufPtr
        JA      @@2
        PUSH    CX
        PUSH    DX
        MOV     AL,1
        CALL    FlushBuffer
        POP     DX
        POP     CX
        JNE     @@4
        MOV     AX,ES:[DI].TBufStream.BufSize
@@2:    CMP     CX,AX
        JB      @@3
        MOV     CX,AX
@@3:    PUSH    DS
        MOV     AX,ES:[DI].TBufStream.BufPtr
        ADD     ES:[DI].TBufStream.BufPtr,CX
        LES     DI,ES:[DI].TBufStream.Buffer
        ADD     DI,AX
        LDS     SI,Buf
        ADD     SI,DX
        ADD     DX,CX
        CLD
        REP     MOVSB
        POP     DS
        JMP     @@1
@@4:
end;
{$ELSE}

{* TDosStream, TBufStream code [Virtual Pascal] *}

constructor TDosStream.Init(FileName: String; Mode: OSWord);
 var
  FName: PChar;
 begin
  inherited Init;
  GetMem(FName, Length(FileName) + 1);
  StrPCopy(FName, FileName);
  case Mode of
   stCreate: Status:=SysFileCreate(FName, open_access_ReadWrite or open_share_DenyNone, 0, Handle);
   stOpenRead: Status:=SysFileOpen(FName, open_access_ReadOnly or open_share_DenyNone, Handle);
   stOpenWrite: Status:=SysFileOpen(FName, open_access_WriteOnly or open_share_DenyNone, Handle);
   stOpen: Status:=SysFileOpen(FName, open_access_ReadWrite or open_share_DenyNone, Handle);
  end;
  FreeMem(FName, Length(FileName) + 1);
  if Status = 0 then Seek(0);
 end;

destructor TDosStream.Done;
 begin
  SysFileClose(Handle);
 end;

procedure TDosStream.Read(var Buf; Count: OSWord);
 var
  Actual: Longint;
 begin
  Status:=SysFileRead(Handle, Buf, Count, Actual);
 end;

function TDosStream.GetSize: Longint;
 var
  OldPosition: Longint;
 begin
  Status:=SysFileSeek(Handle, 0, 1, OldPosition);
  if Status <> 0 then Exit;
  Status:=SysFileSeek(Handle, 0, 2, Result);
  if Status <> 0 then Exit;
  Status:=SysFileSeek(Handle, OldPosition, 0, OldPosition);
  if Status <> 0 then Exit;
 end;

function TDosStream.GetPos: Longint;
 begin
  Status:=SysFileSeek(Handle, 0, 1, Result);
 end;

procedure TDosStream.Seek(Pos: Longint);
 var
  Actual: Longint;
 begin
  Status:=SysFileSeek(Handle, Pos, 0, Actual);
 end;

procedure TDosStream.Truncate;
 begin
  Status:=SysFileSetSize(Handle, GetPos);
 end;

procedure TDosStream.Write(var Buf; Count: OSWord);
 var
  Actual: Longint;
 begin
  Status:=SysFileWrite(Handle, Buf, Count, Actual);
 end;

constructor TBufStream.Init(FileName: String; Mode, Size: OSWord);
 begin
  inherited Init(FileName, Mode);
 end;
{$ENDIF}

{* TCollection *}
constructor TCollection.Init;
 begin
  inherited Init;
  DataSize:=0;
  Data:=Nil;
  AddMoreItems;
 end;

procedure TCollection.AddMoreItems;
 var
  NewDataSize: Longint;
  NewData: PCollectionData;
 begin
  NewDataSize:=DataSize + AlignCollection;
  if NewDataSize > MaxCollection then NewDataSize:=MaxCollection;
  GetMem(NewData, NewDataSize * 4);
  if Data <> Nil then
   begin
    Move(Data^, NewData^, DataSize * 4);
    FreeMem(Data, DataSize * 4);
   end;
  DataSize:=NewDataSize;
  Data:=NewData;
 end;

procedure TCollection.Insert;
 begin
  AtInsert(Count + 1, Item);
 end;

procedure TCollection.Delete;
 begin
  AtDelete(IndexOf(Item));
 end;

procedure TCollection.Free;
 begin
  AtFree(IndexOf(Item));
 end;

procedure TCollection.AtInsert;
 var
  K: Longint;
 begin
  if Count + 1 > DataSize then AddMoreItems;
  if (Count = MaxCollection) or (N > MaxCollection) or (N < 1) then Exit;
  for K:=Count downto N do Data^[K + 1]:=Data^[K];
  Inc(Count);
  Data^[N]:=Item;
 end;

procedure TCollection.AtDelete;
 var
  K: Longint;
 begin
  if (N<1) or (N>Count) then Exit;
  for K:=N+1 to Count do Data^[K-1]:=Data^[K];
  Dec(Count);
 end;

procedure TCollection.AtFree;
 begin
  if (N<1) or (N>Count) then Exit;
  FreeItem(At(N));
  AtDelete(N);
 end;

function TCollection.At;
 begin
  if (Item<1) or (Item>Count) then
   begin
    At:=Nil;
    Exit;
   end;
  At:=Data^[Item];
 end;

function TCollection.IndexOf;
 var
  K: Longint;
  L: ^Pointer;
 begin
  L:=Pointer(Data);
  K:=Count;
  for K:=1 to Count do
   begin
    if L^ = Item then
     begin
      IndexOf:=K;
      Exit;
     end;
    Inc(Longint(L), 4);
   end;
  IndexOf:=-1;
 end;

procedure TCollection.DeleteAll;
 begin
  Count:=0;
 end;

procedure TCollection.FreeAll;
 var
  K: Longint;
 begin
  for K:=1 to Count do
   FreeItem(At(K));
  DeleteAll;
 end;

procedure TCollection.FreeItem;
 begin
  if Item <> nil then Dispose(PObject(Item), Done);
 end;

procedure TCollection.Sort(Handler: TSortHandler);
 procedure SortRange(L, R: Longint);
  var
   I, J, X: Longint;
   Y: Pointer;
  begin
   I:=L; J:=R;
   X:=(L+R) div 2;
   repeat
    while Longint(Handler(@Self, Longint(I), Longint(X)))<Longint(0) do Inc(I);
    while Longint(Handler(@Self, Longint(X), Longint(J)))<Longint(0) do Dec(J);
    if I<=J then
     begin
      Y:=Data^[I];
      Data^[I]:=Data^[J];
      Data^[J]:=Y;
      Inc(I);
      Dec(J);
     end;
    if I>J then Break;
   until False;
   if L<J then SortRange(L, J);
   if I<R then SortRange(I, R);
  end;
 begin
  if Count <= 1 then Exit;
  SortRange(1, Count);
  SortRange(1, Count);
  SortRange(1, Count);
 end;

destructor TCollection.Done;
 begin
  FreeAll;
  FreeMem(Data, DataSize * 4);
  inherited Done;
 end;

constructor TMemoryStream.Init;
 begin
  inherited Init;
  New(First);
  First^.Size:=0;
  First^.Next:=Nil;
  GetMem(First^.Buffer, First^.Size);
  CurPos:=0;
  CurSize:=0;
 end;

destructor TMemoryStream.Done;
 var
  Block, SavedBlock: PRamBlock;
 begin
  Block:=First;
  while Block <> Nil do
   begin
    FreeMem(Block^.Buffer, Block^.Size);
    SavedBlock:=Block;
    Block:=Block^.Next;
    Dispose(SavedBlock);
   end;
  inherited Done;
 end;

function TMemoryStream.GetPos: Longint;
 begin
  GetPos:=CurPos;
 end;

function TMemoryStream.GetSize: Longint;
 begin
  GetSize:=CurSize;
 end;

procedure TMemoryStream.Read(var Buf; Count: OSWord);
 var
  Buffer: TRamBuffer absolute Buf;
  Block: PRamBlock;
  K, Offset, Remain: Longint;
 begin
  K:=0;
  while K < Count do
   begin
    GetPosEx(CurPos, Block, Offset, Remain);
    if Block = Nil then Break;
    if Remain > Count - K then Remain:=Count - K;
    Move(Block^.Buffer^[Offset], Buffer[K], Remain);
    Inc(CurPos, Remain);
    Inc(K, Remain);
   end;
 end;

procedure TMemoryStream.Seek(Pos: Longint);
 begin
  CurPos:=Pos;
 end;

procedure TMemoryStream.Truncate;
 begin
  SetSize(CurPos);
 end;

procedure TMemoryStream.Write(var Buf; Count: OSWord);
 var
  Buffer: TRamBuffer absolute Buf;
  Block: PRamBlock;
  K, Offset, Remain: Longint;
 begin
  if CurPos + Count > CurSize then
   SetSize(CurPos + Count);
  K:=0;
  while K < Count do
   begin
    GetPosEx(CurPos, Block, Offset, Remain);
    if Block = Nil then Break;
    if Remain > Count - K then Remain:=Count - K;
    Move(Buffer[K], Block^.Buffer^[Offset], Remain);
    Inc(CurPos, Remain);
    Inc(K, Remain);
   end;
 end;

procedure TMemoryStream.CopyFrom(var S: TStream; Count: Longint);
 begin
  if CurPos + Count > CurSize then
   SetSize(CurPos + Count);
  inherited CopyFrom(S, Count);
 end;

procedure TMemoryStream.SetSize(NewSize: Longint);
 var
  NextBlockSize: Longint;
  Block, AnotherBlock, Last: PRamBlock;
  Temp: Pointer;
 begin
  if NewSize > CurSize then
   begin
    Last:=First;
    while Last^.Next <> Nil do
     Last:=Last^.Next;
    repeat
     NextBlockSize:=NewSize - CurSize;
     if NextBlockSize = 0 then Break;
     if NextBlockSize > BlockSize then NextBlockSize:=BlockSize;
     Block:=Last;
     if Block^.Size < NextBlockSize then
      begin
       Dec(CurSize, Block^.Size);
       Inc(CurSize, NextBlockSize);
       GetMem(Temp, Block^.Size);
       Move(Block^.Buffer^, Temp^, Block^.Size);
       FreeMem(Block^.Buffer, Block^.Size);
       GetMem(Block^.Buffer, NextBlockSize);
       Move(Temp^, Block^.Buffer^, Block^.Size);
       FreeMem(Temp, Block^.Size);
       Block^.Size:=NextBlockSize;
      end
     else
      begin
       New(AnotherBlock);
       AnotherBlock^.Size:=NextBlockSize;
       AnotherBlock^.Next:=Nil;
       GetMem(AnotherBlock^.Buffer, NextBlockSize);
       Block^.Next:=AnotherBlock;
       Inc(CurSize, AnotherBlock^.Size);
       Last:=AnotherBlock;
      end;
    until False;
   end else
  if NewSize < CurSize then
   repeat
    NextBlockSize:=CurSize - NewSize;
    if NextBlockSize = 0 then Break;
    Block:=First;
    while Block^.Next <> Nil do
     begin
      AnotherBlock:=Block;
      Block:=Block^.Next;
     end;
    if NextBlockSize > Block^.Size then
     begin
      AnotherBlock^.Next:=Nil;
      FreeMem(Block^.Buffer, Block^.Size);
      Dec(CurSize, Block^.Size);
      Dispose(Block);
      Last:=AnotherBlock;
     end
    else
     begin
      NextBlockSize:=Block^.Size - NextBlockSize;
      Dec(CurSize, Block^.Size);
      Inc(CurSize, NextBlockSize);
      GetMem(Temp, NextBlockSize);
      Move(Block^.Buffer^, Temp^, NextBlockSize);
      FreeMem(Block^.Buffer, Block^.Size);
      GetMem(Block^.Buffer, NextBlockSize);
      Move(Temp^, Block^.Buffer^, NextBlockSize);
      FreeMem(Temp, NextBlockSize);
      Block^.Size:=NextBlockSize;
     end;
   until False;
  CurSize:=NewSize;
 end;

procedure TMemoryStream.GetPosEx(Position: Longint; var Block: PRamBlock; var Offset, Remain: Longint);
 begin
  Block:=First;
  repeat
   if Position < Block^.Size then
    begin
     Offset:=Position;
     Remain:=Block^.Size - Position;
     Exit;
    end;
   Dec(Position, Block^.Size);
   Block:=Block^.Next;
  until Block = Nil;
  Offset:=-1;
  Remain:=-1;
 end;

{ ErrorHandler }

{$IFDEF DPMI}
procedure ErrorHandler_SaveTheScreen(var F: Text);
 var
  Scr: PScreen;
  S: String;
  X, Y: Longint;
 begin
  Scr:=Ptr(SegB800, 0);
  S[0]:=#80;
  for Y:=1 to 25 do
   begin
    for X:=1 to 80 do S[X]:=Scr^[Y, X].Ch;
    WriteLn(F, Rtrim(S));
   end;
 end;
{$ENDIF}

{$IFDEF OS2}
procedure ErrorHandler_SaveTheScreen(var F: Text);
 var
  S: String;
  K: SmallWord;
  X, Y: Longint;
 begin
  K:=80;
  for Y:=0 to 24 do
   begin
    S[0]:=#80;
    VioReadCharStr(S[1], K, Y, 0, 0);
    WriteLn(F, Rtrim(S));
   end;
 end;
{$ENDIF}

{$IFDEF WIN32}
type
 PWin32Cell = ^TWin32Cell;
 TWin32Cell = record
  Ch: SmallWord;
  Attr: SmallWord;
 end;
 PStandardCell = ^TStandardCell;
 TStandardCell = packed record
  Ch: Char;
  Attr: Byte;
 end;

procedure ErrorHandler_SaveTheScreen(var F: Text);
 var
  UpLeft, Size: TCoord;
  ReadFrom: TSmallRect;
  Cursor: TPoint;
  Buffer: PWin32Cell;
  BufferSize: Longint;
  PSource: PWin32Cell;
  Info: TConsoleScreenBufferInfo;
  X, Y: Longint;
  S: String;
 begin
  GetConsoleScreenBufferInfo(SysFileStdOut, Info);
  Cursor.X:=Info.dwCursorPosition.X;
  Cursor.Y:=Info.dwCursorPosition.Y;

  BufferSize:=(Info.dwSize.Y + 1) * (Info.dwSize.X + 1) * SizeOf(TWin32Cell);
  GetMem(Buffer, BufferSize);

  Size.X:=Info.dwSize.X;
  Size.Y:=Info.dwSize.Y;
  UpLeft.X:=0;
  UpLeft.Y:=0;
  ReadFrom.Left:=0;
  ReadFrom.Top:=0;
  ReadFrom.Right:=Info.dwSize.X;
  ReadFrom.Bottom:=Info.dwSize.Y;

  ReadConsoleOutput(SysFileStdOut, Buffer, Size, UpLeft, ReadFrom);

  PSource:=Buffer;

  for Y:=0 to Info.dwSize.Y - 1 do
   begin
    S:='';
    for X:=0 to Info.dwSize.X - 1 do
     begin
      S:=Concat(S, Chr(PSource^.Ch));
      Inc(PSource);
     end;
    WriteLn(F, S);
   end;

  FreeMem(Buffer, BufferSize);
 end;
{$ENDIF}

procedure ErrorHandler; far;
 var
  F: Text;
  I: Longint;
{$IFDEF VIRTUALPASCAL}
  SrcFile:String;
  LineNo:Longint;
  LInfo:Pointer;
{$ENDIF}
 begin
  if ErrorAddr <> nil then
   begin
    I:=IOResult;

    vSetAttr($F);
    vPrintLn('');
    vPrintLn('[*] Run-Time Error intercepter activated * ');
    vSetAttr($A);
    vPrintLn('[i] Stack: ' + Long2StrFmt(SPtr) + ' bytes free');
    vSetAttr($C);
    vPrintLn('[i] Run-time error at ' + HexL(Longint(ErrorAddr)) + ': #' + LeftPadCh(Long2Str(ExitCode), '0', 3));
    {$IFDEF VIRTUALPASCAL}
    LInfo:=GetLocationInfo(ErrorAddr, SrcFile, LineNo);
    if LInfo <> nil then
     vPrintLn('[i] LocationInfo: '+SrcFile+':'+Long2Str(LineNo));
    {$ENDIF}
    vSetAttr($7);
    if SPtr < $500 then
     begin
      vPrintLn('[!] Cannot log Run-Time Error because there is not enought stack. :-(');
      Exit;
     end;
    vPrintLn('[*] Working...');
    {$I-}
    if IOResult <> 0 then;
    Assign(F, RTEFile);
    Append(F);
    if IOResult <> 0 then
     begin
      vPrintLn('[*] Creating ' + RTEFile);
      ReWrite(F);
      if InOutRes <> 0 then
       begin
        vPrintLn('[!] Cannot create ' + RTEFile + ', rc#=' + Long2Str(IOResult));
        Exit;
       end;
     end
    else
     vPrintLn('[*] Appending to ' + RTEFile);
    WriteLn(F, '--- ', GetPktDateTime);
    WriteLn(F, 'EC #', LeftPadCh(Long2Str(ExitCode), '0', 3));
    WriteLn(F, 'EA #' + HexL(Longint(ErrorAddr)));
    {$IFDEF VIRTUALPASCAL}
    if LInfo <> nil then
     Writeln(F, 'LI #'+SrcFile+':',LineNo);
    {$ENDIF}
    WriteLn(F, 'IO #', Long2Str(I));
    WriteLn(F, 'HA #', Long2StrFmt(MemAvail));
    WriteLn(F, 'HM #', Long2StrFmt(MaxAvail));
    WriteLn(F, 'SS:SP #', HexL(SSeg), ':', HexL(SPtr));
    WriteLn(F, 'DS #', HexL(DSeg));
    WriteLn(F, 'TS #', HexL(Longint(@ErrorHandler)));

    {$IFDEF DPMI}
    WriteLn(F, 'PS #', HexL(PrefixSeg));
    {$ENDIF}

    WriteLn(F, 'OS #', OS_Name, ' [', HexL(OS_ID), ']');
    WriteLn(F, 'ID #FastUUE'
    {$IFDEF SOLID}+{$IFDEF CUSTOMSOLID}'/CUSTOM'{$ELSE}'/SOLID'{$ENDIF}{$ENDIF});
    WriteLn(F, 'VR #', Version2Str(KernelVersion), ' [', HexL(KernelVersion), ']');
    WriteLn(F, 'SShot');

    ErrorHandler_SaveTheScreen(F);

    WriteLn(F, 'SShot_End');

    Flush(F);
    Close(F);
    vPrintLn('[*] Closed ' + RTEFile);
    if IOResult <> 0 then;

    ErrorAddr:=Nil;
    ExitCode:=255;

    vSetAttr($E);
    vPrintLn('[:] Please send ' + RTEFile + ' to');
    vPrintLn('[:] 2:4600/220@fidonet or sysop@f220.n4600.z2.fidonet.org.');
    vSetAttr($F);
    vPrintLn('[*] Done. Exiting with errorlevel 255.');
    vSetAttr($7);
    vPrintLn('');

    {$IFDEF DPMI}
    ExitProc:=OldExitProc;
    {$ENDIF}
   end;
 end;

begin
{$IFDEF DPMI}
 OldExitProc:=ExitProc;
 ExitProc:=@ErrorHandler;
{$ELSE}
 AddExitProc(ErrorHandler);
{$ENDIF}
end.