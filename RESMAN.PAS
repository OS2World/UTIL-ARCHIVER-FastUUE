uses
{$IFDEF WIN32}
     Windows,
{$ENDIF}
     Types,
     FileLib,
{$IFDEF VIRTUALPASCAL}
     Crt,
{$Else}
     Crt_p2,
{$EndIf}
{$IfDef OS2}
     Os2Base,
{$EndIf}
     Wizard;

const
 Version = '1.0';
{$IfDef Win32}
 OS = 'Win32';
{$EndIf}
{$IfDef OS2}
 OS = 'OS/2';
{$EndIf}
{$IfDef DPMI}
 OS = 'DOS';
{$EndIf}

 QuietMode: Boolean = False;
 StdOut: Boolean = False;
 Code: Integer = 0;

type
 TResManLibrary = object(TLibrary)
  procedure Debug(const S: String); virtual;
 end;

procedure TResManLibrary.Debug(const S: String);
 begin
 end;

var
 RF: TResManLibrary;

{
 mCheckWildcard: Alexander Starostin, 2:5020/1297.153, 22 ˆî« 98, 23:40:30.
}

const
 ItsFirst: integer = 0;

function mCheckWildcard(S, Mask: String): Boolean;
 var
  I: Integer;
  J: Integer;
  Ok: Boolean;
  St: String;
  Msk: String;
 begin
  Inc(ItsFirst);
  I:=1;
  if ItsFirst=1 then
   begin
    while True do
     begin
      J:=Length(Mask);
      while I<Length(Mask) do
       begin
        if (Mask[I]='?') And (Mask[I+1]='*') Then Delete(Mask,I,1);
        if (Mask[I]='*') And (Mask[I+1]='?') And (I<Length(Mask)) Then Delete(Mask,I+1,1);
        If (Mask[I]='*') And (Mask[I+1]='*') And (I<Length(Mask)) Then Delete(Mask,I,1);
        Inc(I);
       end;
      if J=Length(Mask) then Break;
      I:=1;
     end;
   end;
  Ok:=True;
  I:=1;
  J:=1;
  while True do
   begin
    case Mask[I] Of
    '*':
      Begin
        Msk:=Copy(Mask,I+1,Length(Mask)-I+1);
        St:=Copy(S,J,Length(S)-J+1);
        while (St<>'') and (not mCheckWildcard(St,Msk)) do Delete(St,1,1);
        If (St='') and (Msk<>'') then Ok:=False else J:=Pos(St,S);
      End;
    '?':
      Begin
        If (I=Length(Mask)) And (J<Length(S)) Then Ok:=False;
        If J>Length(S) Then Ok:=False;
        Inc(J);
      End;
    else
     if Mask[I]<>S[J] then Ok:=False else Inc(J);
    end;
    if J-1>Length(S) then Ok:=False;
    if not Ok then Break;
    Inc(I);
    if I>Length(Mask) then Break;
   end;
  mCheckWildcard:=Ok;
  Dec(ItsFirst);
 end;

{$IfDef DPMI}
procedure PrintStr(const S: String); assembler;
 asm
        PUSH    DS
        LDS     SI,S
        CLD
        LODSB
        XOR     AH,AH
        XCHG    AX,CX
        MOV     AH,40H
        MOV     BX,1
        MOV     DX,SI
        INT     21H
        POP     DS
 end;
{$EndIf}
{$IfDef OS2}
procedure PrintStr(const S: String);
 var
  WCount: Longint;
 begin
  DosWrite(1, S[1], Length(S), WCount);
 end;
{$EndIf}

procedure Write(const S: String);
 begin
  if QuietMode then Exit;
  if not StdOut then
   begin
    System.Write(S);
    Exit;
   end;
  {$IfDef Win32}
  System.Write(S);
  {$Else}
  PrintStr(S);
  {$EndIf}
 end;

procedure WriteLn(const S: String);
 begin
  Write(S);
  Write(#13#10);
 end;

procedure SetAttr(NewAttr: Byte);
 begin
  if QuietMode or StdOut then Exit;
  TextAttr:=NewAttr;
 end;

procedure Title;
 begin
  if (not QuietMode) and (not StdOut) then
   begin
    SetAttr($07);
    ClrScr;
   end;
  SetAttr($0F); WriteLn('FastUUE Resource Manager/' + OS + ', v' + Version + ', (c) by sk // [rAN] [2:5033/27], 1998-99.');
  SetAttr($07); WriteLn('');
 end;

procedure ListResources(var Mask: String);
 var
  K, Count: Longint;
  I: PItem;
 begin
  if Mask = '' then Mask:='*';
  SetAttr($0E); WriteLn('List of resources "' + Mask + '".');
  SetAttr($07); WriteLn('');
  SetAttr($0A); WriteLn('Total: ' + Long2Str(RF.Index^.Count) + ' resource(s).');
  SetAttr($07); WriteLn('');

  StUpcaseEx(Mask);

  Count:=0;

  for K:=1 to RF.Index^.Count do
   begin
    I:=RF.Index^.At(K);
    if mCheckWildCard(StUpcase(I^.Name), Mask) then
     begin
      Inc(Count);
      if Count = 1 then
       begin
        SetAttr($0F);
        WriteLn(Pad('Resource Name', 58) + ' ID  Offset    Size  ');
       end;
      SetAttr($07);
      WriteLn(Pad(I^.Name, 58) + ' ' + HexB(I^.Id) + ' ' + HexL(I^.Offset) + ' ' + HexL(I^.Size));
     end;
   end;

  if Count <> 0 then
   begin
    SetAttr($07); WriteLn('');
   end;
  SetAttr($0E); WriteLn('Found ' + Long2Str(Count) + ' resource(s).');
  SetAttr($07); WriteLn('');
 end;

procedure ExportResources(var CommandLine: String);
 var
  Mask, Destination, FName: String;
  S: TDosStream;
  K, Count: Longint;
  I: PItem;
 begin
  Mask:=ExtractWord(1, CommandLine, [' ']);
  Destination:=AddBackSlash(ExtractWord(2, CommandLine, [' ']));

  SetAttr($0E); WriteLn('Exporting resources "' + Mask + '" to "' + Destination + '".');
  SetAttr($07); WriteLn('');
  SetAttr($0A); WriteLn('Total: ' + Long2Str(RF.Index^.Count) + ' resource(s).');
  SetAttr($07); WriteLn('');

  StUpcaseEx(Mask);

  Count:=0;

  for K:=1 to RF.Index^.Count do
   begin
    I:=RF.Index^.At(K);
    if mCheckWildCard(StUpcase(I^.Name), Mask) then
     begin
      Inc(Count);
      if Count = 1 then
       begin
        SetAttr($0F);
        WriteLn(Pad('Resource Name', 58) + ' ID  Offset    Size  ');
       end;
      FName:=Destination + HexL(Count) + '.Dat';
      SetAttr($07);
      WriteLn(Pad(I^.Name, 58) + ' ' + HexB(I^.Id) + ' ' + HexL(I^.Offset) + ' ' + HexL(I^.Size));
      Write(' ... ' + FName);
      S.Init(FName, stCreate);
      if S.Status <> stOk then
       WriteLn(': cannot create, rc#' + Long2Str(S.Status))
      else
       begin
        RF.GetResource(I^.Name, @S);
        WriteLn(': ' + Long2StrFmt(I^.Size) + ' byte(s)');
       end;
      S.Done;
     end;
   end;

  if Count <> 0 then
   begin
    SetAttr($07); WriteLn('');
   end;

  SetAttr($0E); WriteLn('Found ' + Long2Str(Count) + ' resource(s).');
  SetAttr($07); WriteLn('');
 end;

procedure ImportResource(var CommandLine: String);
 var
  ResName, FileName: String;
  B: TBufStream;
 begin
  ResName:=ExtractWord(1, CommandLine, [' ']);
  FileName:=ExtractWord(2, CommandLine, [' ']);

  SetAttr($0E); WriteLn('Importing resource "' + ResName + '" from "' + FileName + '".');
  SetAttr($07); WriteLn('');

  B.Init(FileName, stOpenRead, 2048);

  if B.Status <> stOk then
   begin
    SetAttr($0C); WriteLn('Cannot open "' + FileName + '", rc=#' + Long2Str(B.Status) + '.');
    SetAttr($07); WriteLn('');
   end
  else
   begin
    SetAttr($0F); WriteLn('Importing ' + Long2StrFmt(B.GetSize) + ' byte(s)...');
    RF.AddResource(ResName, @B, B.GetSize);
    SetAttr($07); WriteLn('');
   end;

  B.Done;
 end;

procedure KillResources(var Mask: String);
 var
  K, Count: Longint;
  I: PItem;
 begin
  if Mask = '' then Mask:='*';
  SetAttr($0E); WriteLn('Killing resources "' + Mask + '".');
  SetAttr($07); WriteLn('');
  SetAttr($0A); WriteLn('Total: ' + Long2Str(RF.Index^.Count) + ' resource(s).');
  SetAttr($07); WriteLn('');

  StUpcaseEx(Mask);

  Count:=0;

  K:=0;
  repeat
   Inc(K);
   if K > RF.Index^.Count then Break;
   I:=RF.Index^.At(K);
   if mCheckWildCard(StUpcase(I^.Name), Mask) then
    begin
     Inc(Count);
     if Count = 1 then
      begin
       SetAttr($0F);
       WriteLn(Pad('Resource Name', 58) + ' ID  Offset    Size  ');
      end;
     SetAttr($07);
     WriteLn(Pad(I^.Name, 58) + ' ' + HexB(I^.Id) + ' ' + HexL(I^.Offset) + ' ' + HexL(I^.Size));
     Write(' ... killing');
     RF.KillResource(I^.Name);
     WriteLn('');
     Dec(K);
    end;
  until False;

  if Count <> 0 then
   begin
    SetAttr($07); WriteLn('');
   end;

  SetAttr($0E); WriteLn('Killed ' + Long2Str(Count) + ' resource(s).');
  SetAttr($07); WriteLn('');
 end;

procedure PackResource(var TempFile: String);
 var
  B: TBufStream;
  F: File;
 begin
  if TempFile = '' then
   begin
    SetAttr($0C); WriteLn('You must specify temp-filename.');
    SetAttr($07); WriteLn('');
    Exit;
   end;

  B.Init(TempFile, stCreate, 2048);

  if B.Status <> stOk then
   begin
    SetAttr($0C); WriteLn('Cannot create "' + TempFile + '", rc=#' + Long2Str(B.Status) + '.');
    SetAttr($07); WriteLn('');
   end
  else
   begin
    SetAttr($0E); WriteLn('Packing resourcefile with "' + TempFile + '"...');
    RF.Pack(@B);
    SetAttr($07); WriteLn('');

    {$I-}
    if IOResult <> 0 then;
    Assign(F, TempFile);
    Erase(F);
    if IOResult <> 0 then;
   end;

  B.Done;
 end;

procedure GoExit;
 begin
  SetAttr($0A);
  Write(#13 + 'Exiting with errorlevel ' + Long2Str(Code));
  SetAttr($07);
  if (not StdOut) and (not QuietMOde) then
   ClrEol;
  WriteLn('');
  Halt(Code);
 end;

var
 Command, Params, ResFile: String;
 K, Base: Integer;
begin
{$IFDEF WIN32}
 SetFileApisToOem;
{$ENDIF}

 Base:=1;

 for K:=1 to ParamCount do
  begin
   Command:=ParamStr(K);
   TrimEx(Command);
   StUpcaseEx(Command);
   if (Command[0] = #0) then Break;
   if not (Command[1] in ['-', '/']) then
    begin
     Base:=K;
     Break;
    end;
   Delete(Command, 1, 1);
   if Command = 'Q' then QuietMode:=True else
   if Command = 'S' then StdOut:=True else
    begin
     QuietMode:=False;
     StdOut:=False;
     Title;
     SetAttr($0C); WriteLn('Unknown switch "' + ParamStr(K) + '".');
     SetAttr($07); WriteLn('');
     Code:=254;
     GoExit;
    end;
  end;

 if QuietMode and StdOut then
  begin
   QuietMode:=False;
   StdOut:=False;
   Title;
   SetAttr($0C); WriteLn('You must use only one switch of the following: /S, /Q.');
   SetAttr($07); WriteLn('');
   Code:=253;
   GoExit;
  end;

 Title;

 ResFile:=ParamStr(Base);

 Command:=StUpcase(Trim(ParamStr(Base + 1)));

 Params:=ParamStr(Base + 2);
 for K:=Base + 3 to ParamCount do
  Params:=Params + ' ' + ParamStr(K);

 repeat
  if (Command = '') or (Command = '?') then
   begin
    WriteLn('Usage: ResMan [Switches] ResourceFile Command [Params]');
    WriteLn('');
    WriteLn('ResMan RF Export Mask Destination\');
    WriteLn('ResMan RF Import ResourceName Dir\Source.Ext');
    WriteLn('ResMan RF List Mask');
    WriteLn('ResMan RF Kill Mask');
    WriteLn('ResMan RF Pack TempFile');
    WriteLn('');
    WriteLn('Switches:');
    WriteLn(' /Q    disable all messages [quiet]');
    WriteLn(' /S    disable colors and write all messages to stdout');
    WriteLn('');
    Code:=255;
    Break;
   end;

  SetAttr($0A); WriteLn('Using "' + ResFile + '" as resourcefile.');
  SetAttr($07); WriteLn('');

  RF.Init(ResFile);
  if RF.Error then
   begin
    SetAttr($0C); WriteLn('Error: ' + RF.ErrorString);
    SetAttr($07); WriteLn('');
    Break;
   end;

  if (Command = 'LIST') then ListResources(Params) else
  if (Command = 'EXPORT') then ExportResources(Params) else
  if (Command = 'IMPORT') then ImportResource(Params) else
  if (Command = 'KILL') then KillResources(Params) else
  if (Command = 'PACK') then PackResource(Params) else
   begin
    SetAttr($0C); WriteLn('Unknown command "' + Command + '".');
    SetAttr($07); WriteLn('');
   end;
  RF.Done;
 until True;

 GoExit;
end.
