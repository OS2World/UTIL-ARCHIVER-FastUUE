library FUUErexx;

uses
      Wizard,
      Types, Consts_,

      //
      Video,
      Config,
      Semaphor,
      Log,
      Language,
      Plugins,
      Misc,
      //

      Rexx, Hooks, Strings;

{$DYNAMIC MAIN.LIB}

{$LINKER
  DESCRIPTION      "FastUUE(tm) REXX SUPPORT .DLL"
  DATA MULTIPLE NONSHARED

  EXPORTS
    VPRINT = vPrint
    VPRINTLN = vPrintLn
    VCLREOL = vClrEol
    VGETATTR = vGetAttr
    VSETATTR = vSetAttr
    KKEYPRESSED = kKeyPressed
    KREADKEY = kReadKey

    CGETPARAM = cGetParam
    CGETBOOLPARAM = cGetBoolParam
    CGETNUMPARAM = cGetNumParam
    CPROCESSLIST = cProcessList
    CPROCESSLISTEX = cProcessListEx
    CCONFIGURATION = cConfiguration
    IGETPARAM = iGetParam
    IGETBOOLPARAM = iGetBoolParam
    IGETNUMPARAM = iGetNumParam
    IPROCESSLIST = iProcessList
    IPROCESSLISTEX = iProcessListEx
    GGROUPS = gGroups
    GGETPARAM = gGetParam
    GGETBOOLPARAM = gGetBoolParam
    GGETNUMPARAM = gGetNumParam
    GPROCESSLIST = gProcessList
    GPROCESSLISTEX = gProcessListEx
    GSEARCH = gSearch
    GSEARCHBYAREA = gSearchByArea
    GGETDOUBLEPARAM = gGetDoubleParam
    GGETDOUBLEBOOLPARAM = gGetDoubleBoolParam
    GGETDOUBLENUMPARAM = gGetDoubleNumParam
    BSEARCH = bSearch

    SSETSEMAPHORE = sSetSemaphore
    SGETSEMAPHORE = sGetSemaphore
    SGETBOOLSEMAPHORE = sGetBoolSemaphore
    SGETNUMSEMAPHORE = sGetNumSemaphore
    SGETPTRSEMAPHORE = sGetPtrSemaphore
    SEXITNOW = sExitNow
    SSETEXITNOW = sSetExitNow

    LOGCREATE = logCreate
    LOGWRITE = logWrite
    LOGKILL = logKill

    LNGPRINT = lngPrint
    LNGGET = lngGet

    PGET = pGet
    PSEARCH = pSearch
    SRVBROADCAST = srvBroadcast
    SRVEXECUTE = srvExecute
    SRVEXECUTEDIRECT = srvExecuteDirect

    MCREATE = mCreate
    MHASCREATED = mHasCreated
    MCHECKBREAK = mCheckBreak
    MCHECKWILDCARD = mCheckWildcard
    MEXEC = mExec
    MCLEANDIR = mCleanDir
    MCHECKPLUGIN = mCheckPlugin
    MSETTITLE = mSetTitle
}

const
 frVersion = $01000000;

 Functions: Array[1..47] of PChar = (
  // video
  'vPrint',
  'vPrintLn',
  'vClrEol',
  'vGetAttr',
  'vSetAttr',
  'kKeyPressed',
  'kReadKey',
  // config
  'cGetParam',
  'cGetBoolParam',
  'cGetNumParam',
  'cProcessList',
  'cProcessListEx',
  'cConfiguration',
  'iGetParam',
  'iGetBoolParam',
  'iGetNumParam',
  'iProcessList',
  'iProcessListEx',
  'gGroups',
  'gGetParam',
  'gGetBoolParam',
  'gGetNumParam',
  'gProcessList',
  'gProcessListEx',
  'gSearch',
  'gSearchByArea',
  'gGetDoubleParam',
  'gGetDoubleBoolParam',
  'gGetDoubleNumParam',
  'bSearch',
  // semaphor
  'sSetSemaphore',
  'sGetSemaphore',
  'sGetBoolSemaphore',
  'sGetNumSemaphore',
  'sGetPtrSemaphore',
  'sExitNow',
  'sSetExitNow',
  // log
  'logCreate',
  'logWrite',
  'logKill',
  // language
  'lngPrint',
  'lngGet',
  // plugins
  'pGet',
  'pSearch',
  'srvBroadcast',
  'srvExecute',
  'srvExecuteDirect'
  // misc
 );

{$OrgName+,StdCall+}

function CheckArgC(const ArgC: ULong; var R: Longint; const Min: Longint): Boolean;
 begin
  Result:=ArgC >= Min;

  if Result then
   R:=0
  else
   R:=-1;
 end;

/////////////////////////////////////////////////////////////////////////////
// Video
/////////////////////////////////////////////////////////////////////////////

function vPrint(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 var
  S: String;
 begin
  Result:=0;

  while ArgC <> 0 do
   begin
    S:=RxToString(Args^);

    Video.vPrint(S);

    Dec(ArgC);
    Inc(Args);
   end;
 end;

function vPrintLn(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 var
  S: String;
 begin
  Result:=0;

  while ArgC > 0 do
   begin
    S:=RxToString(Args^);

    Video.vPrintLn(S);

    Dec(ArgC);
    Inc(Args);
   end;
 end;

function vClrEol(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 begin
  Result:=0;

  video.vClrEol;
 end;

function vGetAttr(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 begin
  Result:=0;

  LongintToRx(video.vGetAttr, Ret);
 end;

function vSetAttr(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 var
  L: Longint;
 begin
  if CheckArgC(ArgC, Result, 1) then
   begin
    L:=RxToLongint(Args^);

    Video.vSetAttr(L);
   end;
 end;

function kKeyPressed(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 begin
  Result:=0;

  BooleanToRx(Video.kKeyPressed, Ret);
 end;

function kReadKey(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 begin
  Result:=0;

  StringToRx(Video.kReadKey, Ret);
 end;

/////////////////////////////////////////////////////////////////////////////
// Config
/////////////////////////////////////////////////////////////////////////////

// c**

function cGetParam(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 begin
  if CheckArgC(ArgC, Result, 1) then
   StringToRx(Config.cGetParam(RxToString(Args^)), Ret);
 end;

function cGetBoolParam(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 begin
  if CheckArgC(ArgC, Result, 1) then
   BooleanToRx(Config.cGetBoolParam(RxToString(Args^)), Ret);
 end;

function cGetNumParam(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 begin
  if CheckArgC(ArgC, Result, 1) then
   LongintToRx(Config.cGetNumParam(RxToString(Args^)), Ret);
 end;

function cProcessList(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 var
  Key: String;
  List: PStrings;
 begin
  if CheckArgC(ArgC, Result, 2) then
   begin
    Key:=RxToString(Args^);

    Inc(Args);

    List:=RxToPointer(Args^);

    Config.cProcessList(Key, List);
   end;
 end;

function cProcessListEx(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 var
  Key: String;
  List: PStrings;
  Flags: Longint;
 begin
  if CheckArgC(ArgC, Result, 3) then
   begin
    Key:=RxToString(Args^);

    Inc(Args);

    List:=RxToPointer(Args^);

    Inc(Args);

    Flags:=RxToLongint(Args^);

    Config.cProcessListEx(Key, List, Flags);
   end;
 end;

function cConfiguration(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 begin
  Result:=0;

  PointerToRx(Config.cConfiguration, Ret);
 end;

// i**

function iGetParam(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 var
  Block: PStrings;
 begin
  if CheckArgC(ArgC, Result, 2) then
   begin
    Block:=RxToPointer(Args^);

    Inc(Args);

    StringToRx(Config.iGetParam(Block, RxToString(Args^)), Ret);
   end;
 end;

function iGetBoolParam(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 var
  Block: PStrings;
 begin
  if CheckArgC(ArgC, Result, 2) then
   begin
    Block:=RxToPointer(Args^);

    Inc(Args);

    BooleanToRx(Config.iGetBoolParam(Block, RxToString(Args^)), Ret);
   end;
 end;

function iGetNumParam(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 var
  Block: PStrings;
 begin
  if CheckArgC(ArgC, Result, 2) then
   begin
    Block:=RxToPointer(Args^);

    Inc(Args);

    LongintToRx(Config.iGetNumParam(Block, RxToString(Args^)), Ret);
   end;
 end;

function iProcessList(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 var
  Key: String;
  Block, List: PStrings;
 begin
  if CheckArgC(ArgC, Result, 2) then
   begin
    Block:=RxToPointer(Args^);

    Inc(Args);

    Key:=RxToString(Args^);

    Inc(Args);

    List:=RxToPointer(Args^);

    Config.iProcessList(Block, Key, List);
   end;
 end;

function iProcessListEx(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 var
  Key: String;
  Block, List: PStrings;
  Flags: Longint;
 begin
  if CheckArgC(ArgC, Result, 3) then
   begin
    Block:=RxToPointer(Args^);

    Inc(Args);

    Key:=RxToString(Args^);

    Inc(Args);

    List:=RxToPointer(Args^);

    Inc(Args);

    Flags:=RxToLongint(Args^);

    Config.iProcessListEx(Block, Key, List, Flags);
   end;
 end;

// g**

function gGroups(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 begin
  Result:=0;

  PointerToRx(Config.gGroups, Ret);
 end;

function gGetParam(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 var
  Block: PStrings;
 begin
  if CheckArgC(ArgC, Result, 2) then
   begin
    Block:=RxToPointer(Args^);

    Inc(Args);

    StringToRx(Config.gGetParam(Block, RxToString(Args^)), Ret);
   end;
 end;

function gGetBoolParam(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 var
  Block: PStrings;
 begin
  if CheckArgC(ArgC, Result, 2) then
   begin
    Block:=RxToPointer(Args^);

    Inc(Args);

    BooleanToRx(Config.gGetBoolParam(Block, RxToString(Args^)), Ret);
   end;
 end;

function gGetNumParam(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 var
  Block: PStrings;
 begin
  if CheckArgC(ArgC, Result, 2) then
   begin
    Block:=RxToPointer(Args^);

    Inc(Args);

    LongintToRx(Config.gGetNumParam(Block, RxToString(Args^)), Ret);
   end;
 end;

function gProcessList(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 var
  Key: String;
  Block, List: PStrings;
 begin
  if CheckArgC(ArgC, Result, 2) then
   begin
    Block:=RxToPointer(Args^);

    Inc(Args);

    Key:=RxToString(Args^);

    Inc(Args);

    List:=RxToPointer(Args^);

    Config.gProcessList(Block, Key, List);
   end;
 end;

function gProcessListEx(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 var
  Key: String;
  Block, List: PStrings;
  Flags: Longint;
 begin
  if CheckArgC(ArgC, Result, 3) then
   begin
    Block:=RxToPointer(Args^);

    Inc(Args);

    Key:=RxToString(Args^);

    Inc(Args);

    List:=RxToPointer(Args^);

    Inc(Args);

    Flags:=RxToLongint(Args^);

    Config.gProcessListEx(Block, Key, List, Flags);
   end;
 end;

function gSearch(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 begin
  if CheckArgC(ArgC, Result, 1) then
   PointerToRx(Config.gSearch(RxToString(Args^)), Ret);
 end;

function gSearchByArea(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 begin
  if CheckArgC(ArgC, Result, 1) then
   PointerToRx(Config.gSearchByArea(RxToString(Args^)), Ret);
 end;

function gGetDoubleParam(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 var
  Block: PStrings;
 begin
  if CheckArgC(ArgC, Result, 2) then
   begin
    Block:=RxToPointer(Args^);

    Inc(Args);

    StringToRx(Config.gGetDoubleParam(Block, RxToString(Args^)), Ret);
   end;
 end;

function gGetDoubleBoolParam(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 var
  Block: PStrings;
 begin
  if CheckArgC(ArgC, Result, 2) then
   begin
    Block:=RxToPointer(Args^);

    Inc(Args);

    BooleanToRx(Config.gGetDoubleBoolParam(Block, RxToString(Args^)), Ret);
   end;
 end;

function gGetDoubleNumParam(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 var
  Block: PStrings;
 begin
  if CheckArgC(ArgC, Result, 2) then
   begin
    Block:=RxToPointer(Args^);

    Inc(Args);

    LongintToRx(Config.gGetDoubleNumParam(Block, RxToString(Args^)), Ret);
   end;
 end;

// b**

function bSearch(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 begin
  if CheckArgC(ArgC, Result, 1) then
   PointerToRx(Config.bSearch(RxToString(Args^)), Ret);
 end;

/////////////////////////////////////////////////////////////////////////////
// Semaphor
/////////////////////////////////////////////////////////////////////////////

function sSetSemaphore(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 var
  S: String;
 begin
  if CheckArgC(ArgC, Result, 2) then
   begin
    S:=RxToString(Args^);

    Inc(Args);

    Semaphor.sSetSemaphore(S, RxToString(Args^));
   end;
 end;

function sGetSemaphore(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 begin
  if CheckArgC(ArgC, Result, 1) then
   StringToRx(Semaphor.sGetSemaphore(RxToString(Args^)), Ret);
 end;

function sGetBoolSemaphore(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 begin
  if CheckArgC(ArgC, Result, 1) then
   BooleanToRx(Semaphor.sGetBoolSemaphore(RxToString(Args^)), Ret);
 end;

function sGetNumSemaphore(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 begin
  if CheckArgC(ArgC, Result, 1) then
   LongintToRx(Semaphor.sGetNumSemaphore(RxToString(Args^)), Ret);
 end;

function sGetPtrSemaphore(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 begin
  if CheckArgC(ArgC, Result, 1) then
   PointerToRx(Semaphor.sGetPtrSemaphore(RxToString(Args^)), Ret);
 end;

function sExitNow(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 begin
  Result:=0;

  BooleanToRx(Semaphor.sExitNow, Ret);
 end;

function sSetExitNow(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 begin
  Result:=0;

  Semaphor.sSetExitNow;
 end;

/////////////////////////////////////////////////////////////////////////////
// Log
/////////////////////////////////////////////////////////////////////////////

function logCreate(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 var
  S: String;
 begin
  if CheckArgC(ArgC, Result, 2) then
   begin
    S:=RxToString(Args^);

    Inc(Args);

    log.logCreate(S, RxToString(Args^));
   end;
 end;

function logWrite(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 var
  S: String;
 begin
  if CheckArgC(ArgC, Result, 2) then
   begin
    S:=RxToString(Args^);

    Inc(Args);

    log.logWrite(S, RxToString(Args^));
   end;
 end;

function logKill(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 begin
  if CheckArgC(ArgC, Result, 1) then
   log.logKill(RxToString(Args^));
 end;

/////////////////////////////////////////////////////////////////////////////
// Language
/////////////////////////////////////////////////////////////////////////////

function lngPrint(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 var
  LogName, Key: String;
 begin
  if CheckArgC(ArgC, Result, 2) then
   begin
    LogName:=RxToString(Args^);

    Inc(Args); Dec(ArgC);

    Key:=RxToString(Args^);

    Inc(Args); Dec(ArgC);

    lngBegin;

     while ArgC <> 0 do
      begin
       lngPush(RxToString(Args^));

       Inc(ArgS); Dec(ArgC);
      end;

     Language.lngPrint(LogName, Key);
    lngEnd;
   end;
 end;

function lngGet(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 begin
  if CheckArgC(ArgC, Result, 1) then
   StringToRx(Language.lngGet(RxToString(Args^)), Ret);
 end;

/////////////////////////////////////////////////////////////////////////////
// Plugins
/////////////////////////////////////////////////////////////////////////////

function pGet(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 begin
  Result:=0;

  PointerToRx(Plugins.pGet, Ret);
 end;

function pSearch(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 begin
  if CheckArgC(ArgC, Result, 1) then
   PointerToRx(Plugins.pSearch(RxToString(Args^)), Ret);
 end;

function srvBroadcast(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 var
  L: Longint;
 begin
  if CheckArgC(ArgC, Result, 2) then
   begin
    L:=RxToLongint(Args^);

    Inc(Args);

    Plugins.srvBroadcast(L, RxToPointer(Args^));
   end;
 end;

function srvExecute(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 var
  S: String;
  L: Longint;
 begin
  if CheckArgC(ArgC, Result, 2) then
   begin
    S:=RxToString(Args^);

    Inc(Args);

    L:=RxToLongint(Args^);

    LongintToRx(Plugins.srvExecute(S, L, RxToPointer(Args^)), Ret);
   end;
 end;

function srvExecuteDirect(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 var
  P: Pointer;
  L: Longint;
 begin
  if CheckArgC(ArgC, Result, 2) then
   begin
    P:=RxToPointer(Args^);

    Inc(Args);

    L:=RxToLongint(Args^);

    LongintToRx(Plugins.srvExecuteDirect(P, L, RxToPointer(Args^)), Ret);
   end;
 end;

/////////////////////////////////////////////////////////////////////////////
// Misc
/////////////////////////////////////////////////////////////////////////////

function mCreate(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 begin
  if not CheckArgC(ArgC, Result, 1) then
   Misc.mCreate(RxToString(Args^));
 end;

function mHasCreated(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 begin
  if not CheckArgC(ArgC, Result, 1) then
   BooleanToRx(Misc.mHasCreated(RxToString(Args^)), Ret);
 end;

function mCheckBreak(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 begin
  Result:=0;

  Misc.mCheckBreak;
 end;

function mCheckWildcard(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 var
  S: String;
 begin
  if not CheckArgC(ArgC, Result, 2) then
   begin
    S:=RxToString(Args^);

    Inc(Args);

    BooleanToRx(Misc.mCheckWildCard(S, RxToString(Args^)), Ret);
   end;
 end;

function mExec(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 begin
  if not CheckArgC(ArgC, Result, 1) then
   LongintToRx(Misc.mExec(RxToString(Args^)), Ret);
 end;

function mCleanDir(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 begin
  if not CheckArgC(ArgC, Result, 1) then
   BooleanToRx(Misc.mCleanDir(RxToString(Args^)), Ret);
 end;

function mCheckPlugin(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 var
  S: String;
 begin
  if not CheckArgC(ArgC, Result, 2) then
   begin
    S:=RxToString(Args^);

    Inc(Args);

    Misc.mCheckPlugin(S, RxToString(Args^));
   end;
 end;

function mSetTitle(Name: PChar; ArgC: ULong; Args: PRxString; QueueName: PChar; var Ret: RxString): ULong; export;
 begin
  if not CheckArgC(ArgC, Result, 1) then
   Misc.mSetTitle(RxToString(Args^));
 end;

{$OrgName-,StdCall-}

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint; export;
 var
  K: Longint;
 begin
  Service:=srYes;
  case ServiceNumber of
   snQueryName: Semaphor.sSetSemaphore('Kernel.Plugins.Info.Name', 'FUUEREXX');
   snQueryAuthor: Semaphor.sSetSemaphore('Kernel.Plugins.Info.Author', 'sergey korowkin');
   snQueryVersion: Service:=frVersion;
   snQueryReqVer: Service:=KernelVersion;
   snStartup:
    begin
     Service:=srYes;

     for K:=Low(Functions) to High(Functions) do
      RexxRegisterFunctionDLL(Functions[K], 'FUUEREXX', Functions[K]);
    end;
   snShutdown:
    for K:=Low(Functions) to High(Functions) do
     RexxDeRegisterFunction(Functions[K]);
  else
   Service:=srNotSupported;
  end;
 end;

exports
 SERVICE;

begin
end.
