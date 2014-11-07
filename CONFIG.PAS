unit Config;

interface
uses Types, Video, Semaphor, Log, Language, Consts_, Wizard;

const
 CacheHits: Longint = 0;
 CacheTotal: Longint = 0;
 CacheCount: Longint = 0;
 ReloadAnyway: Longint = 0;
 ReloadForce: Boolean = False;
 CompiledExtension = 'SK$';

var
 GeneralBlock: String;

type
 PBlock = ^TBlock;
 TBlock = object(TObject)
 public
  Name: PString;
  Data: PStrings;
  constructor Init(const AName: String);
  destructor Done; virtual;
 end;

 PBlocks = ^TBlocks;
 TBlocks = object(TCollection)
  function SearchBlock(Name: String): PBlock;
 end;

{ these functions called by kernel }
procedure cInit;
procedure cDone;
function  cLoad(const FName: String): Boolean;
function  cParse(const Block: String): Boolean;
function  cLoadConfiguration(FName, ConfigBlock: String): Boolean;
function  cStoreConfiguration(FName: String): Boolean;
function  cGetErrorString: String;
procedure cDump;
function  GetCompiledExtension(const S: String): String;

{ he-he. main exports.. }

function  cGetParam(const Key: String): String; {$IFNDEF SOLID}export;{$ENDIF}
function  cGetBoolParam(const Key: String): Boolean; {$IFNDEF SOLID}export;{$ENDIF}
function  cGetNumParam(const Key: String): Longint; {$IFNDEF SOLID}export;{$ENDIF}
procedure cProcessList(const Key: String; List: PStrings); {$IFNDEF SOLID}export;{$ENDIF}
procedure cProcessListEx(const Key: String; List: PStrings; Flags: Longint); {$IFNDEF SOLID}export;{$ENDIF}

function  cConfiguration: PStrings; {$IFNDEF SOLID}export;{$ENDIF}

function  iGetParam(C: PStrings; const Key: String): String; {$IFNDEF SOLID}export;{$ENDIF}
function  iGetBoolParam(C: PStrings; Key: String): Boolean; {$IFNDEF SOLID}export;{$ENDIF}
function  iGetNumParam(C: PStrings; Key: String): Longint; {$IFNDEF SOLID}export;{$ENDIF}
procedure iProcessList(C: PStrings; const Key: String; List: PStrings); {$IFNDEF SOLID}export;{$ENDIF}
procedure iProcessListEx(C: PStrings; const Key: String; List: PStrings; Flags: Longint); {$IFNDEF SOLID}export;{$ENDIF}

function  gGroups: PCollection; {$IFNDEF SOLID}export;{$ENDIF}

function  gGetParam(G: PStrings; const Key: String): String; {$IFNDEF SOLID}export;{$ENDIF}
function  gGetBoolParam(G: PStrings; const Key: String): Boolean; {$IFNDEF SOLID}export;{$ENDIF}
function  gGetNumParam(G: PStrings; const Key: String): Longint; {$IFNDEF SOLID}export;{$ENDIF}
procedure gProcessList(G: PStrings; const Key: String; List: PStrings); {$IFNDEF SOLID}export;{$ENDIF}
procedure gProcessListEx(G: PStrings; const Key: String; List: PStrings; Flags: Longint); {$IFNDEF SOLID}export;{$ENDIF}

function  gSearch(Name: String): PStrings; {$IFNDEF SOLID}export;{$ENDIF}
function  gSearchByArea(Area: String): PStrings; {$IFNDEF SOLID}export;{$ENDIF}

function  gGetDoubleParam(G: PStrings; const Key: String): String; {$IFNDEF SOLID}export;{$ENDIF}
function  gGetDoubleBoolParam(G: PStrings; const Key: String): Boolean; {$IFNDEF SOLID}export;{$ENDIF}
function  gGetDoubleNumParam(G: PStrings; const Key: String): Longint; {$IFNDEF SOLID}export;{$ENDIF}

function  bSearch(Name: String): PStrings; {$IFNDEF SOLID}export;{$ENDIF}

implementation
uses Misc, Dos;

{$I fastuue.inc}

type
 PUserMacro = ^TUserMacro;
 TUserMacro = object(TObject)
 public
  Name: PString;
  Data: PString;
  constructor Init(const AName, AData: String);
  destructor Done; virtual;
 end;

 PAreaCache = ^TAreaCache;
 TAreaCache = object(TObject)
 public
  Name: PString;
  Group: PStrings;
  constructor Init(const AName: String; AGroup: PStrings);
  destructor Done; virtual;
 end;

var
 cp_ErrorString: String;
 UserMacros: TCollection;
 HyperCache: String;
 HyperGroup: PStrings;
 Cache: TCollection;
 Blocks: TBlocks;
 Configuration: TStrings;
 Groups: TCollection;
 Founded: Boolean;
const
 cp_Error: Boolean = False;
 cp_Block: PBlock = Nil;
var
 cp_ID: String;
 cp_Macro: String;
 cp_Param: String;
const
 cp_Scrollers: Array[1..4] of Char = '|/-\';
 cp_Scroller: Byte = 0;

function ThisOS(var S: String): Boolean;
 begin
  if (Copy(S, 1, 4) = 'OS2.') or (Copy(S, 1, 4) = 'DOS.') or (Copy(S, 1, 4) = 'W32.') then
   begin
    ThisOS:=Copy(S, 1, 3) = OS_Short;
    Delete(S, 1, 4);
   end
  else
   ThisOS:=True;
 end;

function cGetErrorString;
 begin
  cGetErrorString:=cp_ErrorString;
 end;

constructor TUserMacro.Init(const AName, AData: String);
 var
  S: String;
 begin
  inherited Init;
  S:=AName;
  TrimEx(S);
  StUpcaseEx(S);
  Name:=NewStr(S);
  Data:=NewStr(AData);
 end;

destructor TUserMacro.Done;
 begin
  DisposeStr(Name);
  DisposeStr(Data);
  inherited Done;
 end;

constructor TAreaCache.Init(const AName: String; AGroup: PStrings);
 begin
  inherited Init;
  Name:=NewStr(AName);
  Group:=AGroup;
 end;

destructor TAreaCache.Done;
 begin
  DisposeStr(Name);
  inherited Done;
 end;

constructor TBlock.Init;
 begin
  Inherited Init;
  if AName = '' then
   Name:=NewStr('*NULL*')
  else
   Name:=NewStr(AName);
  Data:=New(PStrings, Init);
 end;

destructor TBlock.Done;
 begin
  DisposeStr(Name);
  Dispose(Data, Done);
  Inherited Done;
 end;

function TBlocks.SearchBlock;
 var
  K: Longint;
  B: PBlock;
 begin
  if Name = '' then
   begin
    SearchBlock:=Nil;
    Exit;
   end;
  TrimEx(Name);
  StUpcaseEx(Name);
  Name:='[' + Name + ']';
  for K:=1 to Count do
   begin
    B:=At(K);
    if B^.Name^ = Name then
     begin
      SearchBlock:=B;
      Exit;
     end;
   end;
  SearchBlock:=Nil;
 end;

procedure cInit;
 begin
  Blocks.Init;
  Configuration.Init;
  UserMacros.Init;
  Groups.Init;
  Cache.Init;
  cp_ErrorString:='';
  HyperCache:='';
  HyperGroup:=Nil;
 end;

const
 clFile: String = '';
 clLine: Longint = 0;
 clBlock: PBlock = Nil;
 clOk: Boolean = True;
 clLevel: Longint = 0;

procedure clError(const Message, S: String);
 begin
  vSetAttr($0F);
  vPrintLn('');
  vPrintLn(Concat('    ', clFile, '(', Long2Str(clLine), '): ', Message));

  vSetAttr($07);
  vPrintLn(Concat('    ', S));

  cp_ErrorString:='';

  clOk:=False;
 end;

function clParseFile(const FName: String): Boolean;
 var
  Line: Longint;
  F: Text;
  S, Su: String;
 begin
  clParseFile:=False;

  if IOResult <> 0 then;

  Inc(clLevel);

  if clLevel > 15 then
   begin
    cp_ErrorString:='Too many "include file"''s..';

    Exit;
   end;

  Line:=0;
  clOk:=True;
  clFile:=FName;

  Assign(F, FName);
  Reset(F);

  if InOutRes <> 0 then
   begin
    cp_ErrorString:='Unable to open "' + FName + '", rc=#' + Long2Str(IOResult);

    Exit;
   end;

  while not Eof(F) do
   begin
    if not clOk then
     Break;

    ReadLn(F, S);

    Inc(Line);

    clLine:=Line;

    S:=Ltrim(S);

    if (S[0] = #0) or (S[1] in [';', '/', '%']) then
     Continue;

    if S[1] = '[' then
     if S[Byte(S[0])] <> ']' then
      clError('Wrong declaration of block', S)
     else
      begin
       TrimEx(S);

       StUpcaseEx(S);

       if (S[0] < #3) then
        clError('Wrong declaration of block', S)
       else
        begin
         clBlock:=New(PBlock, Init(S));

         Blocks.Insert(clBlock);
        end;
      end
    else
     begin
      Su:=S;

      StUpcaseEx(Su);

      if (ExtractWord(1, Su, [' ']) = 'INCLUDE') and (ExtractWord(2, Su, [' ']) = 'FILE') then
       begin
        if not clParseFile(GetAllAfterSpace(S, 2)) then
         begin
          clOk:=False;

          Break;
         end;

        clFile:=FName;
       end
      else
       if clBlock = Nil then
        clError('Line before first block', S)
       else
        clBlock^.Data^.Insert(NewStr(S));
     end;
   end;

  Close(F);

  Dec(clLevel);

  clParseFile:=clOk;
 end;

function cLoad(const FName: String): Boolean;
 begin
  if not clParseFile(FName) then
   begin
    cLoad:=False;

    if cp_ErrorString = '' then
     cp_ErrorString:='Errors in configuration file(s)';
   end
  else
   cLoad:=True;
 end;

procedure cDone;
 var
  K: Longint;
  C: PAreaCache;
 begin
  Cache.Done;
  UserMacros.Done;
  Configuration.Done;
  Blocks.Done;
  Groups.Done;
 end;

procedure cp_CheckBlock(Block: PBlock); far;
 var
  K: Longint;
  L: Longint;
  S: String;
  F: Text;
  XBlock: PBlock;
 begin
  K:=0;
  repeat
   mCheckBreak;

   if sExitNow then
    begin
     cp_ErrorString:='Cancelled by user.';
     cp_Error:=True;

     Break;
    end;

   Inc(K);

   if K > Block^.Data^.Count then Break;

   GetPStringEx(Block^.Data^.At(K), S);

   TrimEx(S);

   StUpcaseEx(S);

   if (ExtractWord(1, S, [' ']) = 'INCLUDE') then
    if (ExtractWord(2, S, [' ']) = 'BLOCK') then
     begin
      Inc(cp_Scroller);
      if cp_Scroller > 4 then cp_Scroller:=1;

      vSetAttr($0A);
      vPrint(cp_Scrollers[cp_Scroller] + #8);

      S:=ExtractWord(3, S, [' ']);

      XBlock:=Blocks.SearchBlock(OS_Short + '.' + S);

      if XBlock = Nil then
       XBlock:=Blocks.SearchBlock(S);

      if XBlock = Nil then
       begin
        cp_ErrorString:='Block "' + S + '" is not found.';
        cp_Error:=True;
        Exit;
       end;

      Block^.Data^.AtFree(K);

      for L:=1 to XBlock^.Data^.Count do
       Block^.Data^.AtInsert(K + L - 1, NewStr(GetPString(XBlock^.Data^.At(L))));

      Dec(K);
      if K < 1 then
       K:=1;
     end else
     begin
      cp_Error:=True;
      cp_ErrorString:='Wrong include command.';

      Break;
     end;
  until False;
 end;

procedure cp_MakeConfiguration;
 var
  K: Longint;
  S: String;
 begin
  for K:=1 to cp_Block^.Data^.Count do
   begin
    GetPStringEx(cp_Block^.Data^.At(K), S);

    if Trim(S) = '' then
     Continue;

    Configuration.Insert(NewStr(S));
   end;
 end;

procedure cp_CheckUserMacro(D: PString);
 var
  S: String;
 begin
  S:=Ltrim(D^);

  if (S[0] = #0) or (S[1] <> '#') then
   Exit;

  Delete(S, 1, 1);

  cp_ID:=ExtractWord(1, S, [' ']);

  StUpcaseEx(cp_ID);

  cp_Macro:=ExtractWord(2, S, [' ']);

  cp_Param:=GetAllAfterSpace(S, 2);

  if not ThisOS(cp_ID) then
   Exit;

  if cp_ID = 'DEFINE' then
   UserMacros.Insert(New(PUserMacro, Init(cp_Macro, cp_Param)))
  else
   begin
    cp_Error:=True;
    cp_ErrorString:='Unknown macrocommand "' + cp_ID + '".';
   end;
 end;

procedure cp_CheckGroup(Group: PStrings);
 var
  K: Longint;
  L: Longint;
  XGroup: PStrings;
 begin
  K:=0;
  repeat
   Inc(K);
   if K > Group^.Count then Break;
   cp_ID:=StUpcase(Trim(PString(Group^.At(K))^));
   if ExtractWord(1, cp_ID, [' ']) = 'INHERITE' then
    begin
     Dec(cp_Scroller);
     if cp_Scroller < 1 then cp_Scroller:=4;
     vSetAttr($0A);
     vPrint(cp_Scrollers[cp_Scroller] + #8);
     XGroup:=gSearch(GetAllAfterSpace(cp_ID, 1));
     if XGroup = Nil then
      begin
       cp_Error:=True;
       cp_ErrorString:='Group "'+GetAllAfterSpace(cp_ID, 1)+'" cannot be found.';
       Break;
      end;
     Group^.AtFree(K);
     for L:=1 to XGroup^.Count do
      Group^.AtInsert(K + L - 1, NewStr(GetPString(XGroup^.At(L))));
     Dec(K);
     if K < 1 then K:=1;
    end;
  until False;
 end;

procedure cp_ParseGroups;
 var
  Groups: PBlock;
  Group: PStrings;
  Phase: Longint;
  K: Longint;
 begin
  if cGetParam('GROUPS') = '' then Exit;
  Groups:=Blocks.SearchBlock(cGetParam('GROUPS'));
  if Groups = Nil then
   begin
    cp_Error:=True;
    cp_ErrorString:='Block "'+cGetParam('GROUPS')+'" cannot be found.';
    Exit;
   end;
  K:=0;
  Phase:=0;
  repeat
   Inc(K);
   if K > Groups^.Data^.Count then Break;
   cp_ID:=GetPString(Groups^.Data^.At(K));
   { check for 'BEGIN' }
   if StUpcase(ExtractWord(1, cp_ID, [' '])) = 'BEGIN' then
    if Phase <> 0 then
     begin
      cp_Error:=True;
      cp_ErrorString:='"BEGIN" without "END".';
      Break;
     end
    else
     begin
      Phase:=1;
      Group:=New(PStrings, Init);
      Config.Groups.Insert(Group);
      Continue;
     end;
   { check for 'END' }
   if StUpcase(ExtractWord(1, cp_ID, [' '])) = 'END' then
    if Phase = 0 then
     begin
      cp_Error:=True;
      cp_ErrorString:='"END" without "BEGIN".';
      Break;
     end
    else
     begin
      Phase:=0;
      Continue;
     end;
   if Phase = 0 then
    begin
     cp_Error:=True;
     cp_ErrorString:='Data line before "BEGIN".';
     Break;
    end;
   Group^.Insert(NewStr(cp_ID));
  until False;
  for K:=1 to Config.Groups.Count do
   if not cp_Error then cp_CheckGroup(Config.Groups.At(K));
 end;

function cParse(const Block: String): Boolean;
 var
  K: Longint;
 begin
  cp_Block:=Blocks.SearchBlock(Block+'.'+OS_Short);

  if cp_Block = Nil then
   cp_Block:=Blocks.SearchBlock(Block);

  if cp_Block = Nil then
   begin
    cParse:=False;
    cp_ErrorString:='Block "'+Block+'" cannot be found.';
    Exit;
   end;

  { process "include block"'s }
  for K:=1 to Blocks.Count do
   if not cp_Error then cp_CheckBlock(Blocks.At(K));

  { make cConfiguration pool }
  if not cp_Error then cp_MakeConfiguration;

  { get UserMacros from cConfiguration pool }
  for K:=1 to cConfiguration^.Count do
   if not cp_Error then cp_CheckUserMacro(cConfiguration^.At(K));

  { parse groups }
  cp_ParseGroups;

  { done }
  cParse:=not cp_Error;
 end;

function cConfiguration: PStrings;
 begin
  cConfiguration:=@Configuration;
 end;

procedure UserCheck(var S: String);
 var
  Macro: PUserMacro;
  K: Longint;
 begin
  for K:=1 to UserMacros.Count do
   begin
    Macro:=UserMacros.At(K);
    ReplaceEx(S, GetPString(Macro^.Name), GetPString(Macro^.Data));
   end;
 end;

procedure _iProcessList(C: PStrings; Key: String; List: PStrings);
 var
  S, Cmd: String;
  F: Text;
 procedure CheckList(_S: PString); far;
  begin
   S:=Ltrim(GetPString(_S));
   if Replace(Trim(StUpcase(ExtractWord(1,S,[' ']))),'_','.')=Key then
    begin
     S:=GetAllAfterSpace(S,1);
     Cmd:=Trim(StUpcase(ExtractWord(1,S,[' '])));
     S:=GetAllAfterSpace(S,1);
     Founded:=True;
     if (Cmd='FILE') or (Cmd='REPLACEFILE') then
      begin
       if Cmd='REPLACEFILE' then
        List^.FreeAll;
       S:=Trim(S);
       UserCheck(S);
       {$I-} InOutRes:=0;
       Assign(F, S);
       Reset(F);
       if IOResult=0 then
        begin
         while not Eof(F) do
          begin
           ReadLn(F, S);
           List^.Insert(NewStr(S));
          end;
         Close(F);
         InOutRes:=0;
        end
       else
        begin
         lngBegin;
         lngPush(S);
         lngPrint('Main', 'config.file');
         lngEnd;
        end;
      end else
     if Cmd='KILL' then List^.FreeAll else
     if Cmd='REPLACE' then
      begin
       List^.FreeAll;
       UserCheck(S);
       List^.Insert(NewStr(S));
      end else
     if Cmd='ADD' then
      begin
       UserCheck(S);
       List^.Insert(NewStr(S));
      end;
    end;
  end;
 var
  K: Longint;
 begin
  Founded:=False;
  Key:=StUpcase(Trim(Key));
  for K:=1 to C^.Count do
   CheckList(C^.At(K));
 end;

procedure iProcessList(C: PStrings; const Key: String; List: PStrings);
 begin
  _iProcessList(C, OS_Short + '.' + Key, List);
  if not Founded then
   _iProcessList(C, Key, List);
 end;

procedure iProcessListEx(C: PStrings; const Key: String; List: PStrings; Flags: Longint);
 var
  K: Longint;
  S: PString;
 begin
  _iProcessList(C, OS_Short + '.' + Key, List);
  if not Founded then
   _iProcessList(C, Key, List);
  for K:=1 to C^.Count do
   begin
    S:=C^.At(K);
    if S = Nil then Continue;
    if Flags and cplUpCase <> 0 then StUpcaseEx(S^);
    if Flags and cplLoCase <> 0 then StLocaseEx(S^);
   end;
 end;

function _iGetParam(C: PStrings; Key: String): String;
 var
  S: String;
 procedure CheckList(_S: PString); far;
  begin
   S:=Ltrim(GetPString(_S));
   if Replace(Trim(StUpcase(ExtractWord(1,S,[' ']))),'_','.')=Key then
    begin
     S:=GetAllAfterSpace(S,1);
     UserCheck(S);
     _iGetParam:=S;
     Founded:=True;
    end;
  end;
 var
  K: Longint;
 begin
  Key:=StUpcase(Trim(Key));
  Founded:=False;
  _iGetParam:='';
  for K:=C^.Count downto 1 do
   if not Founded then CheckList(C^.At(K));
 end;

function iGetParam(C: PStrings; const Key: String): String;
 begin
  iGetParam:=_iGetParam(C, OS_Short+'.'+Key);
  if not Founded then
   iGetParam:=_iGetParam(C, Key);
 end;

function iGetBoolParam(C: PStrings; Key: String): Boolean;
 begin
  Key:=Trim(StUpcase(iGetParam(C, Key)));
  iGetBoolParam:=(Key[0]<>#0) and (Key[1] in ['1','Y','T']);
 end;

function iGetNumParam(C: PStrings; Key: String): Longint;
 var
  A: Longint;
 begin
  Key:=Trim(StUpcase(iGetParam(C, Key)));
  Str2Longint(Key, A);
  iGetNumParam:=A;
 end;

procedure cProcessList(const Key: String; List: PStrings);
 begin
  iProcessList(cConfiguration, Key, List);
 end;

procedure cProcessListEx(const Key: String; List: PStrings; Flags: Longint);
 begin
  iProcessListEx(cConfiguration, Key, List, Flags);
 end;

function cGetParam(const Key: String): String;
 begin
  cGetParam:=iGetParam(cConfiguration, Key);
 end;

function cGetBoolParam(const Key: String): Boolean;
 begin
  cGetBoolParam:=iGetBoolParam(cConfiguration, Key);
 end;

function cGetNumParam(const Key: String): Longint;
 begin
  cGetNumParam:=iGetNumParam(cConfiguration, Key);
 end;

function gGroups: PCollection;
 begin
  gGroups:=@Groups;
 end;

function gSearch(Name: String): PStrings;
 procedure TryGroup(G: PStrings); far;
  begin
   if Trim(StUpcase(gGetParam(G,'Name')))=Name then gSearch:=G;
  end;
 var
  K: Longint;
 begin
  Name:=Trim(StUpcase(Name));
  gSearch:=Nil;
  for K:=1 to Groups.Count do TryGroup(Groups.At(K));
 end;

procedure gProcessList;
 begin
  iProcessList(G, Key, List);
 end;

procedure gProcessListEx;
 begin
  iProcessListEx(G, Key, List, Flags);
 end;

function gGetParam;
 begin
  gGetParam:=iGetParam(G, Key);
 end;

function gGetBoolParam;
 begin
  gGetBoolParam:=iGetBoolParam(G, Key);
 end;

function gGetNumParam;
 begin
  gGetNumParam:=iGetNumParam(G, Key);
 end;

function gSearchByArea;
 var
  Areas, AreasExclude: PStrings;
 function CheckGroup(G: PStrings): boolean;
  var
   K, L: Longint;
   S: String;
  begin
   CheckGroup:=False;
   Areas^.FreeAll;
   AreasExclude^.FreeAll;
   gProcessList(G, 'Areas', Areas);
   gProcessList(G, 'Areas.Exclude', AreasExclude);
   for K:=1 to Areas^.Count do
    begin
     if not mCheckWildCard(Area, Trim(StUpcase(GetPString(Areas^.At(K))))) then Continue;
     for L:=1 to AreasExclude^.Count do
      if mCheckWildCard(Area, Trim(StUpcase(GetPString(AreasExclude^.At(L))))) then
       Exit;
     Cache.Insert(New(PAreaCache, Init(Area, G)));
     Inc(CacheCount);
     HyperCache:=Area;
     HyperGroup:=G;
     gSearchByArea:=G;
     CheckGroup:=True;
     Exit;
    end;
  end;
 var
  K: Longint;
 begin
  Inc(CacheTotal);
  Area:=Trim(StUpcase(Area));
  if Area = HyperCache then
   begin
    Inc(CacheHits);
    gSearchByArea:=HyperGroup;
    Exit;
   end;
  if Area = '' then Exit;
  for K:=1 to Cache.Count do
   if PAreaCache(Cache.At(K))^.Name^ = Area then
    begin
     Inc(CacheHits);
     HyperCache:=Area;
     HyperGroup:=PAreaCache(Cache.At(K))^.Group;
     gSearchByArea:=HyperGroup;
     Exit;
    end;
  Areas:=New(PStrings, Init);
  AreasExclude:=New(PStrings, Init);
  gSearchByArea:=Nil;
  for K:=1 to gGroups^.Count do
   if CheckGroup(gGroups^.At(K)) then Break;
  Dispose(Areas, Done);
  Dispose(AreasExclude, Done);
 end;

{function gSearchByArea;
 var
  K, L, M: Longint;
  S: String;
  Areas: PStrings;
 begin
  gSearchByArea:=Nil;
  Area:=Trim(StUpcase(Area));
  Areas:=New(PStrings, Init);
  for K:=1 to gGroups^.Count do
   begin
    gProcessList(gGroups^.At(K), 'Areas', Areas);
    for L:=1 to Areas^.Count do
     begin
      S:=Trim(StUpcase(GetPString(Areas^.At(L))));
      if mCheckWildCard(Area, S) then
       begin
        gSearchByArea:=gGroups^.At(K);
        Dispose(Areas, Done);
        Exit;
       end;
     end;
    Areas^.FreeAll;
   end;
  Dispose(Areas, Done);
 end;}

procedure cDump;
 procedure Write(S: String);
  begin
   logWrite('Main',S);
  end;
 procedure DumpStrings(S: PStrings; Name: String);
  var
   K: Longint;
  begin
   Write('** DUMP of '+Name);
   for K:=1 to S^.Count do
    Write('  '+GetPString(S^.At(K)));
  end;
 var
  K: Longint;
  B: PBlock;
  M: PUserMacro;
  G: PStrings;
 begin
  Write('');
  Write('*** START OF LOADED CONFIG''s DUMP');
  Write('** DUMP of USERMACROS');
  for K:=1 to UserMacros.Count do
   begin
    M:=UserMacros.At(K);
    Write('  "'+GetPString(M^.Name)+'":'+GetPString(M^.Data));
   end;
  DumpStrings(@Configuration, 'CONFIGURATION');
  for K:=1 to Blocks.Count do
   begin
    B:=Blocks.At(K);
    DumpStrings(B^.Data, 'BLOCK '+GetPString(B^.Name));
   end;
  for K:=1 to Groups.Count do
   begin
    G:=Groups.At(K);
    DumpStrings(G, 'GROUP '+gGetParam(G,'Name'));
   end;
  Write('*** END OF LOADED CONFIG''s DUMP');
  Write('');
 end;

function bSearch(Name: String): PStrings;
 var
  B: PBlock;
 begin
  B:=Blocks.SearchBlock(Name);
  if B=Nil then
   bSearch:=Nil
  else
   bSearch:=B^.Data;
 end;

{ *** STORE CONFIGURATION *** }

procedure sc_Language(var S: TStream);
 var
  K: Longint;
  I: PLangItem;
 begin
  S.Write(LanguagePool^.Count, SizeOf(LanguagePool^.Count));
  for K:=1 to LanguagePool^.Count do
   begin
    I:=LanguagePool^.At(K);
    S.WriteStr(GetPString(I^.Name));
    S.WriteStr(GetPString(I^.Value));
   end;
 end;

procedure sc_UserMacros(var S: TStream);
 var
  K: Longint;
  I: PUserMacro;
 begin
  S.Write(UserMacros.Count, SizeOf(UserMacros.Count));
  for K:=1 to UserMacros.Count do
   begin
    I:=UserMacros.At(K);
    S.WriteStr(GetPString(I^.Name));
    S.WriteStr(GetPString(I^.Data));
   end;
 end;

procedure sc_Strings(var S: TStream; D: PStrings);
 var
  K: Longint;
 begin
  S.Write(D^.Count, SizeOf(D^.Count));
  for K:=1 to D^.Count do
   S.WriteStr(GetPString(D^.At(K)));
 end;

procedure sc_Blocks(var S: TStream);
 var
  K: Longint;
  I: PBlock;
 begin
  S.Write(Blocks.Count, SizeOf(Blocks.Count));
  for K:=1 to Blocks.Count do
   begin
    I:=Blocks.At(K);
    S.WriteStr(GetPString(I^.Name));
    sc_Strings(S, I^.Data);
   end;
 end;

procedure sc_Groups(var S: TStream);
 var
  K: Longint;
 begin
  S.Write(Groups.Count, SizeOf(Groups.Count));
  for K:=1 to Groups.Count do
   sc_Strings(S, Groups.At(K));
 end;

procedure sc_Cache(var S: TStream);
 var
  K: Longint;
  L: Longint;
  A: PAreaCache;
 begin
  S.Write(CacheHits, SizeOf(CacheHits));
  S.Write(CacheTotal, SizeOf(CacheTotal));
  S.Write(CacheCount, SizeOf(CacheCount));
  S.Write(Cache.Count, SizeOf(Cache.Count));
  for K:=1 to Cache.Count do
   begin
    A:=Cache.At(K);
    S.WriteStr(GetPString(A^.Name));
    L:=Groups.IndexOf(A^.Group);
    S.Write(L, SizeOf(L));
   end;
 end;

function cStoreConfiguration;
 var
  S: TBufStream;
  K: Longint;
 begin
  if cGetBoolParam('Debug.Disable.Config.Store') then Exit;
  cStoreConfiguration:=False;
  FName:=Trim(StUpcase(FName));
  if GetCompiledExtension(FName) = FName then
   begin
    cp_ErrorString:='wrong extension of '+FName;
    Exit;
   end;
  S.Init(GetCompiledExtension(FName), stCreate, 2048);
  if S.Status <> stOk then
   begin
    cp_ErrorString:='cannot create '+GetCompiledExtension(FName)+' -- rc#'+Long2Str(S.Status);
    S.Done;
    Exit;
   end;
  K:=kernelVersion;
  S.Write(K, SizeOf(K));
  K:=OS_ID;
  S.Write(K, SizeOf(K));
  K:=ReloadAnyway;
  S.Write(K, SizeOf(K));
  S.WriteStr(GeneralBlock);
  lngPrint('Main', 'store.dot');
  sc_Language(S);
  lngPrint('Main', 'store.dot');
  sc_UserMacros(S);
  lngPrint('Main', 'store.dot');
  sc_Blocks(S);
  lngPrint('Main', 'store.dot');
  sc_Strings(S, @Configuration);
  lngPrint('Main', 'store.dot');
  sc_Groups(S);
  lngPrint('Main', 'store.dot');
  sc_Cache(S);
  lngPrint('Main', 'store.dot');
  cStoreConfiguration:=True;
  cp_ErrorString:=Long2StrFmt(S.GetSize);
  S.Done;
  SetStamp(GetCompiledExtension(FName), GetStamp(FName));
 end;

{ *** LOAD CONFIGURATION *** }

var
 L: Longint;
 S1: String;
 S2: String;

procedure lc_Language(var S: TStream);
 var
  K: Longint;
  I: PLangItem;
 begin
  LanguagePool^.FreeAll;
  S.Read(L, SizeOf(L));
  for K:=1 to L do
   begin
    S1:=S.ReadStr;
    S2:=S.ReadStr;
    I:=New(PLangItem, Init(S1, S2));
    LanguagePool^.Insert(I);
   end;
 end;

procedure lc_UserMacros(var S: TStream);
 var
  K: Longint;
  I: PUserMacro;
 begin
  UserMacros.FreeAll;
  S.Read(L, SizeOf(L));
  for K:=1 to L do
   begin
    S1:=S.ReadStr;
    S2:=S.ReadStr;
    I:=New(PUserMacro, Init(S1, S2));
    UserMacros.Insert(I);
   end;
 end;

procedure lc_Strings(var S: TStream; D: PStrings);
 var
  K: Longint;
 begin
  S.Read(L, SizeOf(L));
  for K:=1 to L do
   D^.Insert(NewStr(S.ReadStr));
 end;

procedure lc_Blocks(var S: TStream);
 var
  K: Longint;
  I: PBlock;
 begin
  Blocks.FreeAll;
  S.Read(L, SizeOf(L));
  for K:=1 to L do
   begin
    I:=New(PBlock, Init(S.ReadStr));
    lc_Strings(S, I^.Data);
    Blocks.Insert(I);
   end;
 end;

procedure lc_Groups(var S: TStream);
 var
  K: Longint;
  D: PStrings;
 begin
  Groups.FreeAll;
  S.Read(L, SizeOf(L));
  for K:=1 to L do
   begin
    D:=New(PStrings, Init);
    lc_Strings(S, D);
    Groups.Insert(D);
   end;
 end;

procedure lc_Cache(var S: TStream);
 var
  K: Longint;
  J: Longint;
  I: PAreaCache;
 begin
  S.Read(CacheHits, SizeOf(CacheHits));
  S.Read(CacheTotal, SizeOf(CacheTotal));
  S.Read(CacheCount, SizeOf(CacheCount));
  CacheHits:=0;
  CacheTotal:=0;
  S.Read(L, SizeOf(L));
  for K:=1 to L do
   begin
    I:=New(PAreaCache, Init(S.ReadStr, nil));
    S.Read(J, SizeOf(J));
    I^.Group:=Groups.At(J);
    Cache.Insert(I);
   end;
 end;

function cLoadConfiguration;
 var
  S: TBufStream;
  K: Longint;
  L: Longint;
 begin
  if ReloadForce then
   begin
    cp_ErrorString:='forced by commandline switch /RELOADCFG';
    cLoadConfiguration:=False;
    Exit;
   end;
  FName:=Trim(StUpcase(FName));
  if GetCompiledExtension(FName) = FName then
   begin
    cp_ErrorString:='wrong extension of '+FName;
    cLoadConfiguration:=False;
    Exit;
   end;
  L:=GetStamp(GetCompiledExtension(FName));
  S.Init(GetCompiledExtension(FName), stOpenRead, 2048);
  if S.Status <> stOk then
   begin
    cp_ErrorString:='cannot open '+GetCompiledExtension(FName)+' -- rc#'+Long2Str(S.Status);
    S.Done;
    cLoadConfiguration:=False;
    Exit;
   end;
  if GetStamp(FName) <> L then
   begin
    cp_ErrorString:='timestamp changed (orig. '+HexL(GetStamp(FName))+'h, comp. '+HexL(L)+'h)';
    cLoadConfiguration:=False;
    S.Done;
    Exit;
   end;
  S.Read(K, SizeOf(K));
  if K <> kernelVersion then
   begin
    cp_ErrorString:='configuration file from different version';
    cLoadConfiguration:=False;
    S.Done;
    Exit;
   end;
  S.Read(K, SizeOf(K));
  if K <> OS_ID then
   begin
    cp_ErrorString:='configuration file from different operating system';
    cLoadConfiguration:=False;
    S.Done;
    Exit;
   end;
  S.Read(K, SizeOf(K));
  if K <> 0 then
   begin
    cp_ErrorString:='RELOAD_ANYWAY flag detected';
    cLoadConfiguration:=False;
    S.Done;
    Exit;
   end;
  GeneralBlock:=S.ReadStr;
  if GeneralBlock <> ConfigBlock then
   begin
    cp_ErrorString:='starting with different blocks (' + ConfigBlock + ' vs ' + GeneralBlock + ')';
    cLoadConfiguration:=False;
    S.Done;
    Exit;
   end;
  vPrint('.');
  lc_Language(S);
  vPrint('.');
  lc_UserMacros(S);
  vPrint('.');
  lc_Blocks(S);
  vPrint('.');
  lc_Strings(S, @Configuration);
  vPrint('.');
  lc_Groups(S);
  vPrint('.');
  lc_Cache(S);
  vPrint('.');
  cp_ErrorString:=Long2StrFmt(S.GetSize);
  cLoadConfiguration:=True;
  S.Done;
 end;

function GetCompiledExtension(const S: String): String;
 begin
  GetCompiledExtension:=ForceExtension(S, CompiledExtension);
 end;

function gGetDoubleBoolParam(G: PStrings; const Key: String): Boolean;
 begin
  if gGetParam(G, Key) <> '' then
   gGetDoubleBoolParam:=gGetBoolParam(G, Key)
  else
   gGetDoubleBoolParam:=cGetBoolParam(Key)
 end;

function gGetDoubleParam(G: PStrings; const Key: String): String;
 begin
  if gGetParam(G, Key) <> '' then
   gGetDoubleParam:=gGetParam(G, Key)
  else
   gGetDoubleParam:=cGetParam(Key)
 end;

function gGetDoubleNumParam(G: PStrings; const Key: String): Longint;
 begin
  if gGetParam(G, Key) <> '' then
   gGetDoubleNumParam:=gGetNumParam(G, Key)
  else
   gGetDoubleNumParam:=cGetNumParam(Key)
 end;

begin
 Founded:=False
end.
