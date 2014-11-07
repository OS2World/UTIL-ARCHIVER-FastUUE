{$IFDEF SOLID}
unit CRAx;

interface

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint;

implementation
{$ELSE}
library CRAx;
{$ENDIF}

{$IfDef VIRTUALPASCAL}
uses Types, Consts_, Log, Video, Misc, Language, Config, Resource,
     Division,
     Plugins, Semaphor, Wizard, Core;
{$IFNDEF SOLID}
{$Dynamic MAIN.LIB}
{$ENDIF}
{$EndIF}
{$IFDEF DPMI}
uses
{$IFDEF SOLID}
     Plugins, Semaphor, Language, Misc, Config, Video, Division,
{$ELSE}
     Decl,
{$ENDIF}
     Wizard, Consts_, Dos, Macroz, Types, Core;
{$ENDIF}

{$i scan.inc}
{$i files.inc}
{$i common.inc}
{$i filesbbs.inc}
{$i announce.inc}
{$i hatcher.inc}

var
 crax_StartLine                 : Longint;
 crax_TargetLine                : Longint;
 crax_Count                     : Longint;

 crax_CRC                       : Longint;
 crax_Size                      : Longint;
 crax_Dupe                      : Boolean;
 crax_Counter                   : Longint;

 crax_S                         : String;
 crax_Su                        : String;
 crax_Title                     : String;
 crax_Mask                      : String;
 crax_TempFilename              : String;
 crax_Image                     : PStrings;
 crax_Inf                       : PStrings;
 crax_TempLink                  : Text;

const
 crax_Wadda                     = $01;
 crax_XCK                       = $02;
 crax_CRK                       = $03;

 crax_XCK_CRK                   = $80;
 crax_XCK_CRX                   = $81;

 crax_Wadda_BadCount            = $14;

 HexChars                       : Set Of Char = ['0'..'9', 'A'..'F', 'a'..'f'];
 BadSymbols                     : Set Of Char = [#0..#39, #42..#47, #58..#64, #92, #94..#96, #123..#127, #176..#223,
                                                 #242..#255];
 BadSymbolsEx                   : Set Of Char = [#0..#39, #42..#47, #58..#64, #92, #94..#96, #123..#127, #176..#223,
                                                 #242..#255, ']'];
 ValidNameChars_                : Set Of Char = ['0'..'9', 'A'..'Z', 'a'..'z', '~', ' ', '€'..'¯', 'à'..'ñ', '(', ')'];
 ValidNameChars                 : Set Of Char = ['0'..'9', 'A'..'Z', 'a'..'z', '~'];

 crax_XCK_Masks                 : PStrings = Nil;

 craxVersion                    = $00010000;
 craxCollect                    : Boolean  = True;
 msg                            : PMessage = Nil;

function craxStartup: Longint;
 var
  K: Longint;
  S: PString;
 begin
  craxStartup:=srYes;
  cmCreateStrings(crax_XCK_Masks);
  cProcessList('crax.xck.id', crax_XCK_Masks);
  for K:=1 to cmCount(crax_XCK_Masks) do
   begin
    S:=cmAt(crax_XCK_Masks, K);
    if S <> Nil then
     StUpCaseEx(S^);
   end;

  cmCreateStrings(crax_Image);
  cmCreateStrings(crax_Inf);

  if cGetParam('crax.Temp') = '' then
   begin
    lngBegin;
     lngPush('crax.Temp');
     lngPrint('Main', 'crax.unable.to.start');
    lngEnd;

    sSetExitNow;

    Exit;
   end;

  crax_TempFileName:=cGetParam('crax.Temp');

  mCreate(JustPathName(crax_TempFileName));
 end;

procedure craxShutdown;
 begin
  cmDisposeObject(crax_Image);
  cmDisposeObject(crax_Inf);
  cmDisposeObject(crax_XCK_Masks);

  EraseFile(crax_TempFileName);
 end;

function IsHex(var S: String; B, E: Byte): Boolean;
 var
  K: Byte;
 begin
  for K:=B to E do
   if not (S[K] in HexChars) then
    begin
     IsHex:=False;
     Exit;
    end;
  IsHex:=True;
 end;

function IsHexLine(var S: String): Boolean;
 var
  A: Boolean;
 begin
  A:=(S[0] > #14) and (S[9] = ':');
  if A then
   A:=IsHex(S, 1, 8);
  IsHexLine:=A;
 end;

function IsWaddaLine(var S: String): Boolean;
 begin
  IsWaddaLine:=(S[0] <> #0) and (S[1] = '|');
 end;

function IsMask(var S, UsedMask: String; Mask: PStrings): Boolean;
 var
  K: Longint;
 begin
  for K:=1 to cmCount(Mask) do
   begin
    GetPStringEx(cmAt(Mask, K), UsedMask);
    if mCheckWildcard(S, Concat(UsedMask, '*')) then
     begin
      IsMask:=True;
      Exit;
     end;
   end;
  IsMask:=False;
 end;

function GetLine(const N: Longint): String;
 begin
  GetLine:=GetPString(cmAt(Msg^.Data, N));
 end;

{*** seeking routines ***}
function SeekLastHex(var Line: Longint): Boolean;
 var
  K: Longint;
  S: String;
 begin
  for K:=cmCount(Msg^.Data) downto 1 do
   begin
    GetPStringEx(cmAt(Msg^.Data, K), S);
    if IsHexLine(S) then
     begin
      SeekLastHex:=True;
      Line:=K;
      Exit;
     end;
   end;
  SeekLastHex:=False;
 end;

{*** error dumping ***}
procedure crax_Error;
 begin
 end;

{*** part of crxproc ***}

const
 Group: PStrings = Nil;
 D: Pointer = Nil;
 AnotherD: Pointer = Nil;

{*** dump when any errors occured ***}
procedure crax_Dump(Target: Longint; const Reason: String);
 var
  F: Text;
  K, DumpCount: Longint;
  dmp83:Boolean;
  Day, Month, Year: Word;
  S, SOld:String;
 begin
  if not cGetBoolParam('crax.BadFiles') then Exit;
  iWannaDate (Day, Month, Year);

  dmp83:=_83 or cGetBoolParam('crax.BadFiles.83');

  S:=LeftPadCh(Long2Str(Day), '0', 2)+LeftPadCh(Long2Str(Month), '0', 2);
  if dmp83 then
   S:=S+'c.dmp'
  else
   S:=S+LeftPadCh(Long2Str(Year), '0', 4)+'crax.dmp';

  S:=AddBackSlash(Trim(cGetParam('crax.BadFiles.Dir')))+S;

  if cGetBoolParam('crax.BadFiles.Serial') then 
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
  {$I-}
  Assign(F, S);
  Rewrite(F);
  if IOResult <> 0 then Exit;
  WriteLn(F, 'þþþ Plugin version is ', Version2Str(craxVersion));
  WriteLn(F, 'þþþ info þþþ ');
  WriteLn(F, ' reason ..... ', Reason);
  WriteLn(F, ' time ....... ', GetPktDateTime);
  WriteLn(F, ' __sl ....... ', crax_StartLine);
  WriteLn(F, ' __c ........ ', crax_Count);
  WriteLn(F, ' __tl ....... ', crax_TargetLine);
  WriteLn(F, ' title ...... "', crax_Title, '"');
  WriteLn(F, 'þþþþ dump start þþþþ');
  for K:=crax_StartLine to Target do
   WriteLn(F, GetPString(cmAt(msg^.Data, K)));
  WriteLn(F, 'þþþþ dump end þþþþ');
  Close(F);
 end;

{*** Crax Process (Do The Blues!) ***}

procedure crax_Process(const TheStart, TheEnd, TypeOfCrack: Longint);
 var
  OldName, Name: String;
 procedure InsertToInf(const List: PStrings);
  var
   Macros: Pointer;
   K: Longint;
   S: String;
  begin
   Macros:=umCreateMacros;
   umAddMacro(Macros, '@echo', msg^.iArea);
   umAddMacro(Macros, '@filename', Name);
   umAddMacro(Macros, '@subject', msg^.iSubj);
   umAddMacro(Macros, '@sender.name', msg^.iFrom);
   umAddMacro(Macros, '@receiver.name', msg^.iTo);
   umAddMacro(Macros, '@sender.address', Address2Str(msg^.iFromAddress));
   umAddMacro(Macros, '@receiver.address', Address2Str(msg^.iToAddress));
   umAddMacro(Macros, '@title', crax_Title);
   for K:=1 to cmCount(List) do
    begin
     GetPStringEx(cmAt(List, K), S);
     S:=umProcessMacro(Macros, S);
     if not umEmptyLine(Macros) then
      cmInsert(crax_Inf, cmNewStr(S));
    end;
   umDestroyMacros(Macros);
  end;
 var
  List, AnotherList, Exclude, Include: PStrings;
  Ok, B, Cut: Boolean;
  K, L: Longint;
  S: String;
  Macros: Pointer;
 begin
  Group:=msg^.Group;
  if Group = Nil then
   begin
    lngBegin;
     lngPush(msg^.iArea);
     lngPrint('Main', 'crax.no.group');
    lngEnd;
    Exit;
   end;

  D:=diCreate(Longint(Group));
  AnotherD:=diCreate(0);

  if not diGetBool(D, 'Crax\Parsed') then { * parse * }
   begin
    diSetBool(D, 'Crax\Disabled', gGetBoolParam(Group, 'crax.Disabled'));
    diSetBool(D, 'Crax\83', gGetBoolParam(Group, 'crax.83'));
    diSetBool(D, 'Crax\CheckDupes', gGetDoubleBoolParam(Group, 'crax.CheckDupes'));
    diSetBool(D, 'Crax\CheckDupes\Memorize', gGetDoubleBoolParam(Group, 'crax.CheckDupes.Memorize'));
    diSetBool(D, 'Crax\Put', gGetBoolParam(Group, 'crax.Put') and (pSearch('FILESBBS') <> Nil));
    diSetBool(D, 'Crax\Hatch', gGetBoolParam(Group, 'crax.Hatch') and (pSearch('HATCHER') <> Nil));
    diSetBool(D, 'Crax\Cut', gGetDoubleBoolParam(Group, 'crax.Cut'));
    diSetBool(D, 'Crax\Announce', gGetBoolParam(Group, 'crax.Announce'));
    diSetBool(D, 'Crax\Announce\List', gGetBoolParam(Group, 'crax.List.Announce'));

    gProcessList(Group, 'crax.inf.exclude.lines', diCreateList(D, 'Crax\Inf\Exclude'));
    gProcessList(Group, 'crax.inf.remain.lines', diCreateList(D, 'Crax\Inf\Include'));
    gProcessList(Group, 'crax.inf.header', diCreateList(D, 'Crax\Inf\Header'));
    gProcessList(Group, 'crax.inf.center', diCreateList(D, 'Crax\Inf\Center'));
    gProcessList(Group, 'crax.inf.footer', diCreateList(D, 'Crax\Inf\Footer'));
    gProcessList(Group, 'crax.inf', diCreateList(D, 'Crax\Inf'));
    gProcessList(Group, 'crax.Skip.Cut.Areas', diCreateList(D, 'Crax\Skip\Cut\Areas'));
    gProcessList(Group, 'crax.Remain.Cut.Areas', diCreateList(D, 'Crax\Remain\Cut\Areas'));
    gProcessList(Group, 'crax.Skip.Cut.Address', diCreateList(D, 'Crax\Skip\Cut\Address'));
    gProcessList(Group, 'crax.Remain.Cut.Address', diCreateList(D, 'Crax\Remain\Cut\Address'));
    gProcessList(Group, 'crax.List.Announcer.Header', diCreateList(D, 'Crax\Announce\List\Header'));
    gProcessList(Group, 'crax.List.Announcer.Center', diCreateList(D, 'Crax\Announce\List\Center'));
    gProcessList(Group, 'crax.List.Announcer.Footer', diCreateList(D, 'Crax\Announce\List\Footer'));
    gProcessList(Group, 'crax.List.Announcer.Merge', diCreateList(D, 'Crax\Announce\List\Merge'));
    gProcessList(Group, 'crax.Put.FilesBBS.Lines', diCreateList(D, 'Crax\Put\FilesBBS'));
    gProcessList(Group, 'crax.Put.DirDesc.Lines', diCreateList(D, 'Crax\Put\DirDesc'));
    gProcessList(Group, 'crax.Hatch.Tic.Lines', diCreateList(D, 'Crax\Hatch\Tic'));

    diSetString(D, 'Crax\GroupName', gGetParam(Group, 'Name'));
    diSetString(D, 'Crax\GroupDesc', gGetParam(Group, 'Desc'));

    (* Make item in the global "ENUM" list *)

    diSetNum(AnotherD, 'Crax\Enum\Size', diGetNum(AnotherD, 'Crax\Enum\Size') + 1);
    diSetNum(AnotherD, 'Crax\Enum\' + Long2Str(diGetNum(AnotherD, 'Crax\Enum\Size')), Longint(D));

    (* The Flag %) *)
    diSetBool(D, 'Crax\Parsed', True);
   end;

  if diGetBool(D, 'Crax\Disabled') then Exit;

  Name:='';

  if diGetBool(D, 'Crax\83') then
   begin
    for K:=1 to Length(crax_Title) do
     if crax_Title[K] in ValidNameChars then
      Name:=Concat(Name, crax_Title[K]);
    Name:=Copy(Name, 1, 8);
    StUpcaseEx(Name);
   end
  else
   for K:=1 to Length(crax_Title) do
    if crax_Title[K] in ValidNameChars_ then
     Name:=Concat(Name, crax_Title[K]);

  cmFreeAll(crax_Image);
  for K:=TheStart to TheEnd do
   cmInsert(crax_Image, cmNewStr(GetPString(cmAt(msg^.Data, K))));

  if IOResult <> 0 then;
  Assign(crax_TempLink, crax_TempFileName);
  Rewrite(crax_TempLink);
  if InOutRes <> 0 then
   begin
    lngBegin;
     lngPush(crax_TempFileName);
     lngPush(HexL(IOResult));
     lngPrint('Main', 'error.cant.create');
    lngEnd;
    Exit;
   end;

  for K:=1 to cmCount(crax_Image) do
   WriteLn(crax_TempLink, GetPString(cmAt(crax_Image, K)));

  Close(crax_TempLink);
  if IOResult <> 0 then;

  case TypeOfCrack of
   crax_Wadda, crax_XCK: Name:=Concat(Name, '.XCK');
   crax_CRK: Name:=Concat(Name, '.CRK');
  else
   Name:=Concat(Name, '.ELK');
  end;

  crax_CRC:=uGetCRC(crax_TempFileName);
  crax_Size:=GetFileSize(crax_TempFileName);

  {$IFDEF DPMI}
   Name:=uLFNto83(Name);
  {$ENDIF}

  Name:=uCheckBadFName(Name);

  crax_Dupe:=False;
  crax_Counter:=0;
  Ok:=True;
  OldName:=Name;

  if diGetBool(D, 'Crax\CheckDupes') then
   repeat
    if not filesCheck(Name, 0, 0, fsgName) then Break;
    if filesCheck(Name, crax_Size, crax_CRC, fsgName + fsgSize + fsgCRC) then
     begin
      crax_Dupe:=True;
      Break;
     end;
    Inc(crax_Counter);
    Name:=uChangeFilename(OldName, crax_Counter, _83 or diGetBool(D, 'Crax\83'));
   until False;

  lngBegin;
   lngPush(OldName);
   lngPush(Long2Str(crax_Size));
   lngPush(HexL(crax_CRC));
   lngPush(Long2Str(TheStart));
   lngPush(Long2Str(TheEnd));
   lngPush(Long2Str(cmCount(crax_Image)));
   lngPush(Long2Str(TypeOfCrack));
   lngPUsh(crax_Title);
   lngPrint('Main', 'crax.found');
  lngEnd;

  if OldName <> Name then
   begin
    lngBegin;
     lngPush(OldName);
     lngPush(Name);
     lngPrint('Main', 'crax.renamed');
    lngEnd;
   end;

  if crax_Dupe then
   begin
    lngBegin;
     lngPush(Name);
     lngPrint('Main', 'crax.dupe.encountered');
    lngEnd;
    Exit;
   end;

  (* INF preparation %) *)

  Exclude:=diCreateList(D, 'Crax\Inf\Exclude');
  Include:=diCreateList(D, 'Crax\Inf\Include');

  cmFreeAll(crax_Inf);

  InsertToInf(diCreateList(D, 'Crax\Inf\Header'));

  for K:=1 to TheStart - 1 do
   begin
    GetPStringEx(cmAt(msg^.Data, K), S);
    B:=not CheckForMask(S, Exclude);
    if not B then
     B:=CheckForMask(S, Include);
    if B then
     cmInsert(crax_Inf, cmNewStr(S));
   end;

  InsertToInf(diCreateList(D, 'Crax\Inf\Center'));

  for K:=TheEnd + 1 to cmCount(msg^.Data) do
   begin
    GetPStringEx(cmAt(msg^.Data, K), S);
    B:=not CheckForMask(S, Exclude);
    if not B then
     B:=CheckForMask(S, Include);
    if B then
     cmInsert(crax_Inf, cmNewStr(S));
   end;

  InsertToInf(diCreateList(D, 'Crax\Inf\Footer'));

  (* Cutting %) *)

    B:=not CheckForMask(S, Exclude);
    if not B then
     B:=CheckForMask(S, Include);

  Cut:=Check2Masks(msg^.iArea, diCreateList(D, 'Crax\Skip\Cut\Areas'), 
       diCreateList(D, 'Crax\Remain\Cut\Areas')) and
       Check2Masks(Address2Str(msg^.iFromAddress), 
       diCreateList(D, 'Crax\Skip\Cut\Address'), 
       diCreateList(D, 'Crax\Remain\Cut\Address'));

  if Cut then
   Cut:=gGetDoubleBoolParam(Group, 'crax.Cut');

  if Cut then
   begin
    Macros:=umCreateMacros;

    umAddMacro(Macros, '@echo', msg^.iArea);
    umAddMacro(Macros, '@filename', Name);
    umAddMacro(Macros, '@subject', msg^.iSubj);
    umAddMacro(Macros, '@sender.name', msg^.iFrom);
    umAddMacro(Macros, '@receiver.name', msg^.iTo);
    umAddMacro(Macros, '@sender.address', Address2Str(msg^.iFromAddress));
    umAddMacro(Macros, '@receiver.address', Address2Str(msg^.iToAddress));
    umAddMacro(Macros, '@title', crax_Title);

    for K:=1 to TheEnd - TheStart + 1 do
     cmAtFree(msg^.Data, TheStart);

    List:=diCreateList(D, 'Crax\Inf');

    L:=TheStart;
    for K:=1 to cmCount(List) do
     begin
      GetPStringEx(cmAt(List, K), S);
      S:=umProcessMacro(Macros, S);
      if not umEmptyLine(Macros) then
       begin
        cmAtInsert(msg^.Data, cmNewStr(S), L);
        Inc(L);
       end;
     end;

    crax_TargetLine:=TheStart + cmCount(List);

    umDestroyMacros(Macros);
   end;

  (* FilesBBS *)
  if diGetBool(D, 'Crax\Put') then
   begin
    sSetSemaphore('FilesBBS.FileInfo.Area', msg^.iArea);
    sSetSemaphore('FilesBBS.FileInfo.Sender.Name', msg^.iFrom);
    sSetSemaphore('FilesBBS.FileInfo.Sender.Address', Address2Str(msg^.iFromAddress));
    sSetSemaphore('FilesBBS.FileInfo.Receiver.Name', msg^.iTo);
    sSetSemaphore('FilesBBS.FileInfo.Receiver.Address', Address2Str(msg^.iToAddress));
    sSetSemaphore('FilesBBS.FileInfo.Subject', msg^.iSubj);
    sSetSemaphore('FilesBBS.FileInfo.Title', crax_Title);
    sSetSemaphore('FilesBBS.FileInfo.BBSLines', HexPtr(diCreateList(D, 'Crax\Put\FilesBBS')));
    sSetSemaphore('FilesBBS.FileInfo.TempFilename', crax_TempFileName);
    sSetSemaphore('FilesBBS.FileInfo.Filename', Name);
    sSetSemaphore('FilesBBS.FileInfo.DirFilename', gGetParam(Group, 'crax.put.directory'));

    if gGetBoolParam(Group, 'crax.put.filesbbs') then begin
     sSetSemaphore('FilesBBS.FileInfo.FilesBBS', gGetParam(Group, 'crax.put.filesbbs.name'));
     sSetSemaphore('FilesBBS.FileInfo.DirFilesBBS', gGetParam(Group, 'crax.put.filesbbs.directory'));
    end else begin
     sSetSemaphore('FilesBBS.FileInfo.FilesBBS', '');
     sSetSemaphore('FilesBBS.FileInfo.DirFilesBBS', '');
    end;

    sSetSemaphore('FilesBBS.FileInfo.Packer', '');
    sSetSemaphore('FilesBBS.FileInfo.RePacker', '');
    sSetSemaphore('FilesBBS.FileInfo.Convert', 'No');

    if gGetBoolParam(Group, 'crax.put.inf') then
     begin
      sSetSemaphore('FilesBBS.FileInfo.Inf', 'Yes');
      sSetSemaphore('FilesBBS.FileInfo.PackInf', 'No');
      sSetSemaphore('FilesBBS.FileInfo.Inf.Lines', HexPtr(crax_Inf));
      sSetSemaphore('FilesBBS.FileInfo.Inf.Name', gGetParam(Group, 'crax.put.inf.name'));
      sSetSemaphore('FilesBBS.FileInfo.Inf.Dir', gGetParam(Group, 'crax.put.inf.directory'));
     end
    else
     sSetSemaphore('FilesBBS.FileInfo.Inf', 'No');

    sSetSemaphore('FilesBBS.FileInfo.File_Id.Diz', 'No');

    if gGetBoolParam(Group, 'crax.Put.List') then
     begin
      sSetSemaphore('FilesBBS.FileInfo.List', 'Yes');
      sSetSemaphore('FilesBBS.FileInfo.List.FileName', gGetParam(Group, 'crax.Put.List.FileName'));
     end
    else
     sSetSemaphore('FilesBBS.FileInfo.List', 'No');

    if gGetBoolParam(Group, 'crax.Put.DirDesc') then
     begin
      sSetSemaphore('FilesBBS.FileInfo.DirDesc', 'Yes');
      sSetSemaphore('FilesBBS.FileInfo.DirDesc.FileName', gGetParam(Group, 'crax.Put.DirDesc.FileName'));
      sSetSemaphore('FilesBBS.FileInfo.DirDesc.Lines', HexPtr(diCreateList(D, 'Crax\Put\DirDesc')));
     end
    else
     sSetSemaphore('FilesBBS.FileInfo.DirDesc', 'No');

    sSetSemaphore('FilesBBS.FileInfo.CheckDupes', gGetParam(Group, 'crax.put.checkdupes'));
    sSetSemaphore('FilesBBS.FileInfo.CheckDupes.Memorize', gGetParam(Group, 'crax.put.checkdupes.memorize'));
    sSetSemaphore('FilesBBS.FileInfo.83', gGetParam(Group, 'crax.put.83'));

    Ok:=srvExecute('FILESBBS', snfPutFile, nil) = srfOk;

    if not Ok then
     begin
      lngBegin;
      lngPush('FILESBBS');
      lngPrint('Main', 'crax.some.error');
      lngEnd;
     end;
   end;

  (* Hatcher *)
  if diGetBool(D, 'Crax\Hatch') then
   begin
    sSetSemaphore('Hatcher.FileInfo.Area', msg^.iArea);
    sSetSemaphore('Hatcher.FileInfo.Sender.Name', msg^.iFrom);
    sSetSemaphore('Hatcher.FileInfo.Sender.Address', Address2Str(msg^.iFromAddress));
    sSetSemaphore('Hatcher.FileInfo.Receiver.Name', msg^.iTo);
    sSetSemaphore('Hatcher.FileInfo.Receiver.Address', Address2Str(msg^.iToAddress));
    sSetSemaphore('Hatcher.FileInfo.Subject', msg^.iSubj);
    sSetSemaphore('Hatcher.FileInfo.Title', crax_Title);
    sSetSemaphore('Hatcher.FileInfo.TempFilename', crax_TempFileName);
    sSetSemaphore('Hatcher.FileInfo.Filename', Name);
    sSetSemaphore('Hatcher.FileInfo.Packer', '');
    sSetSemaphore('Hatcher.FileInfo.Repacker', '');
    sSetSemaphore('Hatcher.FileInfo.Convert', '');
    sSetSemaphore('Hatcher.FileInfo.Inf', 'No');
    sSetSemaphore('Hatcher.FileInfo.File_Id.Diz', 'No');
    sSetSemaphore('Hatcher.FileEcho', gGetParam(Group, 'crax.hatch.fileecho'));
    sSetSemaphore('Hatcher.FileEcho.Tic.Name', gGetParam(Group, 'crax.hatch.tic.name'));
    if gGetParam(Group, 'crax.hatch.tic.directory') <> '' then
     sSetSemaphore('Hatcher.FileEcho.Tic.Dir', gGetParam(Group, 'crax.hatch.tic.directory'))
    else
     sSetSemaphore('Hatcher.FileEcho.Tic.Dir', gGetParam(Group, 'crax.hatch.inbound'));
    sSetSemaphore('Hatcher.FileEcho.Inbound', gGetParam(Group, 'crax.hatch.inbound'));
    sSetSemaphore('Hatcher.FileEcho.Tic.Name', gGetParam(Group, 'crax.hatch.tic.name'));
    sSetSemaphore('Hatcher.FileEcho.Tic.Lines', HexPtr(diCreateList(D, 'Crax\Hatch\Tic')));
    if gGetBoolParam(Group, 'crax.hatch.List') then
     begin
      sSetSemaphore('Hatcher.FileInfo.List', 'Yes');
      sSetSemaphore('Hatcher.FileInfo.List.FileName', gGetParam(Group, 'crax.Hatch.List.FileName'));
     end
    else
     sSetSemaphore('Hatcher.FileInfo.List', 'No');

    sSetSemaphore('Hatcher.FileInfo.CheckDupes', gGetParam(Group, 'crax.hatch.checkdupes'));
    sSetSemaphore('Hatcher.FileInfo.CheckDupes.Memorize', gGetParam(Group, 'crax.hatch.checkdupes.memorize'));
    sSetSemaphore('Hatcher.FileInfo.83', gGetParam(Group, 'crax.hatch.83'));

    Ok:=srvExecute('HATCHER', snhHatchFile, nil) = srfOk;
    if not Ok then
     begin
      lngBegin;
       lngPush('FILESBBS');
       lngPrint('Main', 'crax.some.error');
      lngEnd;
     end;
   end;

  (* Announce [1] *)
  if diGetBool(D, 'Crax\Announce') and annCheck then
   begin
    sSetSemaphore('Announcer.Mode', '1');
    sSetSemaphore('Announcer.Lines', HexPtr(crax_Inf));
    sSetSemaphore('Announcer.Area', msg^.iArea);
    sSetSemaphore('Announcer.Prefix', 'crax.');
    sSetSemaphore('Announcer.Sender.Name', msg^.iFrom);
    sSetSemaphore('Announcer.Sender.Address', Address2Str(msg^.iFromAddress));
    sSetSemaphore('Announcer.Receiver.Name', msg^.iTo);
    sSetSemaphore('Announcer.Receiver.Address', Address2Str(msg^.iToAddress));
    sSetSemaphore('Announcer.Subject', msg^.iSubj);
    sSetSemaphore('Announcer.FileName', Name);
    sSetSemaphore('Announcer.FileSize', Long2Str(crax_Size));
    sSetSemaphore('Announcer.FileEcho', gGetParam(Group, 'crax.hatch.fileecho'));
    sSetSemaphore('Announcer.FileDirectory', gGetParam(Group, 'crax.put.directory'));
    sSetSemaphore('Announcer.Title', crax_Title);
    K:=annProcessAnnounce;
    if K <> srYes then
     begin
      lngBegin;
       lngPush(HexL(K));
       lngPrint('Main', 'crax.error.announcing');
      lngEnd;
     end;
   end;

  (* Announce [2] *)
  if diGetBool(D, 'Crax\Announce\List') and annCheck then
   begin
    diSetBool(D, 'Crax\Announce\List\Done', True);
    diSetBool(D, 'Crax\Announce\List\Done.2', True);

    Macros:=umCreateMacros;
    umAddMacro(Macros, '@echo', msg^.iArea);
    umAddMacro(Macros, '@filename', Name);
    umAddMacro(Macros, '@size', Long2Str(crax_Size));
    umAddMacro(Macros, '@subject', msg^.iSubj);
    umAddMacro(Macros, '@title', crax_Title);
    umAddMacro(Macros, '@sender.name', msg^.iFrom);
    umAddMacro(Macros, '@receiver.name', msg^.iTo);
    umAddMacro(Macros, '@sender.address', Address2Str(msg^.iFromAddress));
    umAddMacro(Macros, '@receiver.address', Address2Str(msg^.iToAddress));

    List:=diCreateList(D, 'Crax\Announce\List\Center');
    AnotherList:=diCreateList(D, 'Crax\Announce\List\Data');

    for K:=1 to cmCount(List) do
     begin
      GetPStringEx(cmAt(List, K), S);
      S:=umProcessMacro(Macros, S);
      if not umEmptyLine(Macros) then
       cmInsert(AnotherList, cmNewStr(S));
     end;

    diSetNum(D, 'Crax\Announce\List\Count', diGetNum(D, 'Crax\Announce\List\Count') + 1);
    diSetNum(D, 'Crax\Announce\List\Size', diGetNum(D, 'Crax\Announce\List\Size') + crax_Size);

    umDestroyMacros(Macros);
   end;

  if diGetBool(D, 'Crax\CheckDupes\Memorize') then
   filesAddSpool(Name, crax_Size, crax_CRC);
  filesFlushSpool;
 end;

{*** Post List-Announces ***}

procedure craxDoPreProcess;
 var
  D2, MergeList: Pointer;
  K, L: Longint;
  S: String;
 begin
  MergeList:=diCreateList(D, 'Crax\Announce\List\Merge');

  for K:=1 to cmCount(MergeList) do
   begin
    GetPStringEx(cmAt(MergeList, K), S);
    Group:=gSearch(S);
    if Group = Nil then
     begin
      lngBegin;
       lngPush(S);
       lngPrint('Main', 'crax.unknown.group');
      lngEnd;
     end
    else
     begin
      D2:=diCreate(Longint(Group));
      if diGetBool(D2, 'Crax\Announce\List\Done.2') then
       begin
        diSetBool(D2, 'Crax\Announce\List\Done', False);

        diSetNum(D, 'Crax\Announce\List\Count', diGetNum(D, 'Crax\Announce\List\Count') +
         diGetNum(D2, 'Crax\Announce\List\Count'));

        diSetNum(D, 'Crax\Announce\List\Size', diGetNum(D, 'Crax\Announce\List\Size') +
         diGetNum(D2, 'Crax\Announce\List\Size'));
       end;
     end;
   end;

 end;

procedure craxDoPost;
 var
  List, AnotherList, MergeList: PStrings;
  __TotalFiles, __TotalSize: Longint;
 procedure AddToList(const Key: String);
  var
   Macros: Pointer;
   K: Longint;
   S: String;
  begin
   Macros:=umCreateMacros;

   umAddMacro(Macros, '@totalfiles', Long2Str(__TotalFiles));
   umAddMacro(Macros, '@totalsize', Long2Str(__TotalSize));

   AnotherList:=diCreateList(D, Key);
   for K:=1 to cmCount(AnotherList) do
    begin
     GetPStringEx(cmAt(AnotherList, K), S);
     S:=umProcessMacro(Macros, S);
     if not umEmptyLine(Macros) then
      cmInsert(List, cmNewStr(S));
    end;
   umDestroyMacros(Macros);
  end;
 var
  K, L: Longint;
  S: String;
 begin
  cmCreateStrings(List);

  __TotalFiles:=diGetNum(D, 'Crax\Announce\List\Count');
  __TotalSize:=diGetNum(D, 'Crax\Announce\List\Size');

  AddToList('Crax\Announce\List\Header');

  AnotherList:=diCreateList(D, 'Crax\Announce\List\Data');

  { add our own files }

  for K:=1 to cmCount(AnotherList) do
   begin
    GetPStringEx(cmAt(AnotherList, K), S);
    cmInsert(List, cmNewStr(S));
   end;

  { add merged files %) }

  MergeList:=diCreateList(D, 'Crax\Announce\List\Merge');

  for K:=1 to cmCount(MergeList) do
   begin
    GetPStringEx(cmAt(MergeList, K), S);
    Group:=gSearch(S);
    if Group = Nil then
     begin
      lngBegin;
       lngPush(S);
       lngPrint('Main', 'crax.unknown.group');
      lngEnd;
     end
    else
     begin
      D:=diCreate(Longint(Group));
      if diGetBool(D, 'Crax\Announce\List\Done.2') then
       begin
        AnotherList:=diCreateList(D, 'Crax\Announce\List\Data');
        for L:=1 to cmCount(AnotherList) do
         begin
          GetPStringEx(cmAt(AnotherList, L), S);
          cmInsert(List, cmNewStr(S));
         end;
       end;
     end;
   end;

  AddToList('Crax\Announce\List\Footer');

  sSetSemaphore('Announcer.Mode', '2');
  sSetSemaphore('Announcer.Lines', HexPtr(List));
  sSetSemaphore('Announcer.Prefix', 'crax.List.');
  sSetSemaphore('Announcer.Area', msg^.iArea);

  K:=annProcessAnnounce;
  if K <> srYes then
   begin
    lngBegin;
     lngPush(HexL(K));
     lngPrint('Main', 'crax.error.announcing');
    lngEnd;
   end;

  cmDisposeObject(List);
 end;

procedure craxScanEnd;
 var
  K: Longint;
 begin
  AnotherD:=diCreate(0);

  { pre-processing (required for merging) }

  for K:=1 to diGetNum(AnotherD, 'Crax\Enum\Size') do
   begin
    D:=Pointer(diGetNum(AnotherD, 'Crax\Enum\' + Long2Str(K)));

    if diGetBool(D, 'Crax\Announce\List\Done') then
     craxDoPreProcess;
   end;

  { main processing }

  for K:=1 to diGetNum(AnotherD, 'Crax\Enum\Size') do
   begin
    D:=Pointer(diGetNum(AnotherD, 'Crax\Enum\' + Long2Str(K)));

    if diGetBool(D, 'Crax\Announce\List\Done') then
     begin
      lngBegin;
       lngPush(diGetString(D, 'Crax\GroupName'));
       lngPush(diGetString(D, 'Crax\GroupDesc'));
       lngPrint('Main', 'crax.list.doing');
      lngEnd;
      craxDoPost;
     end;
   end;
 end;

{*** SkullC0DEr's "Wadda stuff?!" ***}
procedure crack_Wadda;
 var
  K: Longint;
  L: Longint;
  Bad: Longint;
  C: Boolean;
 begin
  crax_Title:=Copy(crax_S, 15, 255);
  TrimEx(crax_Title);
  Bad:=0;
  L:=crax_StartLine;
  K:=crax_StartLine;
  C:=False;
  repeat
   Inc(K);
   if K > crax_Count then Break;
   GetPStringEx(cmAt(Msg^.Data, K), crax_S);
   if IsHexLine(crax_S) then
    begin
     L:=K;
     C:=True;
    end
   else
    if crax_S <> '' then
     if (not IsWaddaLine(crax_S)) or (C) then
      begin
       Inc(Bad);
       if Bad > crax_Wadda_BadCount then Break;
      end;
  until False;
  if Bad > crax_Wadda_BadCount then
   crax_Error
  else
   crax_Process(crax_StartLine, L, crax_Wadda);
 end;

{*** XCK ***}
procedure crack_XCK(T: Longint);
 var
  B, C: Boolean;
  K, L: Longint;
 begin
  B:=False;
  C:=False;
  K:=crax_StartLine;
  crax_Title:='';
  repeat
   Inc(K);
   if K > crax_Count then Break;
   GetPStringEx(cmAt(Msg^.Data, K), crax_S);
   TrimEx(crax_S);
   crax_Su:=crax_S;
   StUpcaseEx(crax_Su);
   if IsMask(crax_Su, crax_Mask, crax_XCK_Masks) then
    begin
     Delete(crax_S, 1, Length(crax_Mask));
     while (crax_S[0] <> #0) and (crax_S[1] in BadSymbolsEx) do
      Delete(crax_S, 1, 1);
     while (crax_S[0] <> #0) and (crax_S[Byte(crax_S[0])] in BadSymbols) do
      Dec(crax_S[0]);
     crax_TargetLine:=K;
     crax_Title:=crax_S;
     B:=True;
     Break;
    end;
  until False;
  if crax_Title = '' then
   begin
    GetPStringEx(cmAt(Msg^.Data, crax_StartLine + 1), crax_Title);
    B:=True;
   end;
  if (crax_Title = '') or (Pos('[BEGIN', StUpcase(crax_Title)) <> 0) then
   begin
    GetPStringEx(cmAt(Msg^.Data, crax_StartLine + 2), crax_Title);
    B:=True;
   end;
  if (crax_Title = '') or (Pos('[BEGIN', StUpcase(crax_Title)) <> 0) then
   begin
    GetPStringEx(cmAt(Msg^.Data, crax_StartLine + 2), crax_Title);
    crax_Dump(crax_Count, 'Mystique title');
    B:=True;
    crax_TargetLine:=crax_StartLine + 2;
   end;
  if not B then
   begin
    crax_Dump(crax_Count, 'WTF?');
    Exit;
   end;
  B:=False;
  K:=crax_StartLine;
  L:=0;
  repeat
   Inc(K);
   if K > crax_Count then Break;
   GetPStringEx(cmAt(Msg^.Data, K), crax_S);
   StUpcaseEx(crax_S);
   if Pos('[END', crax_S) <> 0 then
    case T of
     crax_XCK:
      if Pos('[ENDXCK]', crax_S) <> 0 then
       begin
        crax_TargetLine:=K;
        B:=True;
        Break;
       end else
      if Pos('[ENDCRK]', crax_S) <> 0 then
       L:=K;
     crax_XCK_CRK:
      if Pos('[ENDCRK]', crax_S) <> 0 then
       begin
        crax_TargetLine:=K;
        B:=True;
        Break;
       end else
      if Pos('[ENDXCK]', crax_S) <> 0 then
       L:=K;
     crax_XCK_CRX:
      if Pos('[ENDCRX', crax_S) <> 0 then
       begin
        crax_TargetLine:=K;
        B:=True;
        Break;
       end else
      if Pos('[ENDXCK]', crax_S) <> 0 then
       L:=K else
      if Pos('[ENDCRK]', crax_S) <> 0 then
       L:=K;
    end;
  until False;
  if (not B) and (L <> 0) then
   begin
    crax_TargetLine:=L;
    B:=True;
   end;
  if not B then
   if SeekLastHex(crax_TargetLine) then
    B:=True;
  if not B then
   begin
    crax_Dump(crax_Count, 'End is not found');
    Exit;
   end;
  crax_Process(crax_StartLine, crax_TargetLine, crax_XCK);
 end;

{*** CRK ***}
procedure crack_CRK;
 procedure crack_Dec(var X:LongInt; Decrement:Longint);
 var P:PString;
     L:Longint;
 begin
  L:=X;
  Dec(X, Decrement);
  repeat
   if L=X then Break;

   P:=cmAt(Msg^.Data, X);
   if P<>nil then
    if P^[1]<>#01 then Break;

   Inc(X);
  until false;
 end;

 var L:Longint;
 begin
  crax_Title:='';
  if GetLine(crax_StartLine - 3) = '' then
   begin
    L:=crax_StartLine;
    crack_Dec(crax_StartLine, 4);
    if (crax_StartLine<>L) then crax_Title:=GetLine(crax_StartLine);
   end;
  if crax_Title = '' then
   begin
    L:=crax_StartLine;
    crack_Dec(crax_StartLine, 1);
    if (crax_StartLine<>L) then crax_Title:=GetLine(crax_StartLine);
   end;

  TrimEx(crax_Title);
  if SeekLastHex(crax_TargetLine) then
   crax_Process(crax_StartLine, crax_TargetLine, crax_CRK)
  else
   crax_Dump(crax_Count, 'End is not found');
 end;

{*** general message handler ***}
procedure craxMessage;
 var
  K: Longint;
 procedure Check;
  begin
   if K < 1 then K:=1;
   crax_Count:=cmCount(Msg^.Data);
  end;
 procedure Crack(What: Byte);
  begin
   crax_StartLine:=K;
   crax_TargetLine:=K;
   case What of
    crax_Wadda: crack_Wadda;
    crax_XCK: crack_XCK(crax_XCK);
    crax_XCK_CRK: crack_XCK(crax_XCK_CRK);
    crax_XCK_CRX: crack_XCK(crax_XCK_CRX);
    crax_CRK: crack_CRK;
   end;
   K:=crax_TargetLine;
   if K < 1 then K:=1;
  end;
 begin
  K:=0;
  crax_Count:=cmCount(Msg^.Data);
  repeat
   Inc(K);
   if K > crax_Count then Break;
   crax_S:=GetPString(cmAt(Msg^.Data, K));
   crax_Su:=StUpcase(crax_S);
   if Copy(crax_S, 1, 13) = '|Wadda stuff:' then Crack(crax_Wadda);
   if Pos('[BEGIN', crax_Su) <> 0 then
    repeat
     if Pos('[BEGINXCK]', crax_Su) <> 0 then
      Crack(crax_XCK) else
     if Pos('[BEGINCRK]', crax_Su) <> 0 then
      Crack(crax_XCK_CRK) else
     if Pos('[BEGINCRX', crax_Su) <> 0 then
      Crack(crax_XCK_CRX) else
      Break;
    until True;
   if IsHexLine(crax_S) then
    Crack(crax_CRK);
  until False;
 end;

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint; {$IFNDEF SOLID}export;{$ENDIF}
 var
  S: String;
 begin
  Service:=srYes;
  case ServiceNumber of
   snStartup: Service:=craxStartup;
   snStart:;
   snShutdown: craxShutdown;
   snAfterStartup:;
   snQueryName: sSetSemaphore('Kernel.Plugins.Info.Name','CRAx');
   snQueryAuthor: sSetSemaphore('Kernel.Plugins.Info.Author','sergey korowkin');
   snQueryVersion: Service:=craxVersion;
   snQueryReqVer: Service:=kernelVersion;
   snsMessage:
    if craxCollect then
     begin
      msg:=Buffer;
      craxMessage;
     end;
   snsScanEnd: craxScanEnd;
   snsAreYouScanner: Service:=snrIamScanner;
  else
   Service:=srNotSupported;
  end;
 end;

{$IFNDEF SOLID}
exports
 SERVICE;

begin
{$ENDIF}
end.
