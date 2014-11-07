{
 Common.Dll
 пользовательский плагин для FastUUE
 в целом, (c) by sergey korowkin, 1997-98.

 FastUUE Macros Engine (c) by sk // [rAN] [2:5033/27], 1998.
 Вычисление CRC-32 (c) by Harms Software Engineering, 1992-97.
}
{$F+}
{$IFDEF SOLID}
unit Common;

interface

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint;

implementation
{$ELSE}
library Common;
{$ENDIF}

{$IFDEF VIRTUALPASCAL}
uses
     Types, Consts_, Log, Video, Wizard, Misc, Language, Config, Semaphor,
     Plugins, Dos, Macroz;
{$IFNDEF SOLID}
{$Dynamic MAIN.LIB}
{$ENDIF}
{$ENDIF}
{$IFDEF DPMI}
uses
{$IFDEF SOLID}
     Plugins, Semaphor, Language,
{$ELSE}
     Decl,
{$ENDIF}
     Types, Consts_, Wizard, Dos, Macroz;
{$ENDIF}

{$i Common.Inc}
{$i FastUUE.Inc}
{$i Files.Inc}

{$IFNDEF VIRTUALPASCAL}
procedure FSplit(const Path: String; var Dir: String; var Name: String; var Ext: String);
var
  I,NamePos,ExtPos: Integer;
begin
  NamePos := 0;
  ExtPos  := 256;
  for I := 1 to Length(Path) do
  case Path[I] of
    ':','\':
      begin
        NamePos := I;
        ExtPos  := 256;
      end;
    '.': ExtPos := I;
  end;
  Dir  := Copy(Path, 1, NamePos);
  Name := Copy(Path, NamePos+1, ExtPos-NamePos-1);
  Ext  := Copy(Path, ExtPos, 255);
end;
{$ENDIF}

const
 userVersion = $00010600;
 Crc32Tab: array[0..255] of longint = ($00000000, $77073096, $ee0e612c, $990951ba, $076dc419, $706af48f, $e963a535,$9e6495a3,
                                       $0edb8832, $79dcb8a4, $e0d5e91e, $97d2d988, $09b64c2b, $7eb17cbd, $e7b82d07,$90bf1d91,
                                       $1db71064, $6ab020f2, $f3b97148, $84be41de, $1adad47d, $6ddde4eb, $f4d4b551,$83d385c7,
                                       $136c9856, $646ba8c0, $fd62f97a, $8a65c9ec, $14015c4f, $63066cd9, $fa0f3d63,$8d080df5,
                                       $3b6e20c8, $4c69105e, $d56041e4, $a2677172, $3c03e4d1, $4b04d447, $d20d85fd,$a50ab56b,
                                       $35b5a8fa, $42b2986c, $dbbbc9d6, $acbcf940, $32d86ce3, $45df5c75, $dcd60dcf,$abd13d59,
                                       $26d930ac, $51de003a, $c8d75180, $bfd06116, $21b4f4b5, $56b3c423, $cfba9599,$b8bda50f,
                                       $2802b89e, $5f058808, $c60cd9b2, $b10be924, $2f6f7c87, $58684c11, $c1611dab,$b6662d3d,
                                       $76dc4190, $01db7106, $98d220bc, $efd5102a, $71b18589, $06b6b51f, $9fbfe4a5,$e8b8d433,
                                       $7807c9a2, $0f00f934, $9609a88e, $e10e9818, $7f6a0dbb, $086d3d2d, $91646c97,$e6635c01,
                                       $6b6b51f4, $1c6c6162, $856530d8, $f262004e, $6c0695ed, $1b01a57b, $8208f4c1,$f50fc457,
                                       $65b0d9c6, $12b7e950, $8bbeb8ea, $fcb9887c, $62dd1ddf, $15da2d49, $8cd37cf3,$fbd44c65,
                                       $4db26158, $3ab551ce, $a3bc0074, $d4bb30e2, $4adfa541, $3dd895d7, $a4d1c46d,$d3d6f4fb,
                                       $4369e96a, $346ed9fc, $ad678846, $da60b8d0, $44042d73, $33031de5, $aa0a4c5f,$dd0d7cc9,
                                       $5005713c, $270241aa, $be0b1010, $c90c2086, $5768b525, $206f85b3, $b966d409,$ce61e49f,
                                       $5edef90e, $29d9c998, $b0d09822, $c7d7a8b4, $59b33d17, $2eb40d81, $b7bd5c3b,$c0ba6cad,
                                       $edb88320, $9abfb3b6, $03b6e20c, $74b1d29a, $ead54739, $9dd277af, $04db2615,$73dc1683,
                                       $e3630b12, $94643b84, $0d6d6a3e, $7a6a5aa8, $e40ecf0b, $9309ff9d, $0a00ae27,$7d079eb1,
                                       $f00f9344, $8708a3d2, $1e01f268, $6906c2fe, $f762575d, $806567cb, $196c3671,$6e6b06e7,
                                       $fed41b76, $89d32be0, $10da7a5a, $67dd4acc, $f9b9df6f, $8ebeeff9, $17b7be43,$60b08ed5,
                                       $d6d6a3e8, $a1d1937e, $38d8c2c4, $4fdff252, $d1bb67f1, $a6bc5767, $3fb506dd,$48b2364b,
                                       $d80d2bda, $af0a1b4c, $36034af6, $41047a60, $df60efc3, $a867df55, $316e8eef,$4669be79,
                                       $cb61b38c, $bc66831a, $256fd2a0, $5268e236, $cc0c7795, $bb0b4703, $220216b9,$5505262f,
                                       $c5ba3bbe, $b2bd0b28, $2bb45a92, $5cb36a04, $c2d7ffa7, $b5d0cf31, $2cd99e8b,$5bdeae1d,
                                       $9b64c2b0, $ec63f226, $756aa39c, $026d930a, $9c0906a9, $eb0e363f, $72076785,$05005713,
                                       $95bf4a82, $e2b87a14, $7bb12bae, $0cb61b38, $92d28e9b, $e5d5be0d, $7cdcefb7,$0bdbdf21,
                                       $86d3d2d4, $f1d4e242, $68ddb3f8, $1fda836e, $81be16cd, $f6b9265b, $6fb077e1,$18b74777,
                                       $88085ae6, $ff0f6a70, $66063bca, $11010b5c, $8f659eff, $f862ae69, $616bffd3,$166ccf45,
                                       $a00ae278, $d70dd2ee, $4e048354, $3903b3c2, $a7672661, $d06016f7, $4969474d,$3e6e77db,
                                       $aed16a4a, $d9d65adc, $40df0b66, $37d83bf0, $a9bcae53, $debb9ec5, $47b2cf7f,$30b5ffe9,
                                       $bdbdf21c, $cabac28a, $53b39330, $24b4a3a6, $bad03605, $cdd70693, $54de5729,$23d967bf,
                                       $b3667a2e, $c4614ab8, $5d681b02, $2a6f2b94, $b40bbe37, $c30c8ea1, $5a05df1b,$2d02ef8d);

function GetCRC(FName: String): Longint;
 type
  PBuffer = ^TBuffer;
  TBuffer = array[1..65520] of byte;
 const
  Buffer: PBuffer = nil;
  Size: Longint = 65520;
  CRC: Longint = 0;
  Count: Longint = 0;
  N: Longint = 0;
  K: Longint = 0;
  F: PDosStream = nil;
 var
  Loop: Longint;
 begin
  CRC:=$FFFFFFFF;
  GetMem(Buffer, Size);
  F:=New(PDosStream, Init(FName, stOpenRead));
  sSetSemaphore('User.Crc32.Error', Long2Str(F^.Status));
  if F^.Status<>stOk then
   begin
    GetCRC:=CRC;
    Dispose(F, Done);
    Exit;
   end;
  Count:=F^.GetSize;
  while Count>0 do
   begin
    if Count>Size then N:=Size else N:=Count;
    F^.Read(Buffer^, N);
    Dec(Count, N);
    for Loop:=1 to N do
     CRC:=crc32tab[byte(crc xor longint(Buffer^[Loop]))] xor ((crc shr 8) and $00FFFFFF);
   end;
  CRC:=not CRC;
  Dispose(F, Done);
  FreeMem(Buffer, Size);
  GetCRC:=CRC;
 end;

const
 OldMSGiD: Longint = $00000000;

{$q-}
function GetMSGiD: String;
 var
  Stamp: Longint;
{$IFDEF VIRTUALPASCAL}
  Year, Month, Day, Dow, Hour, Min, Sec, Sec100: Longint;
{$ELSE}
  Year, Month, Day, Dow, Hour, Min, Sec, Sec100: Word;
{$ENDIF}
  DT: DateTime;
 begin
  repeat
   GetDate(Year, Month, Day, Dow);
   GetTime(Hour, Min, Sec, Sec100);
   Stamp:=Longint(Year + 10) * 355 * 24 * 60 * 60;
   Stamp:=Stamp + Longint(Month) * 30 * 24 * 60 * 60;
   Stamp:=Stamp + Longint(Day) * 24 * 60 * 60;
   Stamp:=Stamp + Longint(Hour) * 60 * 60;
   Stamp:=Stamp + Longint(Min) * 60;
   Stamp:=Stamp + Longint(Sec);
   Stamp:=(Stamp shl 7) or (Sec100 and $7F);
  until OldMSGiD <> Stamp;
  OldMSGiD:=Stamp;
  GetMSGiD:=StLocase(HexL(Stamp));
 end;
{$q+}

function InvalidateLine(S: String): String;
 begin
  if S[0] <> #0 then
   begin
    if S[1] = #1 then S[1]:='@';
    if Copy(S, 1, 5) = 'AREA:' then S:='@' + S;
    if Copy(S, 1, 3) = '---' then S[2]:='+';
    if Copy(S, 1, 10) = ' * Origin:' then S[2]:='+';
    if Copy(S, 1, 7) = 'SEEN-BY' then S[5]:='+';
   end;
  InvalidateLine:=S;
 end;

function ChangeFilename(const S: String; Count: Longint; _83: Boolean): String;
 var
  Dir, Name, Ext, Counter: String;

 begin
  FSplit(S, Dir, Name, Ext);

  Counter:=Long2Str(Count);

  if _83 then
   while Length(Name + Counter) > 8 do Dec(Name[0]);

  ChangeFilename:=Dir + Name + Counter + Ext;
 end;

const
 _DigitsChars: string[36] = 'QWERTYUIOPASDFGHJKLZXCVBNM1234567890';
 _Digits: string[10] = '1234567890';
 _DigitsHex: string[16] = '0123456789ABCDEF';
var
 _Dir, _Name, _Ext: String;

procedure CheckBadSym(var S: String);
 var
  D: String;
  K: Byte;
 begin
  D:='';
  for K:=1 to Length(S) do
   case S[K] of
    'A'..'Z',
    'a'..'z',
    '0',
    '1'..'9',
    '-', '$',
{$IFDEF VIRTUALPASCAL}
    ' ',
    'А'..'Я',
    'а'..'п',
    'р'..'ё',
{$ENDIF}
    '_', '~': D:=D + S[K];
   end;
  S:=D;
 end;

function CleanupSubj(S: String): String;
 var
  S1: String;
 begin
  S1:=StUpcase(ExtractWord(1, S, [':',' ']));
  if (Copy(S1, 1, 2)='RE') and (S1[0]<#6) then
   begin
    Delete(S, 1, Length(S1)+1);
    if S[1]=' ' then Delete(S, 1, 1);
   end;
  CleanupSubj:=S;
 end;

function CheckBadFName(S: String): String;
 var
  Path, FName, Ext: String;
  FNameEx: String;
 begin
  FSplit(S, Path, FName, Ext);

  Delete(Ext, 1, 1);

  CheckBadSym(FName);
  CheckBadSym(Ext);

  S:=Path + FName;

  FNameEx:=FName;

  StUpcaseEx(FNameEx);

  if FNameEx = 'CON' then FName:='_CON';
  if FNameEx = 'PRN' then FName:='_PRN';
  if FNameEx = 'AUX' then FName:='_AUX';

  if Copy(FNameEx, 1, 3) = 'LPT' then FName:='_' + FName;
  if Copy(FNameEx, 1, 3) = 'COM' then FName:='_' + FName;

  if Ext <> '' then S:=S + '.' + Ext;

  if S = '' then
   S:='$bad$';

  if S[1] = '.' then
   S:='$bad' + S;

  CheckBadFName:=S;
 end;

{*** Macros Engine ***}
type
 PMacrosCollection = ^TMacrosCollection;
 TMacrosCollection = object(TCollection)
  procedure FreeItem(Item: Pointer); virtual;
 end;

 PMacrosEngine = ^TMacrosEngine;
 TMacrosEngine = object(TMacros)
 public
  Container: PMacrosCollection;
  procedure AddAdditionalMacros; virtual;
  procedure ContainerInit; virtual;
  function ContainerSize: Longint; virtual;
  function ContainerAt(Index: Longint): PMacro; virtual;
  procedure ContainerInsert(Macro: PMacro); virtual;
  procedure ContainerFree(Macro: PMacro); virtual;
  procedure ContainerDone; virtual;
 end;

procedure TMacrosCollection.FreeItem(Item: Pointer);
 begin
  Dispose(PMacro(Item), Done);
 end;

procedure TMacrosEngine.AddAdditionalMacros;
 var
  Day, Month, Year, Hour, Min, Sec, Dow: Word;
 begin
  IWannaTime(Hour, Min, Sec);
  IWannaDate(Day, Month, Year);
  Dow:=DayOfWeek(Year, Month, Day);
  AddMacro('@longversion', 'FastUUE/'+OS_Short+' '+sGetSemaphore('Kernel.Version')+' (c) by sergey korowkin, 1999.', mcUser);
  AddMacro('@shortversion', 'FastUUE/'+OS_Short+' '+sGetSemaphore('Kernel.Version'), mcUser);
  AddMacro('@curhour', LeftPadCh(Long2Str(Hour), '0', 2), mcUser);
  AddMacro('@curmin', LeftPadCh(Long2Str(Min), '0', 2), mcUser);
  AddMacro('@cursec', LeftPadCh(Long2Str(Sec), '0', 2), mcUser);
  AddMacro('@curday', LeftPadCh(Long2Str(Day), '0', 2), mcUser);
  AddMacro('@curmonth', LeftPadCh(Long2Str(Month), '0', 2), mcUser);
  AddMacro('@curyear', LeftPadCh(Long2Str(Year), '0', 2), mcUser);
  AddMacro('@curdow', lngGet('longdow.' + Long2Str(Dow)), mcUser);
  AddMacro('@curshortdow', lngGet('shortdow.' + Long2Str(Dow)), mcUser);
 end;

procedure TMacrosEngine.ContainerInit;
 begin
  Container:=New(PMacrosCollection, Init);
 end;

function TMacrosEngine.ContainerSize: Longint;
 begin
  ContainerSize:=Container^.Count;
 end;

function TMacrosEngine.ContainerAt(Index: Longint): PMacro;
 begin
  ContainerAt:=Container^.At(Index);
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

function MacrosEngine(ServiceNumber: Longint): Longint;
 var
  Macros: PMacrosEngine;
  MacroFunction: TMacroFunction;
  Macro: PMacro;
  S: String;
 begin
  Macros:=sGetPtrSemaphore('User.Macros');
  case ServiceNumber of
   snuCreateMacros:
    begin
     Macros:=New(PMacrosEngine, Init);
     MacrosEngine:=Longint(Macros);
    end;
   snuAddMacro:
    begin
     Macros^.AddMacro(sGetSemaphore('User.Macros.Id'), sGetSemaphore('User.Macros.Data'), mcUser);
    end;
   snuAddFunction:
    begin
     @MacroFunction:=sGetPtrSemaphore('User.Macros.Func');
     Macros^.AddFunction(sGetSemaphore('User.Macros.Id'), MacroFunction, mcUser);
    end;
   snuRemoveMacro:
    begin
     Macros^.RemoveMacro(sGetSemaphore('User.Macros.Id'));
    end;
   snuProcessMacro:
    begin
     S:=sGetSemaphore('User.Macros.String');
     S:=Macros^.Process(S);
     sSetSemaphore('User.Macros.String', S);
     if Macros^.EmptyLine then
      sSetSemaphore('User.Macros.EmptyLine', 'Yes')
     else
      sSetSemaphore('User.Macros.EmptyLine', 'No');
    end;
   snuDestroyMacros:
    begin
     Dispose(Macros, Done);
    end;
   snuGetMacrosInfo:
    begin
     Macro:=Macros^.GetMacro(sGetSemaphore('User.Macros.Id'));
     sSetSemaphore('User.Macros.Info.ID', GetPString(Macro^.ID));
     sSetSemaphore('User.Macros.Info.Data', GetPString(Macro^.Data));
     sSetSemaphore('User.Macros.Info.Class', Long2Str(Macro^.ClassID));
     sSetSemaphore('User.Macros.Info.IsFunc', Long2Str(Byte(Macro^.IsFunc)));
     sSetSemaphore('User.Macros.Info.Func', HexPtr(@Macro^.Func));
    end;
  end;
 end;

{*** Service handler ***}
function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint; {$IFNDEF SOLID}export;{$ENDIF}
 var
  S: String;
  D: String;
  K: Byte;
  F: File;
 begin
  Service:=srYes;
  case ServiceNumber of
   snStartup: Service:=srYes;
   snQueryName: sSetSemaphore('Kernel.Plugins.Info.Name', 'USER');
   snQueryAuthor: sSetSemaphore('Kernel.Plugins.Info.Author', 'sergey korowkin');
   snQueryVersion: Service:=userVersion;
   snQueryReqVer: Service:=kernelVersion;
   snuCheck: Service:=sruReadyToSir;
   snuGetCRC: Service:=GetCRC(sGetSemaphore('User.Filename'));

   {*** MACROS ENGINE ***}
   snuCreateMacros,
   snuAddMacro,
   snuAddFunction,
   snuRemoveMacro,
   snuProcessMacro,
   snuDestroyMacros,
   snuGetMacrosInfo: Service:=MacrosEngine(ServiceNumber);

   snuGetUnique:
    begin
     S:=sGetSemaphore('User.Unique');
     for K:=1 to Length(S) do
      case S[K] of
       '$': S[K]:=_DigitsChars[Random(Length(_DigitsChars)) + 1];
       '#': S[K]:=_Digits[Random(Length(_Digits)) + 1];
       '*': S[K]:=_DigitsHex[Random(Length(_DigitsHex)) + 1];
      end;
     sSetSemaphore('User.Unique', S);
    end;
   snuGetMSGiD: sSetSemaphore('User.MSGiD', GetMSGiD);
   snuInvalidateLine:
    begin
     S:=sGetSemaphore('User.InvLine');
     S:=InvalidateLine(S);
     sSetSemaphore('User.InvLine', S);
    end;
   snuChangeFilename: sSetSemaphore('User.FName',
    ChangeFilename(sGetSemaphore('User.FName'), sGetNumSemaphore('User.Counter'), sGetBoolSemaphore('User.83')));
   snuCheckBadFName: sSetSemaphore('User.FName', CheckBadFName(sGetSemaphore('User.FName')));
   snuLFNto83: { LFN -> 8.3 }
    begin
     S:=sGetSemaphore('User.83');

     FSplit(S, _Dir, _Name, _Ext);
     Delete(_Ext, 1, 1);

     CheckBadSym(_Name);
     CheckBadSym(_Ext);

     S:=Copy(_Name, 1, 8) + '.' + Copy(_Ext, 1, 3);

     sSetSemaphore('User.83', S);
    end;
   snu83echo: { any stuff to 8.3 :) }
    begin
     S:=sGetSemaphore('User.83');

     CheckBadSym(S);

     S:=Copy(S, 1, 8) + '.' + Copy(S, 9, 3);

     sSetSemaphore('User.83', S);
    end;
   snuCreateFlag:
    if sGetSemaphore('User.Flag') <> '' then
     begin
      {$I-}
      InOutRes:=0;
      Assign(F, sGetSemaphore('User.Flag'));
      ReWrite(F);
      if IOResult = 0 then
       begin
        lngBegin;
        lngPush(sGetSemaphore('User.Flag'));
        lngPrint('Main', 'common.flag.created');
        lngEnd;
       end;
      Close(F);
      InOutRes:=0;
     end;
   snuCleanupSubj: sSetSemaphore('User.Subj', CleanupSubj(sGetSemaphore('User.Subj')));
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
