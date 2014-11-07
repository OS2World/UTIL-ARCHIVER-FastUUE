{
 The New Scanning Core,
 (c) by sergey korowkin, 1999.
}
unit ScanSys;

{$IFDEF VIRTUALPASCAL}
 {$DEFINE USEUNITS}
{$ENDIF}
{$IFDEF SOLID}
 {$DEFINE USEUNITS}
{$ENDIF}

interface

uses
{$IFDEF USEUNITS}
     Misc, Semaphor, Plugins, Language, Config, Video,
{$ELSE}
     Decl,
{$ENDIF}
     Core, Dos, Wizard, Types;

type
 PStatPlugin = ^TStatPlugin;
 TStatPlugin = object(TObject)
  Plugin: Pointer;
  LockedTime, Time, Calls: Longint;
  constructor Init(const APlugin: Pointer);
  procedure Lock;
  procedure Unlock;
 end;

 TBroadcaster = procedure(const Service: Longint; const Buffer: Pointer);

const
 __HACK__STUFF__                : String[7] = 'hsSSBS!';
 ScanStreamBlockSize            : Longint = $00002000;

 ScanProcessedSize              : Longint = $00000000;
 ScanTotalSize                  : Longint = $00000000;

 ScanUseReply                   : Boolean = False;
 ScanRepack                     : Boolean = False;
 ScanShowProgress               : Boolean = False;
 ScanPreload                    : Boolean = False;
 ScanPresave                    : Boolean = False;

 TheQueue                       : PCollection = Nil;
 PluginsQueue                   : PCollection = Nil;

 Stat                           : Boolean = False;

 MBuffer                        : PChar = Nil;

{$IFDEF VIRTUALPASCAL}
 MBufferOffset                  : Longint = 0;
{$ELSE}
 MBufferOffset                  : Word = 0;
{$ENDIF}

{$IFDEF VIRTUALPASCAL}
 MBufferSize                    = $1FFFF;
{$ELSE}
 MBufferSize                    = $0FFF0;
{$ENDIF}

 flagsMaxFucktor                = $00000001;

 Flags                          : Longint = 0;

var
 StatExternal                   : TStatPlugin;
 StatInternal                   : TStatPlugin;
 StatLoadMessage                : TStatPlugin;
 StatPreload                    : TStatPlugin;
 StatPresave                    : TStatPlugin;

 { twittaz }

 FromExclude                    : PStrings;
 FromRemain                     : PStrings;
 ToExclude                      : PStrings;
 ToRemain                       : PStrings;

{ Scan.Inc's declarations }

{$DEFINE SCAN_DECL}
{$I SCAN.INC}

{ TScanStream's declaration }
type
 PScanStream = ^TScanStream;
 TScanStream = object(TBufStream)
  CurPos: Longint;
  CurSize: Longint;
  constructor Init(const FileName: String; const Mode: OSWord);
  function GetPos: Longint; virtual;
  function GetSize: Longint; virtual;
  procedure Seek(Pos: Longint); virtual;
  procedure Read(var Buf; Count: OSWord); virtual;
  procedure Write(var Buf; Count: OSWord); virtual;
 private
  procedure Refresh;
 end;

var
 Broadcaster: TBroadcaster;

procedure __ScanPacket(const FName: String);

procedure Broadcast(const Service: Longint; const Buffer: Pointer);
procedure BroadcastEx(const Service: Longint; const Buffer: Pointer);

implementation

{ TStatPlugin }

constructor TStatPlugin.Init(const APlugin: Pointer);
 begin
  inherited Init;
  Plugin:=APlugin;
  Time:=0;
 end;

procedure TStatPlugin.Lock;
 begin
  LockedTime:=Clock;
 end;

procedure TStatPlugin.Unlock;
 begin
  Inc(Time, Clock - LockedTime);
  Inc(Calls);
 end;

{ Scan.Inc's code }

{$DEFINE SCAN_CODE}
{$I SCAN.INC}

{ TScanStream's code }

constructor TScanStream.Init(const FileName: String; const Mode: OSWord);
 begin
  inherited Init(FileName, Mode, ScanStreamBlockSize);
  Refresh;
 end;

function TScanStream.GetPos: Longint;
 begin
  GetPos:=CurPos;
 end;

function TScanStream.GetSize: Longint;
 begin
  GetSize:=CurSize;
 end;

procedure TScanStream.Seek(Pos: Longint);
 begin
  inherited Seek(Pos);
  Refresh;
 end;

procedure TScanStream.Read(var Buf; Count: OSWord);
 begin
  inherited Read(Buf, Count);
  Refresh;
 end;

procedure TScanStream.Write(var Buf; Count: OSWord);
 begin
  inherited Write(Buf, Count);
  Refresh;
 end;

procedure TScanStream.Refresh;
 begin
  CurPos:=inherited GetPos;
  CurSize:=inherited GetSize;
 end;

{ ReadString's code }

function ReadString(const Stream: PStream; var S: String): Boolean;
 const
  MaxStringSize = 73 * 3;
 var
  Size: Longint;
  K: Byte;
 begin
  Size:=Stream^.GetSize - Stream^.GetPos;
  if Size > MaxStringSize then Size:=MaxStringSize;
  Stream^.Read(S[1], Size);
  for K:=1 to Size do
   if S[K] = #0 then
    begin
     S[0]:=Chr(K - 1);
     Stream^.Seek(Stream^.GetPos - Size + K);
     ReadString:=True;
     Exit;
    end;
  ReadString:=False;
 end;

{ WriteString's code }

procedure WriteString(const Stream: PStream; S: String);
 begin
  S:=Concat(S, #0);
  Stream^.Write(S[1], Length(S));
 end;

{ Strings stuff }

{$IFDEF DPMI}
function StrScan(Str: PChar; C: Char): PChar; assembler;
asm
        CLD
        LES     DI,Str
        MOV     SI,DI
        MOV     CX,0FFFFH
        XOR     AL,AL
        REPNE   SCASB
        NOT     CX
        MOV     DI,SI
        MOV     AL,C
        REPNE   SCASB
        MOV     AX,0
        CWD
        JNE     @@1
        MOV     AX,DI
        MOV     DX,ES
        DEC     AX
@@1:
end;

function StrScan0Dh(Str: PChar): PChar; assembler;
asm
        CLD
        LES     DI,Str
        MOV     SI,DI
        MOV     CX,0FFFFH
        XOR     AL,AL
        REPNE   SCASB
        NOT     CX
        MOV     DI,SI
        MOV     AL,0dh
        REPNE   SCASB
        MOV     AX,0
        CWD
        JNE     @@1
        MOV     AX,DI
        MOV     DX,ES
        DEC     AX
@@1:
end;

function StrScan20h(Str: PChar): PChar; assembler;
asm
        CLD
        LES     DI,Str
        MOV     SI,DI
        MOV     CX,0FFFFH
        XOR     AL,AL
        REPNE   SCASB
        NOT     CX
        MOV     DI,SI
        MOV     AL,20h
        REPNE   SCASB
        MOV     AX,0
        CWD
        JNE     @@1
        MOV     AX,DI
        MOV     DX,ES
        DEC     AX
@@1:
end;

function StrEnd(Str: PChar): PChar; assembler;
asm
        CLD
        LES     DI,Str
        MOV     CX,0FFFFH
        XOR     AL,AL
        REPNE   SCASB
        MOV     AX,DI
        MOV     DX,ES
        DEC     AX
end;

function StrPas(Str: PChar): String; assembler;
asm
        PUSH    DS
        CLD
        LES     DI,Str
        MOV     CX,0FFFFH
        XOR     AL,AL
        REPNE   SCASB
        NOT     CX
        DEC     CX
        LDS     SI,Str
        LES     DI,@Result
        MOV     AL,CL
        STOSB
        REP     MOVSB
        POP     DS
end;
{$ELSE}
function StrScan(Str: PChar; C: Char): PChar; assembler; {$USES edi} {$FRAME-}
asm
                cld
                mov     edi,Str
                mov     edx,edi
                or      ecx,-1
                xor     eax,eax
                repne   scasb
                not     ecx
                mov     edi,edx
                mov     al,c
                repne   scasb
                mov     al,0
                jne     @@1
                lea     eax,[edi-1]
              @@1:
end;

function StrScan0Dh(Str: PChar): PChar; assembler; {$USES edi} {$FRAME-}
asm
                cld
                mov     edi,Str
                mov     edx,edi
                or      ecx,-1
                xor     eax,eax
                repne   scasb
                not     ecx
                mov     edi,edx
                mov     al,0dh
                repne   scasb
                mov     al,0
                jne     @@1
                lea     eax,[edi-1]
              @@1:
end;

function StrScan20h(Str: PChar): PChar; assembler; {$USES edi} {$FRAME-}
asm
                cld
                mov     edi,Str
                mov     edx,edi
                or      ecx,-1
                xor     eax,eax
                repne   scasb
                not     ecx
                mov     edi,edx
                mov     al,20h
                repne   scasb
                mov     al,0
                jne     @@1
                lea     eax,[edi-1]
              @@1:
end;

function StrEnd(Str: PChar): PChar; assembler; {$USES edi} {$FRAME-}
asm
                cld
                mov     edi,Str
                or      ecx,-1
                xor     al,al
                repne   scasb
                lea     eax,[edi-1]
end;

function StrPas(Str: PChar): String; assembler; {$USES esi,edi} {$FRAME-}
asm
                cld
                mov     edi,Str
                or      ecx,-1
                xor     al,al
                repne   scasb
                not     ecx
                dec     ecx
                cmp     ecx,255
                jbe     @@1
                mov     ecx,255
              @@1:
                mov     esi,Str
                mov     edi,@Result
                mov     al,cl
                stosb
                shr     ecx,2
                and     al,11b
                rep     movsd
                mov     cl,al
                rep     movsb
end;
{$ENDIF}

{ LoadMessage's code }

function LoadMessage(const Stream: PStream; var Message: TMessage): Boolean;
 var
  Size, SavedPos: Longint;
  LineStart, LineEnd, LineEnd2, LineEnd3, MessageEnd, MessageGrunged: PChar;
  LineLast, LineSkip: Boolean;
  SaveChar: Char;
 {$IFDEF DPMI}
  SizeW: Word absolute Size;
  TargetW: Word absolute MessageEnd;
 {$ENDIF}
 const
  Margin1 = 255;
  Margin2 = 80;
  Margin3 = 79;
 {$IFDEF DPMI}
 label
  Cancel;
 {$ENDIF}
 begin
  StatLoadMessage.Lock;

  SavedPos:=Stream^.GetPos;

  Size:=Stream^.GetSize - SavedPos;

  if Size > MBufferSize - 1 then Size:=MBufferSize - 1;

  Stream^.Read(MBuffer^, Size);

  MBuffer[Size]:=#0;

  MessageGrunged:=@MBuffer[Size];

  MessageEnd:=StrEnd(MBuffer);

  (*
  {$IFDEF DPMI}
   MessageEnd:=MBuffer;

   asm
    cld
    les   di, MBuffer
    mov   cx, SizeW
    xor   al, al
    repne scasb
    dec   di
    mov   TargetW, di
   end;
  {$ELSE}
   asm
    cld
    mov   edi, MBuffer
    or    ecx, -1
    xor   al, al
    repne scasb
    dec   edi
    mov   MessageEnd, edi
   end;
  {$ENDIF}
  *)

  if MessageEnd = MessageGrunged then
   begin
    lngBegin;
     lngPush(Long2StrFmt(MBufferSize));
     lngPrint('Main', 'scan.64kb');
    lngEnd;

    sSetExitNow;

    Exit;
   end;

  LineStart:=MBuffer;
  LineLast:=False;
  LineSkip:=False;

  repeat
   if LineStart > MessageEnd then
    vprintln('bitch');

   LineEnd:=StrScan0Dh(LineStart);

   if LineEnd = Nil then
    begin
     LineEnd:=StrEnd(LineStart);

     LineLast:=True;

     LineSkip:=LineStart[0] = #0;
    end;

   if LineEnd - LineStart <= Margin1 then
    begin
     LineEnd[0]:=#0;

     if not LineSkip then
      cmInsert(Message.Data, cmNewStr(StrPas(LineStart)))
    end
   else
    begin
     LineEnd2:=LineStart;
     LineEnd3:=Nil;

     repeat
      LineEnd2:=StrScan20h(LineEnd2 + 1);

      if LineEnd2 - LineStart < Margin2 then
       LineEnd3:=LineEnd2
      else
       Break;
     until False;

     if LineEnd3 = Nil then
      begin
       LineEnd:=LineStart + Margin3;

       SaveChar:=LineEnd[0];
       LineEnd[0]:=#0;

       cmInsert(Message.Data, cmNewStr(StrPas(LineStart)));

       LineEnd[0]:=SaveChar;
      end
     else
      begin
       LineEnd3[0]:=#0;

       cmInsert(Message.Data, cmNewStr(StrPas(LineStart)));

       LineEnd:=LineEnd3;
      end;
    end;

   Inc(LineEnd);

   LineStart:=LineEnd;
  until LineLast;

  Message.iSize:=(MessageEnd - MBuffer) + 1;

  Stream^.Seek(SavedPos + Message.iSize);

  StatLoadMessage.Unlock;
 end;

{function LoadMessage(const Stream: PStream; var Message: TMessage): Boolean;
 var
  Size, SizeEx, SavedPos: Longint;
  EndReached: Boolean;
  C: ^Char;
  D: Char;
  K: Byte;
  S: String;
 begin
  StatLoadMessage.Lock;

  SavedPos:=Stream^.GetPos;

  EndReached:=False;
  repeat
   Size:=80 * 2;
   SizeEx:=Stream^.GetSize - Stream^.GetPos;
   if Size > SizeEx then Size:=SizeEx;

   Stream^.Read(S[1], Size);

   for K:=Size downto Size div 2 do
    case S[K] of
     #0, #13: Break;
     ' ', ',', '.', ':', ';', '!':
      begin
       Stream^.Seek(Stream^.GetPos - Size + K);
       Size:=K;
       Break;
      end;
    end;

   S[0]:=Chr(Size);
   for K:=1 to Size do
    case S[K] of
     #13:
      begin
       Stream^.Seek(Stream^.GetPos - Size + K);
       S[0]:=Chr(K - 1);
       Break;
      end;
     #0:
      begin
       Stream^.Seek(Stream^.GetPos - Size + K);
       S[0]:=Chr(K - 1);
       EndReached:=True;
       Break;
      end;
    end;

   if S[Byte(S[0])] = ' ' then Dec(S[0]);

   K:=0;
   C:=@S[1];
   repeat
    Inc(K);
    if K > Byte(S[0]) then Break;
    if C^ = #10 then
     begin
      Delete(S, K, 1);
      Continue;
     end;
    Inc(C);
   until False;

   if EndReached then Break;

   cmInsert(Message.Data, cmNewStr(S));
  until False;

  Message.iSize:=Stream^.GetPos - SavedPos;
  StatLoadMessage.Unlock;
 end;}

{ SaveMessage's code }

procedure SaveMessage(const Stream: PStream; var Message: TMessage);
 var
  K: Longint;
  S: String;
 const
  CRLF: Char = #$0D;
  ZERO: Char = #$00;
 begin
  for K:=1 to cmCount(Message.Data) do
   begin
    GetPStringEx(cmAt(Message.Data, K), S);
    Stream^.Write(S[1], Length(S));
    Stream^.Write(CRLF, SizeOf(CRLF));
   end;
  Stream^.Write(ZERO, SizeOf(ZERO));
 end;

{ StringToAddress's code }

procedure StringToAddress(S: String; var Address: TAddress);
 var
  Dots, K: Byte;
 begin
  TrimEx(S);
  S:=ExtractWord(1, S, [' ', '@']);
  Dots:=0;
  for K:=1 to Length(S) do
   case S[K] of
    '.': Inc(Dots);
    '0'..'9', ':', '/':;
   else
    Inc(Dots, 2);
   end;
  if Dots > 1 then
   ClearAddress(Address)
  else
   Str2Address(S, Address);
 end;

{ StringToINTL's code }

procedure StringToINTL(const S: String; var FromAddress, ToAddress: TAddress);
 const
  INTLSet: Set Of Char = ['/', ':', ' '];
 begin
  Str2Longint(ExtractWord(1, S, INTLSet), ToAddress.Zone);
  Str2Longint(ExtractWord(2, S, INTLSet), ToAddress.Net);
  Str2Longint(ExtractWord(3, S, INTLSet), ToAddress.Node);

  Str2Longint(ExtractWord(4, S, INTLSet), FromAddress.Zone);
  Str2Longint(ExtractWord(5, S, INTLSet), FromAddress.Net);
  Str2Longint(ExtractWord(6, S, INTLSet), FromAddress.Node);
 end;

{ CheckLine's code }

function CheckLine(var Message: TMessage; const S: PString): Boolean;
 begin
  CheckLine:=False;
  if S = Nil then Exit;
  if S^[1] <> #1 then
   begin
    CheckLine:=True;
    Exit;
   end;
  if S^[0] < #6 then Exit;
  if Copy(S^, 1, 5) = #1'TOPT' then
   Str2Longint(ExtractWord(2, S^, [' ']), Message.iToAddress.Point) else
  if Copy(S^, 1, 5) = #1'FMPT' then
   Str2Longint(ExtractWord(2, S^, [' ']), Message.iFromAddress.Point) else
  if Copy(S^, 1, 7) = #1'MSGID:' then
   StringToAddress(Copy(S^, 9, 255), Message.iFromAddress) else
  if ScanUseReply and (Copy(S^, 1, 7) = #1'REPLY:') then
   StringToAddress(Copy(S^, 9, 255), Message.iToAddress) else
  if Copy(S^, 1, 5) = #1'INTL' then
   StringToINTL(Copy(S^, 7, 255), Message.iFromAddress, Message.iToAddress);
 end;

{*** LAMBDA CORE :-) ***}

var
 Packet                 : PStream;
 PacketName             : String;

 TempPacket             : PStream;
 TempPacketName         : String;

 TempPacketPresave      : PStream;

 PacketHeader           : TPKTHeader;
 PacketMessage          : TPKTMessage;
 PacketFromAddress      : TAddress;
 PacketToAddress        : TAddress;

 TheWord                : System.Word;

 Good                   : Boolean;

 Message                : TMessage;

 Buffer                 : Pointer;
 BufferSize             : Longint;

 OldProgress            : Longint;

{ __ExportTheMessages's code }

procedure __ExportTheMessages;
 var
  K: Longint;
  Message: PMessage;
 begin
  if sExitNow then
   begin
    lngBegin;
     lngPush(Long2Str(TheQueue^.Count));
     lngPrint('Main', 'scan.unexported.because.exitnow');
    lngEnd;
    TheQueue^.FreeAll;
    Exit;
   end;
  lngBegin;
   lngPush(Long2Str(TheQueue^.Count));
   lngPrint('Main', 'scan.exporting');
  lngEnd;
  for K:=1 to TheQueue^.Count do
   begin
    Message:=TheQueue^.At(K);
    lngBegin;
     lngPush(Message^.iFrom);
     lngPush(Message^.iTo);
     lngPush(Address2Str(Message^.iFromAddress));
     lngPush(Address2Str(Message^.iToAddress));
     lngPush(Message^.iSubj);
     lngPush(Message^.iDate);
     lngPush(Message^.iArea);
     lngPrint('Main', 'scan.exporting.message');
    lngEnd;

    PacketMessage.origNode:=Message^.iFromAddress.Node;
    PacketMessage.origNet:=Message^.iFromAddress.Net;
    PacketMessage.destNode:=Message^.iToAddress.Node;
    PacketMessage.destNet:=Message^.iToAddress.Net;
    PacketMessage.Cost:=0;
    PacketMessage.Attribute:=Message^.iAttributes;

    TheWord:=$0002;
    TempPacket^.Write(TheWord, SizeOf(TheWord));
    TempPacket^.Write(PacketMessage, SizeOf(PacketMessage));

    WriteString(TempPacket, Message^.iDate);
    WriteString(TempPacket, Message^.iTo);
    WriteString(TempPacket, Message^.iFrom);
    WriteString(TempPacket, Message^.iSubj);

    SaveMessage(TempPacket, Message^);
   end;
  TheQueue^.FreeAll;
 end;

{ Broadcast's code }

procedure Broadcast(const Service: Longint; const Buffer: Pointer);
 var
  K: Longint;
 begin
  for K:=1 to PluginsQueue^.Count do
   srvExecuteDirect(PStatPlugin(PluginsQueue^.At(K))^.Plugin, Service, Buffer);
 end;

{ BroadcastEx's code }

procedure BroadcastEx(const Service: Longint; const Buffer: Pointer);
 var
  K: Longint;
  P: PStatPlugin;
 begin
  StatExternal.Lock;

  for K:=1 to PluginsQueue^.Count do
   begin
    P:=PluginsQueue^.At(K);

    P^.Lock;

    srvExecuteDirect(P^.Plugin, Service, Buffer);

    P^.Unlock;
   end;

  StatExternal.Unlock;
 end;

{ __ScanPacket's code }

procedure __ScanPacket(const FName: String);
 var
  MemoryStream: PMemoryStream;
  K, Count: Longint;
  Grunged: Boolean;
  Factor: Real;
  Code: xWord;
  W: Word;
  S: String;
  F: Text;
  WhichRule: (wrFrom, wrTo);
 begin
  mCheckBreak;
  if sExitNow then Exit;

  Count:=0;

  StatInternal.Lock;

  PacketName:=FName;

  Packet:=New(PScanStream, Init(PacketName, stOpenRead));

  if Packet^.Status <> stOk then
   begin
    lngBegin;
     lngPush(JustFileName(PacketName));
     lngPush(Long2Str(Packet^.Status));
     lngPrint('Main', 'Scan.Pkt.Open.Error');
    lngEnd;
    Dispose(Packet, Done);
    Exit;
   end;

  if ScanPreload then
   begin
    lngBegin;
     lngPush(JustFileName(PacketName));
     lngPush(Long2StrFmt(Packet^.GetSize));
     lngPrint('Main', 'Scan.Pkt.Preloading');
    lngEnd;

    StatPreload.Lock;

    MemoryStream:=New(PMemoryStream, Init);

    MemoryStream^.CopyFrom(Packet^, Packet^.GetSize);

    MemoryStream^.Seek(0);

    Dispose(Packet, Done);

    StatPreload.Unlock;

    Packet:=MemoryStream;
   end;

  if ScanRepack then
   begin
    TempPacketName:=ForceExtension(PacketName, 'sk_');

    if ScanPresave then
     begin
      TempPacket:=New(PMemoryStream, Init);

      Val(cGetParam('Scan.Presave.Factor'), Factor, Code);

      if Code <> 0 then
       Factor:=1.0;

      if (Factor <> 1.0) and (Flags and flagsMaxFucktor = 0) then
       begin
        lngBegin;
         lngPush(cGetParam('Scan.Presave.Factor'));
         lngPrint('Main', 'scan.max.fucktor');
        lngEnd;
        Flags:=Flags or flagsMaxFucktor;
       end;

      PMemoryStream(TempPacket)^.SetSize(Round(Packet^.GetSize * Factor));

      lngBegin;
       lngPush(Long2StrFmt(TempPacket^.GetSize));
       lngPrint('Main', 'scan.presave.allocated');
      lngEnd;

      TempPacketPresave:=New(PScanStream, Init(TempPacketName, stCreate));

      if TempPacketPresave^.Status <> stOk then
       begin
        lngBegin;
         lngPush(TempPacketName);
         lngPush(HexL(TempPacketPresave^.Status));
         lngPrint('Main', 'Error.CaNT.Create');
        lngEnd;
        sSetExitNow;
        Dispose(TempPacketPresave, Done);
        Dispose(TempPacket, Done);
        Dispose(Packet, Done);
        Exit;
       end;
     end
    else
     begin
      TempPacket:=New(PScanStream, Init(TempPacketName, stCreate));

      if TempPacket^.Status <> stOk then
       begin
        lngBegin;
         lngPush(TempPacketName);
         lngPush(HexL(TempPacket^.Status));
         lngPrint('Main', 'Error.CaNT.Create');
        lngEnd;

        sSetExitNow;

        Dispose(TempPacket, Done);
        Dispose(Packet, Done);
        Exit;
       end;
     end;
   end;

  lngBegin;
   lngPush(JustFileName(PacketName));
   lngPush(Long2StrFmt(Packet^.GetSize div 1024));
   lngPrint('Main', 'Scan.Pkt.Opened');
  lngEnd;

  Packet^.Read(PacketHeader, SizeOf(PacketHeader));

  { checking for grungity }

  Grunged:=PacketHeader.Version <> 2;

  if Grunged then
   begin
    lngBegin;
     lngPush(HexW(PacketHeader.Version));
     lngPush('0002');

     lngPrint('Main', 'scan.grunged.pv');
    lngEnd;
   end
  else
   begin
    K:=Packet^.GetPos;

    Packet^.Seek(Packet^.GetSize - 2);

    Packet^.Read(W, 2);

    if W <> 0 then
     begin
      Grunged:=True;

      lngBegin;
       lngPush(HexW(W));
       lngPush('0000');

       lngPrint('Main', 'scan.grunged.pe');
      lngEnd;
     end;

    Packet^.Seek(K);
   end;

  if Grunged then
   begin
    lngBegin;
     lngPush(PacketName);

     lngPrint('Main', 'scan.grunged');
    lngEnd;

    if ScanRepack then
     begin
      if ScanPresave then
       Dispose(TempPacketPresave, Done);

      Dispose(TempPacket, Done);

      EraseFile(TempPacketName);
     end;

    Dispose(Packet, Done);

    Exit;
   end;

  { check for twittaz }

  with PacketFromAddress, PacketHeader do
   begin
    Zone:=OrigZone;
    Net:=OrigNet;
    Node:=OrigNode;
    Point:=OrigPoint;
   end;

  with PacketToAddress, PacketHeader do
   begin
    Zone:=DestZone;
    Net:=DestNet;
    Node:=DestNode;
    Point:=DestPoint;
   end;

  Good:=Check2Masks(Address2Str(PacketFromAddress), FromExclude, FromRemain);

  WhichRule:=wrFrom;

  if Good then
   begin
    Good:=Check2Masks(Address2Str(PacketToAddress), ToExclude, ToRemain);

    WhichRule:=wrTo;
   end;

  if not Good then
   begin
    lngBegin;
     lngPush(PacketName);
     lngPush(Address2Str(PacketFromAddress));
     lngPush(Address2Str(PacketToAddress));

     case WhichRule of
      wrFrom: lngPrint('Main', 'scan.reject.by.from');
      wrTo: lngPrint('Main', 'scan.reject.by.to');
     end;
    lngEnd;

    if ScanRepack then
     begin
      if ScanPresave then
       Dispose(TempPacketPresave, Done);

      Dispose(TempPacket, Done);

      EraseFile(TempPacketName);
     end;

    Dispose(Packet, Done);

    Exit;
   end;

  Broadcast(snsPktStart, @PacketName);

  lngBegin;
   lngPush(Address2Str(PacketFromAddress));
   lngPush(Address2Str(PacketToAddress));
   lngPrint('Main', 'Scan.Pkt.Info');
  lngEnd;

  sSetSemaphore('Scanner.Pkt.Info.SourceAddress', Address2Str(PacketFromAddress));
  sSetSemaphore('Scanner.Pkt.Info.DestinationAddress', Address2Str(PacketToAddress));
  sSetSemaphore('Scanner.Pkt.FileName', PacketName);
  sSetSemaphore('Scanner.Pkt.Size', Long2Str(Packet^.GetSize));

  Broadcast(snsPktHeader, @PacketHeader);

  if ScanRepack then
   TempPacket^.Write(PacketHeader, SizeOf(PacketHeader));

  Good:=True;

  repeat
   Packet^.Read(TheWord, SizeOf(TheWord));

   if TheWord = $0000 then Break;

   if TheWord <> $0002 then
    begin
     lngBegin;
      lngPush(HexL(TheWord));
      lngPush(HexL(Packet^.GetPos - $02));
      lngPrint('Main', 'Scan.Pkt.Error.ID');
     lngEnd;
     Good:=False;
     Break;
    end;

   Packet^.Read(PacketMessage, SizeOf(PacketMessage));

   Message.Init;

   Message.iAttributes:=PacketMessage.Attribute;

   ReadString(Packet, Message.iDate);
   ReadString(Packet, Message.iTo);
   ReadString(Packet, Message.iFrom);
   ReadString(Packet, Message.iSubj);

   Message.Kill:=False;

   LoadMessage(Packet, Message);

   GetPStringEx(cmAt(Message.Data, 1), Message.iArea);
   if Copy(Message.iArea, 1, 5) = 'AREA:' then
    Delete(Message.iArea, 1, 5)
   else
    Message.iArea:='NETMAIL';

   Message.Group:=gSearchByArea(Message.iArea);

   ClearAddress(Message.iFromAddress);
   ClearAddress(Message.iToAddress);

   if Message.iArea = 'NETMAIL' then
    for K:=1 to cmCount(Message.Data) do
     if CheckLine(Message, cmAt(Message.Data, K)) then
      Break
     else
   else
    for K:=2 to cmCount(Message.Data) do
     if CheckLine(Message, cmAt(Message.Data, K)) then
      Break;

   sSetSemaphore('Scanner.Message.Kill', '');

   Broadcaster(snsMessage, @Message);

   if ScanRepack and (sGetSemaphore('Scanner.Message.Kill') = '') then
    begin
     TheWord:=$0002;
     TempPacket^.Write(TheWord, SizeOf(TheWord));
     TempPacket^.Write(PacketMessage, SizeOf(PacketMessage));

     WriteString(TempPacket, Message.iDate);
     WriteString(TempPacket, Message.iTo);
     WriteString(TempPacket, Message.iFrom);
     WriteString(TempPacket, Message.iSubj);

     SaveMessage(TempPacket, Message);
    end;

   Message.Done;

   Inc(Count);

   if Count = 4 then
    begin
     K:=Round((Packet^.GetPos + ScanProcessedSize) / ScanTotalSize * 100);

     if OldProgress <> K then
      begin
       if K < 0 then K:=0;
       if K > 100 then K:=100;
       S:=Long2Str(K) + '%';
       sSetSemaphore('Scanner.Pkt.Done', Long2Str(K));
       vSetAttr($0F);
       vPrint(S + PadCh('', #8, Length(S)));
       OldProgress:=K;
      end;

     mCheckBreak;
     Count:=0;
    end;

   if sExitNow then
    begin
     Broadcast(snsWarnStop, Nil);
     lngPrint('Main', 'Scan.Pkt.ExitNow');
     Good:=False;
     Break;
    end;
  until False;

  Inc(ScanProcessedSize, Packet^.GetSize);
  Dispose(Packet, Done);

  StatInternal.Unlock;

  if ScanRepack then
   begin
    if TheQueue^.Count <> 0 then
     __ExportTheMessages;

    TheWord:=$0000;
    TempPacket^.Write(TheWord, SizeOf(TheWord));

    if ScanPresave then
     begin
      StatPresave.Lock;

      PMemoryStream(TempPacket)^.Truncate;

      lngBegin;
       lngPush(Long2StrFmt(TempPacket^.GetSize));
       lngPrint('Main', 'scan.presaving');
      lngEnd;

      TempPacket^.Seek(0);

      TempPacketPresave^.CopyFrom(TempPacket^, TempPacket^.GetSize);

      StatPresave.Unlock;

      Dispose(TempPacketPresave, Done);
     end;

    Dispose(TempPacket, Done);

    if sExitNow or (not Good) or cGetBoolParam('Debug.Scan.DontKill') then Exit;

    if IOResult <> 0 then;
    Assign(F, PacketName);
    Erase(F);
    if InOutRes <> 0 then
     begin
      lngBegin;
       lngPush(PacketName);
       lngPush(HexL(IOResult));
       lngPrint('Main', 'error.cant.delete');
      lngEnd;
      sSetExitNow;
      Exit;
     end;
    Assign(F, TempPacketName);
    Rename(F, PacketName);
    if InOutRes <> 0 then
     begin
      lngBegin;
       lngPush(PacketName);
       lngPush(HexL(IOResult));
       lngPrint('Main', 'error.cant.rename');
      lngEnd;
      sSetExitNow;
      Exit;
     end;
   end
  else
   if TheQueue^.Count <> 0 then
    begin
     lngPrint('Main', 'Scan.Cannot.Export');
     TheQueue^.FreeAll;
    end;

  if cGetBoolParam('Scan.Kill.Packets') then
   begin
    lngBegin;
     lngPush(PacketName);
     if IOResult <> 0 then;
     Assign(F, PacketName);
     Erase(F);
     if InOutRes = 0 then
      lngPrint('Main', 'scan.killed')
     else
      begin
       lngPush(HexL(IOResult));
       lngPrint('Main', 'error.cant.delete');
      end;
    lngEnd;
   end;
 end;

end.
