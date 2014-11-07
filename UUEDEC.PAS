unit uueDec;

{$IFDEF VIRTUALPASCAL}
 {$DEFINE USEUNITS}
{$ENDIF}
{$IFDEF SOLID}
 {$DEFINE USEUNITS}
{$ENDIF}

interface

uses
{$IFDEF USEUNITS}
     Misc, Language, Semaphor, Plugins, Config, Video, Division, Resource,
{$ELSE}
     Decl,
{$ENDIF}
     Consts_,
     Dos, Wizard, Types,
     uueOver,
     Core;

procedure __Decode;

implementation

var
 Files: PCollection;
 Group: PStrings;
 KeepDays: Longint;

{$I COMMON.INC}
{$I FILES.INC}
{$I FILESBBS.INC}
{$I HATCHER.INC}
{$I ANNOUNCE.INC}
{$I THEDUPE.INC}

{ Files support }

procedure SeekFile(Filename, Area: String; var F: PFile);
 var
  K: Longint;
 begin
  StUpcaseEx(Filename);
  StUpcaseEx(Area);

  for K:=1 to Files^.Count do
   begin
    F:=Files^.At(K);

    if (Filename = StUpcase(F^.Filename)) and (Area = StUpcase(F^.Area)) then
     Exit;
   end;

  F:=Nil;
 end;

{ __Analyze }

procedure __Analyze;
 var
  K, L, Current, Total, Good, Valid: Longint;
  S, Filename, Area: String;
  F: PFile;
  Section: PSection;
 begin
  lngPrint('Main', 'uue.analyzing.index');

  Valid:=0;
  Good:=0;

  for K:=1 to rGetIndexSize do
   begin
    S:=rGetIndexName(K);

    if not ParseName(S, Current, Total, Filename, Area) then Continue;

    Inc(Valid);

    SeekFile(Filename, Area, F);

    if F = Nil then
     begin
      Section:=New(PSection, Init);

      Section^.Load(QueryName(Current, Total, Filename, Area));

      if Section^.Error then
       Section^.iDate:=TimeFix;

      F:=New(PFile, Init(Filename, Section^.iArea, 0, Total, Section^.iDate, 0));
      Files^.Insert(F);

      Dispose(Section, Done);
     end;

    Inc(F^.Count);
    if Current > F^.Max then F^.Max:=Current;
    if Total > F^.Max then F^.Max:=Total;
   end;

  K:=0;
  repeat
   mCheckBreak;
   if sExitNow then Break;

   Inc(K);
   if K > Files^.Count then Break;

   F:=Files^.At(K);

   if F^.Total = 0 then
    for L:=1 to F^.Count do
     if not rExist(QueryName(L, F^.Total, F^.Filename, F^.Area)) then
      F^.Bad:=True
     else
   else
    if F^.Count <> F^.Total then
     F^.Bad:=True;

   Group:=gSearchByArea(F^.Area);

   if Group = Nil then
    begin
     lngBegin;
      lngPush(F^.Area);
      lngPrint('Main', 'uue.trying.group');
     lngEnd;
     F^.Bad:=True;
     Continue;
    end;

   KeepDays:=gGetDoubleNumParam(Group, 'uue.KeepDays');

   if KeepDays = 0 then
    KeepDays:=-1;

   if F^.Bad then
    begin
     lngBegin;
      lngPush(F^.FileName);
      lngPush(Long2Str(F^.Count));
      lngPush(Long2Str(F^.Total));
      lngPush(Long2Str(QueryTimeDifference(F)));
      lngPush(Long2Str(KeepDays));
      lngPrint('Main', 'uue.incomplete.file');
     lngEnd;
    end
   else
    begin
     Inc(Good);
     lngBegin;
      lngPush(F^.FileName);
      lngPush(Long2Str(F^.Count));
      lngPush(Long2Str(F^.Total));
      lngPush(Long2Str(QueryTimeDifference(F)));
      lngPush(Long2Str(KeepDays));
      lngPrint('Main', 'uue.complete.file');
     lngEnd;
    end;
  until False;

  if sExitNow then
   lngPrint('Main', 'uue.analyzing.screwed')
  else
   begin
    lngBegin;
     lngPush(Long2Str(Valid));
     lngPush(Long2Str(Good));
     lngPush(Long2Str(Files^.Count - Good));
     lngPrint('Main', 'uue.analyzing.done');
    lngEnd;
   end;
 end;

{ __Dump }

const
 dfExpired              = 1;
 dfBad                  = 2;

procedure __Dump(const F: PFile; const Reason: Longint);
 var
  S, SOld, ReasonS: String;
  T: Text;
  K, L, DumpCount: Longint;
  Section: PSection;
  dmp83: Boolean;
  Day, Month, Year: Word;
 begin
  if not cGetBoolParam('uue.BadFiles') then Exit;

  dmp83:=_83 or cGetBoolParam('uue.BadFiles.83');

  S:=uCheckBadFName(F^.Filename);
  if dmp83 then S:=uLFNto83(S);

  S:=AddBackSlash(Trim(cGetParam('uue.BadFiles.Dir')))+S;
  
  if cGetBoolParam('uue.BadFiles.Extended') and not dmp83 then
  begin
   iWannaDate (Day, Month, Year);
   S:=S+'.'+LeftPadCh(Long2Str(Day), '0', 2)+LeftPadCh(Long2Str(Month), '0', 2)+
            LeftPadCh(Long2Str(Year), '0', 4)+'.dmp';
  end
  else
   S:=ForceExtension(S, 'dmp');

  if cGetBoolParam('uue.BadFiles.Serial') then 
  begin
   DumpCount:=0;
   SOld:=S;
   while (ExistFile(S)) do 
   begin
    inc(DumpCount);
    S:=uChangeFilename(SOld, DumpCount, dmp83);
   end;
  end;

  mCreate(JustPathname(S));

  case Reason of
   dfExpired: ReasonS:='expired';
   dfBad:     ReasonS:='bad';
  else
   ReasonS:='unknown';
  end;

  lngBegin;
   lngPush(F^.Filename);
   lngPush(ReasonS);
   lngPrint('Main', 'uue.badfiles.dumping');
  lngEnd;

  if IOResult <> 0 then;

  Assign(T, S);
  Rewrite(T);

  if InOutRes <> 0 then
   begin
    lngBegin;
     lngPush(S);
     lngPush(Long2Str(IOResult));
     lngPrint('Main', 'error.cant.create');
    lngEnd;
    Exit;
   end;

  WriteLn(T, '| Dumped at ', GetPktDateTime);
  WriteLn(T, '| File info:');
  WriteLn(T, '|  .. bad: ', F^.Bad);
  WriteLn(T, '|  .. fname: "', F^.Filename, '"');
  WriteLn(T, '|  .. area: "', F^.Area, '"');
  WriteLn(T, '|  .. count: ', F^.Count);
  WriteLn(T, '|  .. total: ', F^.Total);
  WriteLn(T, '|  .. date: ', HexL(F^.Date), ', cur: ', HexL(TimeFix));
  WriteLn(T, '|  .. max: ', F^.Max);
  WriteLn(T, '|  .. reason: ', ReasonS, ' (code: ',Reason,')');
  WriteLn(T, '');

  K:=0;
  repeat
   Inc(K);
   if K > F^.Max then Break;

   S:=QueryName(K, F^.Total, F^.Filename, F^.Area);
   if not rExist(S) then
    WriteLn(T, '| section ', K, ' of ', F^.Max, ' is absent [resource "', S, '"]')
   else
    begin
     WriteLn(T, '| dump of section ', K, ' of ', F^.Max);

     Section:=New(PSection, Init);
     Section^.Load(S);

     L:=0;
     repeat
      Inc(L);
      if L > Section^.Data^.Count then Break;

      GetPStringEx(Section^.Data^.At(L), S);
      WriteLn(T, S);
     until False;

     WriteLn(T, '');

     Dispose(Section, Done);
    end;
  until False;

  WriteLn(T, '| end');

  Close(T);
  if IOResult <> 0 then;
 end;

{ __KillInResource }

procedure __KillInResource(const F: PFile);
 var
  K: Longint;
 begin
  if cGetBoolParam('debug.uue.dontkill') then Exit;

  for K:=1 to F^.Max do
   rDelete(QueryName(K, F^.Total, F^.VirginFilename, F^.Area));
 end;

{ __DecodeFile }

procedure __DecodeMessage(const MessageID: String; const F: PFile);
 begin
  lngBegin;
   lngPush(F^.Filename);
   lngPrint('Main', MessageID);
  lngEnd;
 end;

function __CalcCRC(Crc: Word; NextByte: Byte): Word; assembler;
 asm
  mov ax, Crc
  ror ax, 1
  mov cl, NextByte
  xor ch, ch
  add ax, cx
 end;

const
 DecodeBufSize = {$IFDEF DPMI} 63 * 1024 {$ELSE}
                               128 * 1024 {$ENDIF};

type
 PDecodeBuffer = ^TDecodeBuffer;
 TDecodeBuffer = array[1..DecodeBufSize] of byte;

const
 DecodeBuffer: PDecodeBuffer = Nil;

var
 DecodeLine: String;
 DecodeLineLo: String;
 DecodeByte: Byte;

 { decoder's stuff }
 DecodeMode, DecodeCRC, DecodeFileCRC: Word;
 DecodeBufPos: Longint;
 DecodeFile: PStream;

procedure __DecodeFlushByte;
 begin
  Inc(DecodeBufPos);

  DecodeBuffer^[DecodeBufPos]:=DecodeByte;

  DecodeFileCRC:=__CalcCRC(DecodeFileCRC, DecodeByte);

  if DecodeBufPos = DecodeBufSize then
   begin
    DecodeFile^.Write(DecodeBuffer^, DecodeBufPos);

    DecodeBufPos:=0;
   end;
 end;

procedure __DecodeLine;
 var
  M: Boolean;
  Kx, Lx: Word;
 begin
  M:=DecodeMode = 3;

  if DecodeMode = 3 then
   DecodeMode:=0;

  DecodeLineLo:=StLoCase(DecodeLine);

  if Copy(DecodeLineLo, 1, 6) = 'begin ' then
   begin
    DecodeMode:=1;
    Exit;
   end;

  if Copy(DecodeLineLo, 1, 12) = 'sum -r/size ' then
   begin
    if Pos('entire', DecodeLineLo) <> 0 then
     Str2Word(ExtractWord(4, DecodeLine, [' ','/']), DecodeCRC);
    Exit;
   end;

  if Copy(DecodeLineLo, 1, 9) = 'filetime ' then
   Exit;

  if Copy(DecodeLineLo, 1, 5) = 'table' then
   begin
    DecodeMode:=3;
    Exit;
   end;

  if Copy(DecodeLineLo, 1, 8) = 'section ' then Exit;

  if Copy(DecodeLineLo, 1, 3) = 'end' then
   begin
    DecodeMode:=2;
    Exit;
   end;

  if (DecodeLine = '`') or (DecodeLine = '``') then
   Exit;

  if (DecodeLine = '') then
   Exit;

  if M then
   begin
    DecodeMode:=3;
    Exit;
   end;

  if not IsUUE(DecodeLine) then
   Exit;

  for Kx:=1 to Length(DecodeLine) do
   if DecodeLine[Kx]='`' then
    DecodeLine[Kx]:=' ';

  Lx:=Byte(DecodeLine[1]) - 32;

  {$IFDEF VIRTUALPASCAL}
   asm
   {&Alters edi,ebx,ecx}
    mov      kx, 0

   @@MainLoop:
    inc      kx
    mov      ax, kx

    cmp      ax, lx
    jg       @@MainLoopEnd

    mov     edi, offset decodeline

    dec     ax
    mov     bl, 4
    imul    bl
    mov     bl, 3
    idiv    bl
    mov     cl, ah
    xor     ah, ah
    add     ax, 2
    mov     bx, 0
    push    bx
    push    ax
    pop     eax

    add     edi, eax
    mov     ax, [edi]
    xchg    al, ah
    sub     ax, 2020h
    shl     ah, 2
    mov     bl, al
    shr     bl, 4
    or      ah, bl
    shl     al, 4
    shl     cl, 1
    shl     ax, cl

    mov     DecodeByte, ah
    call    __DecodeFlushByte

    jmp     @@MainLoop

   @@MainLoopEnd:
   end;
  {$ELSE}
  asm
   mov     kx, 0

  @@MainLoop:
   inc     kx
   mov     ax, kx

   cmp     ax, lx
   jg      @@MainLoopEnd

   push    seg decodeline
   pop     es
   mov     di, offset decodeline

   mov     ax, kx
   dec     ax
   mov     bl,4
   imul    bl
   mov     bl,3
   idiv    bl
   mov     cl,ah
   xor     ah,ah
   add     ax,2
   add     di,ax

   mov     ax,es:[di]

   xchg    al,ah
   sub     ax,2020h
   shl     ah,2
   mov     bl,al
   shr     bl,4
   or      ah,bl
   shl     al,4
   shl     cl,1
   shl     ax,cl

   mov     DecodeByte, ah
   call    __DecodeFlushByte

   jmp     @@MainLoop

  @@MainLoopEnd:
  end;
  {$ENDIF}
 end;

function __DecodeFile(const F: PFile): Boolean;
 var
  K, L: Longint;
  Section: PSection;
 begin
  Section:=New(PSection, Init);

  GetMem(DecodeBuffer, DecodeBufSize);

  __DecodeMessage('uue.trying', F);

  DecodeFile:=New(PDosStream, Init(uueTempFileName, stCreate));
  
  __DecodeFile:=False;

  DecodeMode:=0;
  DecodeCRC:=0;
  DecodeFileCRC:=0;
  DecodeBufPos:=0;

  K:=0;
  repeat
   Inc(K);

   if K > F^.Max then Break;

   Section^.Load(QueryName(K, F^.Total, F^.Filename, F^.Area));

   if (Section^.Current <> K) or
      (Section^.Total <> F^.Total) or
      (Section^.Error) or
      (Section^.Version <> uueResourceVersion) then
       begin
        lngBegin;
         lngPush(F^.Filename);
         lngPush(Long2Str(K));
         lngPush(Long2Str(Section^.Current));
         lngPush(Long2Str(F^.Total));
         lngPush(Long2Str(Section^.Total));
         lngPush('-');
         lngPush('-');
         lngPush(HexL(Section^.Version));
         lngPush(HexL(uueResourceVersion));
         lngPrint('Main','uue.trying.section.error');
        lngEnd;

        FreeMem(DecodeBuffer, DecodeBufSize);

        Dispose(DecodeFile, Done);
        Exit;
       end;

   L:=0;
   repeat
    Inc(L);

    if L > Section^.Data^.Count then Break;

    GetPStringEx(Section^.Data^.At(L), DecodeLine);

    __DecodeLine;
   until False;
  until False;

  if (DecodeCRC <> DecodeFileCRC) and (DecodeCRC <> 0) then
   begin
    lngBegin;
     lngPush(F^.Filename);
     lngPush(HexW(DecodeFileCRC));
     lngPush(HexW(DecodeCRC));
     lngPrint('Main','uue.trying.section.crc');
    lngEnd;
   end
  else
   begin
    __DecodeMessage('uue.trying.done', F);
    __DecodeFile:=True;
   end;

  if DecodeBufPos <> 0 then
   DecodeFile^.Write(DecodeBuffer^, DecodeBufPos);

  Dispose(DecodeFile, Done);

  FreeMem(DecodeBuffer, DecodeBufSize);

  Dispose(Section, Done);
 end;

{ __ProcessFile }

type
 TOriginal = record
  FileName: String;
  CRC, Size: Longint;
  FilesBBS, Hatcher: String;
 end;

var
 D: Pointer;
 Ok: Boolean;
 Original: TOriginal;
 OrderedToDestroy: Boolean;

procedure ___Parse(const D: Pointer);
 begin
  diSetBool(D, 'uue\decoder\Parsed', True);

  diSetBool(D, 'uue\decoder\CheckDupes', gGetDoubleBoolParam(Group, 'uue.CheckDupes'));
  diSetBool(D, 'uue\decoder\CheckDupes\Memorize', gGetDoubleBoolParam(Group, 'uue.CheckDupes.Memorize'));
  diSetBool(D, 'uue\decoder\83', gGetDoubleBoolParam(Group, 'uue.83'));

  gProcessList(Group, 'uue.put.filesbbs.lines', diCreateList(D, 'uue\decoder\put\bbs'));
  gProcessList(Group, 'uue.put.fileiddiz.lines', diCreateList(D, 'uue\decoder\put\diz'));
  gProcessList(Group, 'uue.put.dirdesc.lines', diCreateList(D, 'uue\decoder\put\dirdesc'));

  gProcessList(Group, 'uue.hatch.tic.lines', diCreateList(D, 'uue\decoder\hatch\tic'));
  gProcessList(Group, 'uue.hatch.fileiddiz.lines', diCreateList(D, 'uue\decoder\hatch\diz'));

  gProcessList(Group, 'uue.list.announcer.merge', diCreateList(D, 'uue\decoder\list\announce\merge'));
 end;

function __CopyFile(const Source, Destination: String): Boolean;
 var
  B1, B2: PDosStream;
 begin
  mCreate(JustPathName(Source));
  mCreate(JustPathName(Destination));

  __CopyFile:=False;

  repeat
   B1:=New(PDosStream, Init(Source, stOpenRead));
   B2:=Nil;

   if B1^.Status <> stOk then
    begin
     lngBegin;
      lngPush(Source);
      lngPrint('Main','uue.copy.source.error');
     lngEnd;
     Break;
    end;

   B2:=New(PDosStream, Init(Destination, stCreate));
   if B2^.Status <> stOk then
    begin
     lngBegin;
      lngPush(Destination);
      lngPrint('Main','uue.copy.destination.error');
     lngEnd;
     Break;
    end;

   B2^.CopyFrom(B1^, B1^.GetSize);

   __CopyFile:=True;
  until True;

  Dispose(B1, Done);

  if B2 <> Nil then
   Dispose(B2, Done);
 end;

procedure __LocalStringsToGlobalStrings(const Local, Global: PStrings);
 var
  K: Longint;
  S: String;
 begin
  cmFreeAll(Global);

  for K:=1 to Local^.Count do
   begin
    GetPStringEx(Local^.At(K), S);

    cmInsert(Global, cmNewStr(S));
   end;
 end;

procedure ___FilesBBS(const F: PFile; const Section: PSection);
 procedure __SS(const Key, Value: String);
  begin
   sSetSemaphore('FilesBBS.FileInfo.' + Key, Value);
  end;
 procedure __SSg(const Key, Source: String);
  begin
   sSetSemaphore('FilesBBS.FileInfo.' + Key, gGetParam(Group, Source));
  end;
 var
  K: Longint;
 begin
  __LocalStringsToGlobalStrings(Section^.Inf, diCreateList(D, 'uue\decoder\put\inf'));

  __SS('Area', Section^.iArea);
  __SS('Sender.Name', Section^.iFrom);
  __SS('Sender.Address', Section^.iFromAddress);
  __SS('Receiver.Name', Section^.iTo);
  __SS('Receiver.Address', Section^.iToAddress);
  __SS('Subject', Section^.iSubj);
  __SS('BBSLines', HexPtr(diCreateList(D, 'uue\decoder\put\bbs')));
  __SS('TempFilename', uueTempFilename);
  __SS('Filename', F^.Filename);
  __SS('DirFilename', gGetParam(Group, 'uue.put.directory'));

  if gGetBoolParam(Group, 'uue.put.filesbbs') then
   begin
    __SSg('FilesBBS', 'uue.put.filesbbs.name');
    __SSg('DirFilesBBS', 'uue.put.filesbbs.directory');
   end
  else
   begin
    __SS('FilesBBS', '');
    __SS('DirFilesBBS', '');
   end;

  __SSg('Packer', 'uue.put.packer');

  if gGetParam(Group, 'uue.put.repacker') = '' then
   begin
    __SS('Repacker', '');
    __SS('Convert', '');
   end
  else
   begin
    __SSg('Repacker', 'uue.put.repacker');
    __SS('Convert', 'Yes');
   end;

  if gGetBoolParam(Group, 'uue.put.inf') then
   begin
    __SS('Inf', 'Yes');
    __SSg('PackInf', 'uue.put.inf.pack');
    __SS('Inf.Lines', HexPtr(diCreateList(D, 'uue\decoder\put\inf')));
    __SSg('Inf.Name', 'uue.put.inf.name');
    __SSg('Inf.Dir', 'uue.put.inf.directory');
   end
  else
   __SS('Inf', 'No');

  if gGetBoolParam(Group, 'uue.put.fileiddiz') then
   begin
    __SS('File_Id.Diz', 'Yes');
    __SS('File_Id.Diz.Lines', HexPtr(diCreateList(D, 'uue\decoder\put\diz')));
    __SSg('File_Id.Diz.Name', 'uue.put.fileiddiz.name');
   end
  else
   __SS('File_Id.Diz', 'No');

  if gGetBoolParam(Group, 'uue.Put.List') then
   begin
    __SS('List', 'Yes');
    __SSg('List.FileName', 'uue.Put.List.FileName');
   end
  else
   __SS('List', 'No');

  if gGetBoolParam(Group, 'uue.Put.DirDesc') then
   begin
    __SS('DirDesc', 'Yes');
    __SSg('DirDesc.FileName', 'uue.Put.DirDesc.FileName');
    __SS('DirDesc.Lines', HexPtr(diCreateList(D, 'uue\decoder\put\dirdesc')));
   end
  else
   __SS('DirDesc', 'No');

  __SSg('CheckDupes', 'uue.put.checkdupes');
  __SSg('CheckDupes.Memorize', 'uue.put.checkdupes.memorize');
  __SSg('83', 'uue.put.83');

  Ok:=__CopyFile(uueTempFileName, uueTempFileNameBackup);

  if Ok then
   begin
    K:=srvExecute('FILESBBS', snfPutFile, nil);

    Ok:=K = srfOk;

    if Ok then
     begin
      Ok:=__CopyFile(uueTempFileNameBackup, uueTempFileName);

      if Ok then
       Original.FilesBBS:=sGetSemaphore('FilesBBS.Feedback.FileName');
     end
    else
     begin
      lngBegin;
       lngPush('FILESBBS');
       lngPush(HexL(K));

       lngPrint('Main', 'uue.some.error');
      lngEnd;
     end;
   end;
 end;

procedure ___Hatcher(const F: PFile; const Section: PSection);
 procedure __SS(const Key, Value: String);
  begin
   sSetSemaphore('Hatcher.FileInfo.' + Key, Value);
  end;
 procedure __SSg(const Key, Source: String);
  begin
   sSetSemaphore('Hatcher.FileInfo.' + Key, gGetParam(Group, Source));
  end;
 var
  K: Longint;
 begin
  __LocalStringsToGlobalStrings(Section^.Inf, diCreateList(D, 'uue\decoder\hatch\inf'));

  __SS('Area', Section^.iArea);
  __SS('Sender.Name', Section^.iFrom);
  __SS('Sender.Address', Section^.iFromAddress);
  __SS('Receiver.Name', Section^.iTo);
  __SS('Receiver.Address', Section^.iToAddress);
  __SS('Subject', Section^.iSubj);
  __SS('TempFilename', uueTempFilename);
  __SS('Filename', F^.Filename);

  __SSg('Packer', 'uue.hatch.packer');

  if gGetParam(Group, 'uue.hatch.repacker') = '' then
   begin
    __SS('Repacker', '');
    __SS('Convert', '');
   end
  else
   begin
    __SSg('Repacker', 'uue.hatch.repacker');
    __SS('Convert', 'Yes');
   end;

  if gGetBoolParam(Group, 'uue.hatch.inf') then
   begin
    __SS('Inf', 'Yes');
    __SS('Inf.Lines', HexPtr(diCreateList(D, 'uue\decoder\hatch\inf')));
    __SSg('Inf.Name', 'uue.hatch.inf.name');
   end
  else
   __SS('Inf', 'No');

  if gGetBoolParam(Group, 'uue.hatch.fileiddiz') then
   begin
    __SS('File_Id.Diz', 'Yes');
    __SS('File_Id.Diz.Lines', HexPtr(diCreateList(D, 'uue\decoder\hatch\diz')));
    __SSg('File_Id.Diz.Name', 'uue.hatch.fileiddiz.name');
   end
  else
   __SS('File_Id.Diz', 'No');

  sSetSemaphore('Hatcher.FileEcho', gGetParam(Group, 'uue.hatch.fileecho'));
  sSetSemaphore('Hatcher.FileEcho.Tic.Name', gGetParam(Group, 'uue.hatch.tic.name'));

  if gGetParam(Group, 'uue.hatch.tic.directory') <> '' then
   sSetSemaphore('Hatcher.FileEcho.Tic.Dir', gGetParam(Group, 'uue.hatch.tic.directory'))
  else
   sSetSemaphore('Hatcher.FileEcho.Tic.Dir', gGetParam(Group, 'uue.hatch.inbound'));

  sSetSemaphore('Hatcher.FileEcho.Inbound', gGetParam(Group, 'uue.hatch.inbound'));
  sSetSemaphore('Hatcher.FileEcho.Tic.Name', gGetParam(Group, 'uue.hatch.tic.name'));
  sSetSemaphore('Hatcher.FileEcho.Tic.Lines', HexPtr(diCreateList(D, 'uue\decoder\hatch\tic')));

  if gGetBoolParam(Group, 'uue.hatch.List') then
   begin
    __SS('List', 'Yes');
    __SSg('List.FileName', 'uue.Hatch.List.FileName');
   end
  else
   __SS('List', 'No');

  __SSg('CheckDupes', 'uue.hatch.checkdupes');
  __SSg('CheckDupes.Memorize', 'uue.hatch.checkdupes.memorize');
  __SSg('83', 'uue.hatch.83');

  K:=srvExecute('HATCHER', snhHatchFile, Nil);

  Ok:=K = srfOk;

  if not Ok then
   begin
    lngBegin;
     lngPush('HATCHER');
     lngPush(HexL(K));
     lngPrint('Main', 'uue.some.error');
    lngEnd;
   end
  else
   Original.Hatcher:=sGetSemaphore('Hatcher.Feedback.Filename');
 end;

procedure ___Announce(const F: PFile; const Section: PSection);
 var
  K: Longint;
 begin
  __LocalStringsToGlobalStrings(Section^.Inf, diCreateList(D, 'uue\decoder\announce\inf'));

  sSetSemaphore('Announcer.Mode', '1');
  sSetSemaphore('Announcer.Lines', HexPtr(diCreateList(D, 'uue\decoder\announce\inf')));
  sSetSemaphore('Announcer.Area', Section^.iArea);
  sSetSemaphore('Announcer.Prefix', 'uue.');
  sSetSemaphore('Announcer.Sender.Name', Section^.iFrom);
  sSetSemaphore('Announcer.Sender.Address', Section^.iFromAddress);
  sSetSemaphore('Announcer.Receiver.Name', Section^.iTo);
  sSetSemaphore('Announcer.Receiver.Address', Section^.iToAddress);
  sSetSemaphore('Announcer.Subject', Section^.iSubj);
  sSetSemaphore('Announcer.FileName', F^.Filename);
  sSetSemaphore('Announcer.FileSize', Long2Str(GetFileSize(uueTempFilename)));
  sSetSemaphore('Announcer.FileEcho', gGetParam(Group, 'uue.hatch.fileecho'));
  sSetSemaphore('Announcer.FileDirectory', gGetParam(Group, 'uue.put.directory'));
  sSetSemaphore('Announcer.FileName.FilesBBS', Original.FilesBBS);
  sSetSemaphore('Announcer.FileName.Hatcher', Original.Hatcher);

  K:=annProcessAnnounce;

  if K <> srYes then
   begin
    lngBegin;
     lngPush(HexL(K));
     lngPrint('Main', 'uue.error.announcing');
    lngEnd;
   end;
 end;

procedure ___ListAnnounce(const F: PFile; const Section: PSection);
 var
  Macros: Pointer;
  Temp, Target: PStrings;
  S: String;
  K: Longint;
 begin
  diSetBool(D, 'uue\decoder\list\announce\filled', True);
  diSetBool(D, 'uue\decoder\list\announce\post', True);

  Target:=diCreateList(D, 'uue\decoder\list\announce\data');

  cmCreateStrings(Temp);

  gProcessList(Group, 'uue.List.Announcer.Center', Temp);

  Macros:=umCreateMacros;

  umAddMacro(Macros, '@echo', F^.Area);
  umAddMacro(Macros, '@filename', Original.Filename);
  umAddMacro(Macros, '@ffilename', Original.FilesBBS);
  umAddMacro(Macros, '@hfilename', Original.Hatcher);
  umAddMacro(Macros, '@size', Long2Str(Original.Size));
  umAddMacro(Macros, '@subject', Section^.iSubj);
  umAddMacro(Macros, '@sender.name', Section^.iFrom);
  umAddMacro(Macros, '@receiver.name', Section^.iTo);
  umAddMacro(Macros, '@sender.address', Section^.iFromAddress);
  umAddMacro(Macros, '@receiver.address', Section^.iToAddress);

  if F^.Total = 0 then
   umAddMacro(Macros, '@sections', CheckForZero(F^.Count))
  else
   umAddMacro(Macros, '@sections', CheckForZero(F^.Total));

  for K:=1 to cmCount(Temp) do
   begin
    GetPStringEx(cmAt(Temp, K), S);

    S:=umProcessMacro(Macros, S);

    if not umEmptyLine(Macros) then
     cmInsert(Target, cmNewStr(S));
   end;

  umDestroyMacros(Macros);

  cmDisposeObject(Temp);

  diSetNum(D, 'uue\decoder\list\announce\count', diGetNum(D, 'uue\decoder\list\announce\count') + 1);
  diSetNum(D, 'uue\decoder\list\announce\size', diGetNum(D, 'uue\decoder\list\announce\size') + Original.Size);

  diSetString(D, 'uue\decoder\list\announce\area', Section^.iArea);
 end;

procedure __ProcessFile(const F: PFile);
 var
  Section: PSection;
  Counter: Longint;
 begin
  Section:=New(PSection, Init);

  Section^.Load(QueryName(1, F^.Total, F^.Filename, F^.Area));

  D:=diCreate(Longint(Group));

  if not diGetBool(D, 'uue\decoder\Parsed') then
   ___Parse(D);

  Original.FileName:=F^.Filename;
  Original.CRC:=uGetCRC(uueTempFilename);
  Original.Size:=GetFileSize(uueTempFilename);

  F^.Filename:=uCheckBadFName(F^.Filename);

  if diGetBool(D, 'uue\decoder\83') then
   F^.Filename:=uLFNto83(F^.Filename);

  Counter:=0;

  if diGetBool(D, 'uue\decoder\CheckDupes') then
   ComprehensiveDupeChecking(F^.Filename,
    Original.Size, Original.CRC, fsgName or fsgSize or fsgCRC, _83 or diGetBool(D, 'uue\decoder\83'), F^.Filename,
    OrderedToDestroy, True);

  if Original.Filename <> F^.Filename then
   begin
    lngBegin;
     lngPush(Original.Filename);
     lngPush(F^.Filename);
     lngPrint('Main', 'uue.trying.dupe');
    lngEnd;
   end;

  Ok:=True;

  repeat
   if OrderedToDestroy then
    begin
     lngPrint('Main', 'uue.we.must.kill.this');
     Break;
    end;

   Original.FilesBBS:='n/a';
   Original.Hatcher:='n/a';

   if (pSearch('FILESBBS') <> Nil) and gGetBoolParam(Group, 'uue.put') and (Ok) then
    ___FilesBBS(F, Section);

   if (pSearch('HATCHER') <> Nil) and gGetBoolParam(Group, 'uue.hatch') and (Ok) then
    ___Hatcher(F, Section);

   if (annCheck) and gGetBoolParam(Group, 'uue.announce') and (Ok) then
    ___Announce(F, Section);

   if (annCheck) and gGetBoolParam(Group, 'uue.list.announce') and (Ok) then
    ___ListAnnounce(F, Section);

   if Ok then
    begin
     if diGetBool(D, 'uue\decoder\CheckDupes\Memorize') then
      filesAddSpool(F^.Filename, Original.Size, Original.CRC);
    end;
   filesFlushSpool;
  until True;

  Dispose(Section, Done);
 end;

{ __DoTheBlues }

procedure __DoTheBlues; { (c) DJ Hooker }
 var
  K: Longint;
  F: PFile;
 begin
  K:=0;
  repeat
   mCheckBreak;
   if sExitNow then Break;

   if K < 0 then K:=0;
   Inc(K);
   if K > Files^.Count then Break;

   F:=Files^.At(K);

   Group:=gSearchByArea(F^.Area);
   if Group = Nil then
    begin
     lngBegin;
      lngPush(F^.Area);
      lngPrint('Main', 'uue.trying.group');
     lngEnd;
     Continue;
    end;

   KeepDays:=gGetDoubleNumParam(Group, 'uue.KeepDays');
   if KeepDays = 0 then
    KeepDays:=-1;

   if F^.Bad then
    begin
     if QueryTimeDifference(F) > KeepDays then
      begin
       lngBegin;
        lngPush(F^.Filename);
        lngPush(Long2Str(QueryTimeDifference(F)));
        lngPush(Long2Str(KeepDays));
        lngPrint('Main', 'uue.killed.because.bad');
       lngEnd;
       __Dump(F, dfExpired);
       __KillInResource(F);
      end;
     Continue;
    end;

   if __DecodeFile(F) then
    begin
     __ProcessFile(F);
     __KillInResource(F);
    end
   else
    if gGetDoubleBoolParam(Group, 'uue.Kill.Bad') then
     begin
      __Dump(F, dfBad);
      __KillInResource(F);
     end
    else
     if QueryTimeDifference(F) > KeepDays then
      __KillInResource(F);
  until False;
 end;

{ __PostListedAnnounces }

procedure ___PreProcessListedAnnounces(const Group: PStrings);
 var
  G, Merge: PStrings;
  D2: Pointer;
  S: String;
  K: Longint;
 begin
  D:=diCreate(Longint(Group));

  if not diGetBool(D, 'uue\decoder\list\announce\filled') then
   Exit;

  Merge:=diCreateList(D, 'uue\decoder\list\announce\merge');

  for K:=1 to cmCount(Merge) do
   begin
    GetPStringEx(cmAt(Merge, K), S);

    G:=gSearch(S);

    if G = Nil then
     begin
      lngBegin;
       lngPush(S);
       lngPrint('Main', 'uue.unknown.group');
      lngEnd;
     end
    else
     begin
      D2:=diCreate(Longint(G));

      if diGetBool(D2, 'uue\decoder\list\announce\filled') then
       begin
        diSetBool(D2, 'uue\decoder\list\announce\post', False);

        diSetNum(D, 'uue\decoder\list\announce\count',
         diGetNum(D, 'uue\decoder\list\announce\count') +
         diGetNum(D2, 'uue\decoder\list\announce\count'));

        diSetNum(D, 'uue\decoder\list\announce\size',
         diGetNum(D, 'uue\decoder\list\announce\size') +
         diGetNum(D2, 'uue\decoder\list\announce\size'));
       end;
     end;
   end;
 end;

procedure ___PostListedAnnounces(const Group: PStrings);
 var
  Temp, List, Merge, G: PStrings;
  D2: Pointer;
  S: String;
 procedure Prepare(const Key: String);
  var
   Macros: Pointer;
   K: Longint;
   S: String;
  begin
   Macros:=umCreateMacros;

   cmCreateStrings(List);

   gProcessList(Group, Key, List);

   umAddMacro(Macros, '@totalfiles', Long2Str(diGetNum(D, 'uue\decoder\list\announce\count')));
   umAddMacro(Macros, '@totalsize', Long2Str(diGetNum(D, 'uue\decoder\list\announce\size')));

   for K:=1 to cmCount(List) do
    begin
     GetPStringEx(cmAt(List, K), S);

     S:=umProcessMacro(Macros, S);

     if not umEmptyLine(Macros) then
      cmInsert(Temp, cmNewStr(S));
    end;

   cmDisposeObject(List);

   umDestroyMacros(Macros);
  end;
 var
  K, L: Longint;
 begin
  D:=diCreate(Longint(Group));

  if not diGetBool(D, 'uue\decoder\list\announce\filled') then
   Exit;

  if not diGetBool(D, 'uue\decoder\list\announce\post') then
   Exit;

  cmCreateStrings(Temp);

  Prepare('uue.list.announcer.header');

  List:=diCreateList(D, 'uue\decoder\list\announce\data');

  { add our own files }

  for K:=1 to cmCount(List) do
   cmInsert(Temp, cmNewStr(GetPString(cmAt(List, K))));

  { add merged files }

  Merge:=diCreateList(D, 'uue\decoder\list\announce\merge');

  for K:=1 to cmCount(Merge) do
   begin
    GetPStringEx(cmAt(Merge, K), S);

    G:=gSearch(S);

    if G = Nil then
     begin
      lngBegin;
       lngPush(S);
       lngPrint('Main', 'uue.unknown.group');
      lngEnd;
     end
    else
     begin
      D2:=diCreate(Longint(G));

      if diGetBool(D2, 'uue\decoder\list\announce\filled') then
       begin
        List:=diCreateList(D2, 'uue\decoder\list\announce\data');

        for L:=1 to cmCount(List) do
         begin
          GetPStringEx(cmAt(List, L), S);

          cmInsert(Temp, cmNewStr(S));
         end;
       end;
     end;
   end;

  Prepare('uue.list.announcer.footer');

  sSetSemaphore('Announcer.Mode', '2');
  sSetSemaphore('Announcer.Lines', HexPtr(Temp));
  sSetSemaphore('Announcer.Prefix', 'uue.List.');
  sSetSemaphore('Announcer.Area', diGetString(D, 'uue\decoder\list\announce\area'));

  K:=annProcessAnnounce;
  if K <> srYes then
   begin
    lngBegin;
    lngPush(HexL(K));
    lngPrint('Main', 'uue.error.announcing');
    lngEnd;
   end
  else
   lngPrint('Main', 'uue.list.announced');

  cmDisposeObject(Temp);
 end;

procedure __PostAnnounces;
 var
  K: Longint;
  Groups: Pointer;
 begin
  Groups:=gGroups;

  for K:=1 to cmCount(Groups) do
   ___PreProcessListedAnnounces(cmAt(Groups, K));

  for K:=1 to cmCount(Groups) do
   ___PostListedAnnounces(cmAt(Groups, K));
 end;

{ __Decode }

procedure __Decode;
 begin
  if (not uueDecoding) or sExitNow then Exit;

  Files:=New(PCollection, Init);

  lngPrint('Main', 'uue.decoding.started');

  __Analyze;

  if not sExitNow then
   __DoTheBlues;

  __PostAnnounces;

  Dispose(Files, Done);
 end;

end.
