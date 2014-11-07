unit uueScan;

{$IFDEF VIRTUALPASCAL}
 {$DEFINE USEUNITS}
{$ENDIF}
{$IFDEF SOLID}
 {$DEFINE USEUNITS}
{$ENDIF}

interface

uses
{$IFDEF USEUNITS}
     Misc, Language, Semaphor, Plugins, Config, Video, Division,
{$ELSE}
     Decl,
{$ENDIF}
     Consts_,
     Dos, Wizard, Types,
     uueOver,
     Core;

{$DEFINE SCAN_DECL}
{$I SCAN.INC}

var
 Message: PMessage;

procedure __ProcessMessage;

implementation

{$DEFINE SCAN_CODE}
{$I SCAN.INC}
{$I COMMON.INC}

{ __Process }

var
 __StartLine, __TargetLine, __Current, __Total: Longint;
 __Filename: String;

 D, GD: Pointer;
 Group, Exclude, Remain: PStrings;
 Section: PSection;
 Cut: Boolean;
 KillMode: (kmAll, kmKeepFirst, kmNope);
 DataCount: Longint;

procedure __SearchBounds;
 var
  S: String;
  K, L: Longint;
 begin
  __TargetLine:=cmCount(Message^.Data);
  K:=__StartLine - 1;
  repeat
   Inc(K);
   if K > cmCount(Message^.Data) then Break;

   GetPStringEx(cmAt(Message^.Data, K), S);

   if Copy(S, 1, 3) = 'end' then
    begin
     __TargetLine:=K;
     L:=0;

     for K:=__TargetLine to __TargetLine + 10 do
      begin
       GetPStringEx(cmAt(Message^.Data, K), S);

       if Copy(S, 1, 4) = 'sum ' then
        begin
         Inc(L);

         __TargetLine:=K;

         if L = 2 then Break;
        end;
      end;
     Break;
    end;

   if Copy(S, 1, 4) = 'sum ' then
    begin
     __TargetLine:=K;
     L:=0;

     for K:=__TargetLine to __TargetLine + 10 do
      begin
       GetPStringEx(cmAt(Message^.Data, K), S);

       if Copy(S, 1, 4) = 'sum ' then
        begin
         Inc(L);

         __TargetLine:=K;

         if L = 2 then Break;
        end;
      end;
     Break;
    end;

   if (S <> '') and (not IsUUE(S)) and (K > __StartLine + 7) then
    begin
     __TargetLine:=K - 1;
     Break;
    end;
  until False;
 end;

procedure __SaveSection;
 var
  K: Longint;
  S: String;
 begin
  Section^.Current:=__Current;
  Section^.Total:=__Total;
  Section^.Filename:=__Filename;
  Section^.iFrom:=Message^.iFrom;
  Section^.iTo:=Message^.iTo;
  Section^.iFromAddress:=Address2Str(Message^.iFromAddress);
  Section^.iToAddress:=Address2Str(Message^.iToAddress);
  Section^.iSubj:=Message^.iSubj;
  Section^.iArea:=Message^.iArea;
  Section^.iDate:=TimeFix;
  Section^.Version:=uueResourceVersion;

  for K:=__StartLine to __TargetLine do
   begin
    GetPStringEx(cmAt(Message^.Data, K), S);
    Section^.Data^.Insert(NewStr(S));
   end;
 end;

procedure __InsertInf(const Key: String);
 var
  S: String;
  M: Pointer;
  I: PStrings;
  K: Longint;
 begin
  M:=umCreateMacros;

  umAddMacro(M, '@echo', Message^.iArea);
  umAddMacro(M, '@filename', __Filename);
  umAddMacro(M, '@subject', Message^.iSubj);
  umAddMacro(M, '@sender.name', Message^.iFrom);
  umAddMacro(M, '@receiver.name', Message^.iTo);
  umAddMacro(M, '@sender.address', Address2Str(Message^.iFromAddress));
  umAddMacro(M, '@receiver.address', Address2Str(Message^.iToAddress));
  umAddMacro(M, '@sections', CheckForZero(__Total));
  umAddMacro(M, '@startline', GetPString(cmAt(Message^.Data, __StartLine)));

  I:=diCreateList(D, Key);

  for K:=1 to cmCount(I) do
   begin
    GetPStringEx(cmAt(I, K), S);
    S:=umProcessMacro(M, S);

    if not umEmptyLine(M) then
     Section^.Inf^.Insert(NewStr(S));
   end;

  umDestroyMacros(M);
 end;

procedure __InsertPart(const LowBound, HighBound: Longint);
 var
  S: String;
  K: Longint;
  B: Boolean;
 begin
  for K:=LowBound to HighBound do
   begin
    GetPStringEx(cmAt(Message^.Data, K), S);
    B:=not CheckForMask(S, Exclude);
    if not B then
     B:=CheckForMask(S, Remain);

    if B then
     Section^.Inf^.Insert(NewStr(S));
   end;
 end;

procedure __SaveInf;
 begin
  Exclude:=diCreateList(D, 'uue\inf\exclude\lines');
  Remain:=diCreateList(D, 'uue\inf\remain\lines');

  __InsertInf('uue\inf\header');

  __InsertPart(1, __StartLine - 1);

  __InsertInf('uue\inf\center');

  __InsertPart(__TargetLine + 1, cmCount(Message^.Data));

  __InsertInf('uue\inf\footer');
 end;

procedure __ShowInfo;
 begin
  lngBegin;
   lngPush(__FileName);
   lngPush(Long2Str(__Current));
   lngPush(Long2Str(__Total));
   lngPush(Message^.iArea);
   lngPush(gGetParam(Group, 'Name'));
   lngPush(gGetParam(Group, 'Desc'));
   lngPrint('Main','uue.Found.1');
   lngPrint('Main','uue.Found.2');
   lngPrint('Main','uue.Found.3');
  lngEnd;
 end;

procedure __CheckCut;
 begin
  Exclude:=diCreateList(D, 'uue\skip\cut\areas');
  Remain:=diCreateList(D, 'uue\remain\cut\areas');

  Cut:=Check2Masks(Message^.iArea, Exclude, Remain);

  Exclude:=diCreateList(D, 'uue\skip\cut\address');
  Remain:=diCreateList(D, 'uue\remain\cut\address');

  if Cut then
   Cut:=Check2Masks(Address2Str(Message^.iFromAddress), Exclude, Remain);

  if Cut then
   Cut:=gGetDoubleBoolParam(Group, 'uue.cut');
 end;

procedure __Cut;
 var
  M: Pointer;
  I: PStrings;
  S: String;
  K: Longint;
  L: Longint;
 begin
  M:=umCreateMacros;

  umAddMacro(M, '@echo', Message^.iArea);
  umAddMacro(M, '@filename', __Filename);
  umAddMacro(M, '@subject', Message^.iSubj);
  umAddMacro(M, '@sender.name', Message^.iFrom);
  umAddMacro(M, '@receiver.name', Message^.iTo);
  umAddMacro(M, '@sender.address', Address2Str(Message^.iFromAddress));
  umAddMacro(M, '@receiver.address', Address2Str(Message^.iToAddress));
  umAddMacro(M, '@sections', CheckForZero(__Total));
  umAddMacro(M, '@section', Long2Str(__Current));
  umAddMacro(M, '@startline', GetPString(cmAt(Message^.Data, __StartLine)));

  I:=diCreateList(D, 'uue\Inf');

  for K:=1 to __TargetLine - __StartLine + 1 do
   cmAtFree(Message^.Data, __StartLine);

  L:=__StartLine;

  for K:=1 to cmCount(I) do
   begin
    GetPStringEx(cmAt(I, K), S);
    S:=umProcessMacro(M, S);

    if not umEmptyLine(M) then
     begin
      cmAtInsert(Message^.Data, cmNewStr(S), L);
      Inc(L);
     end;
   end;

  umDestroyMacros(M);

  __TargetLine:=__StartLine + cmCount(I);
 end;

procedure __CheckKill;
 var
  S: String;
 begin
  S:=gGetDoubleParam(Group, 'uue.kill');

  TrimEx(S);
  StUpcaseEx(S);

  if (S[0] <> #0) then
   case S[1] of
    'A': KillMode:=kmAll;
    'K': KillMode:=kmKeepFirst;
   else
    KillMode:=kmNope;
   end
  else
   KillMode:=kmNope;
 end;

procedure __Process;
 var KillThisMessage:boolean;
 begin
  Group:=Message^.Group;

  if Group = Nil then
   begin
    lngBegin;
     lngPush(Message^.iArea);
     lngPrint('Main', 'uue.unknown.group');
    lngEnd;

    Exit;
   end;

  D:=diCreate(Longint(Group));
  GD:=diCreate(0);

  if not diGetBool(D, 'uue\Parsed') then
   begin
    (* let's parse it! *)

    diSetBool(D, 'uue\Scan.Disabled', gGetDoubleBoolParam(Group, 'uue.Scan.Disabled'));
    diSetBool(D, 'uue\Decode.Disabled', gGetDoubleBoolParam(Group, 'uue.Decode.Disabled'));

    gProcessList(Group, 'uue.Inf', diCreateList(D, 'uue\Inf'));

    gProcessList(Group, 'uue.skip.cut.areas', diCreateList(D, 'uue\skip\cut\areas'));
    gProcessList(Group, 'uue.remain.cut.areas', diCreateList(D, 'uue\remain\cut\areas'));

    gProcessList(Group, 'uue.skip.cut.address', diCreateList(D, 'uue\skip\cut\address'));
    gProcessList(Group, 'uue.remain.cut.address', diCreateList(D, 'uue\remain\cut\address'));

    gProcessList(Group, 'uue.inf.exclude.lines', diCreateList(D, 'uue\inf\exclude\lines'));
    gProcessList(Group, 'uue.inf.remain.lines', diCreateList(D, 'uue\inf\remain\lines'));

    gProcessList(Group, 'uue.inf.header', diCreateList(D, 'uue\inf\header'));
    gProcessList(Group, 'uue.inf.center', diCreateList(D, 'uue\inf\center'));
    gProcessList(Group, 'uue.inf.footer', diCreateList(D, 'uue\inf\footer'));

    (* hmm... we parsed it! *)

    diSetBool(D, 'uue\Parsed', True);
   end;

  if diGetBool(D, 'uue\Scan.Disabled') then Exit;

  __SearchBounds;

  { Do Section }

  Section:=New(PSection, Init);

  __SaveSection;

  if __Current = 1 then
   __SaveInf
  else
   Section^.Inf^.FreeAll;

  __ShowInfo;

  Section^.Store(QueryName(__Current, __Total, __Filename, Message^.iArea));

  Dispose(Section, Done);

  { Cut }

  __CheckCut;

  if Cut then
  begin
   __CheckKill;
   KillThisMessage:=false;
   case KillMode of
    kmAll: KillThisMessage:=true; 
    kmKeepFirst: if __Current <> 1 then KillThisMessage:=true;
   end;

   if KillThisMessage then sSetSemaphore('Scanner.Message.Kill', 'Yes')
   else __Cut;
  end;

 end;

{ __ProcessHeader }

var
 __LineHash, __HeaderHash: Longint;
 __Line, __Header, __LineWord, __HeaderWord: String;

function __Hash(var S: String): Longint;
 var
  Count, K: Longint;
 begin
  Count:=1;
  for K:=1 to Length(S) do
   if (S[K] = ' ') and (S[K - 1] <>  ' ') then
    Inc(Count);
  __Hash:=Count;
 end;

function __Word(N: Byte; var S: String): String;
 var
  I: Word;
  Count, Len : Byte;
  SLen: Byte absolute S;
 begin
  Count:=0;
  I:=1;
  Len:=0;
  __Word[0]:=#0;

  while (I <= SLen) and (Count <> N) do
   begin
    while (I <= SLen) and (S[I] = ' ') do Inc(I);
    if I <= SLen then Inc(Count);
    while (I <= SLen) and not(S[I] = ' ') do
     begin
      if Count = N then
       begin
        Inc(Len);
        __Word[0]:=Char(Len);
        __Word[Len]:=S[I];
       end;
      Inc(I);
     end;
   end;
 end;

function __ProcessHeader: Boolean;
 var
  K, L: Longint;
 begin
  __LineHash:=__Hash(__Line);
  __HeaderHash:=__Hash(__Header);

  __Current:=1;
  __Total:=0;
  __Filename:='';

  K:=0;
  repeat
   Inc(K);
   if K > __HeaderHash then Break;

   __HeaderWord:=__Word(K, __Header);
   __LineWord:=__Word(K, __Line);

   if __HeaderWord[1] = '%' then
    case __HeaderWord[2] of
     'c': Str2Longint(__LineWord, __Current);
     't': Str2Longint(__LineWord, __Total);
     '?':;
     'n': if not Str2Number(__LineWord) then Break;
     '%': if __LineWord <> '%' then Break;
     'f':
      begin
       __FileName:=JustFileName(__LineWord);

       TrimEx(__FileName);

       for L:=1 to Length(__FileName) do
        if __FileName[L] = #255 then
         __FileName[L]:='_';
      end;
    end
   else
    if StLoCase(__LineWord) <> __HeaderWord then Break;
  until False;

  if __Filename <> '' then
   begin
    __Process;
    DataCount:=cmCount(Message^.Data);
    __ProcessHeader:=True;
   end
  else
   __ProcessHeader:=False;
 end;

{ __ProcessLine }

procedure __ProcessLine;
 var
  K: Longint;
 begin
 
  if (__Line = '') or (not uueTable[LoCase(__Line[1])]) then Exit;

  for K:=1 to uueHeadersCount do
   begin
    GetPStringEx(cmAt(uueHeaders, K), __Header);
    if __ProcessHeader then Break;
   end;
 end;

{ __ProcessMessage }

procedure __ProcessMessage;
 begin
  __TargetLine:=0;
  DataCount:=cmCount(Message^.Data);
  repeat
   Inc(__TargetLine);
   if __TargetLine > DataCount then Break;

   GetPStringEx(cmAt(Message^.Data, __TargetLine), __Line);

   __StartLine:=__TargetLine;

   __ProcessLine;
  until False;
 end;

end.