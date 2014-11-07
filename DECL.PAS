unit Decl;

interface
{$IFNDEF SOLID}
uses Types;

{begin}
procedure mCreate(Path: String);                 (* MISC *)
function  mHasCreated(Path: String): Boolean;
procedure cmCreateStrings(var S: PStrings);
procedure cmCreateMemoryStream(var S: PMemoryStream);
procedure cmDisposeObject(S: PObject);
procedure cmAllocMem(P: Pointer; Size: Word);
procedure cmFreeMem(P: Pointer; Size: Word);
procedure cmInsert(C: PCollection; O: Pointer);
procedure cmDelete(C: PCollection; O: Pointer);
procedure cmFree(C: PCollection; O: Pointer);
procedure cmAtFree(C: PCollection; I: Integer);
procedure cmAtInsert(C: PCollection; O: Pointer; I: Integer);
procedure cmAtDelete(C: PCollection; I: Integer);
function  cmIndexOf(C: PCollection; O: Pointer): Longint;
function  cmAt(C: PCollection; I: Integer): Pointer;
function  cmNewStr(const S: String): PString;
procedure cmDisposeStr(S: PString);
function  cmCount(C: PCollection): Longint;
procedure cmSort(C: PCollection; H: TSortHandler);
procedure mCheckBreak;
function  mCheckWildcard(S, Mask: String): Boolean;
function  cmStreamGetPos(Stream: PStream): Longint;
function  cmStreamGetSize(Stream: PStream): Longint;
procedure cmStreamSeek(Stream: PStream; P: Longint);
function  cmStreamWrite(Stream: PStream; var Buf; Count: Word): word;
function  cmStreamRead(Stream: PStream; var Buf; Count: Word): word;
procedure cmStreamCopyFrom(Stream: PStream; var S: TStream; Count: Longint);
function  mExec(const CommandLine: String): Longint;
function  mCleanDir(ADirectory: String): Boolean;
function  cmStreamReadStr(Stream: PStream): String;
procedure cmStreamWriteStr(Stream: PStream; const S: String);
function  cmStreamGetStatus(Stream: PStream): Longint;
procedure cmFreeAll(C: PCollection);
procedure cmDeleteAll(C: PCollection);
procedure mCheckPlugin(const Caller, Name: String);
function  sysService(Number: Longint; Buffer: Pointer): Longint;
procedure mSetTitle(const S: String);

procedure vPrint(const S: String);               (* VIDEO *)
procedure vPrintLn(const S: String);
procedure vClrScr;
procedure vClrEol;
function vGetAttr: Byte;
procedure vSetAttr(Color: Byte);
function kKeypressed: Boolean;
function kReadkey: Char;
procedure vGotoY(Y:Byte);

procedure logCreate(Name, FName: String);        (* LOG *)
procedure logWrite(Name, S: String);
procedure logKill(Name: String);

procedure sSetSemaphore(Name, Value: String);    (* SEMAPHOR *)
function sGetSemaphore(Name: String): String;
function sGetBoolSemaphore(Name: String): Boolean;
function sGetNumSemaphore(Name: String): Longint;
function sGetPtrSemaphore(Name: String): Pointer;
function sExitNow: Boolean;
procedure sSetExitNow;

procedure cProcessList(const Key: String; List: PStrings); (* CONFIG *)
procedure cProcessListEx(const Key: String; List: PStrings; Flags: Longint);
function  cGetParam(const Key: String): String;
function  cGetBoolParam(const Key: String): Boolean;
function  cGetNumParam(const Key: String): Longint;
function  cConfiguration: PStrings;
procedure iProcessList(C: PStrings; const Key: String; List: PStrings);
procedure iProcessListEx(C: PStrings; const Key: String; List: PStrings; Flags: Longint);
function  iGetParam(C: PStrings; const Key: String): String;
function  iGetBoolParam(C: PStrings; Key: String): Boolean;
function  iGetNumParam(C: PStrings; Key: String): Longint;
function  gGroups: PCollection;
procedure gProcessList(G: PStrings; const Key: String; List: PStrings);
procedure gProcessListEx(G: PStrings; const Key: String; List: PStrings; Flags: Longint);
function  gGetParam(G: PStrings; const Key: String): String;
function  gGetBoolParam(G: PStrings; const Key: String): Boolean;
function  gGetNumParam(G: PStrings; const Key: String): Longint;
function  gSearch(Name: String): PStrings;
function  gSearchByArea(Area: String): PStrings;
function  bSearch(Name: String): PStrings;
function  gGetDoubleBoolParam(G: PStrings; const Key: String): Boolean;
function  gGetDoubleParam(G: PStrings; const Key: String): String;
function  gGetDoubleNumParam(G: PStrings; const Key: String): Longint;

procedure lngBegin;                              (* LANGUAGE *)
procedure lngPush(const Value: String);
procedure lngPrint(const LogName, Key: String);
procedure lngEnd;
function  lngGet(Key: String): String;

function  pGet: PCollection;                     (* PLUGINS *)
function  pSearch(Name: String): PObject;
procedure pQueryPluginInfo(const Plugin: Pointer; var FName, Name, SearchName: String; var Service: Pointer);
procedure srvBroadcast(const ServiceNumber: Longint; const Buffer: Pointer);
function  srvExecute(const Name: String; const ServiceNumber: Longint; const Buffer: Pointer): Longint;
function  srvExecuteDirect(const Plugin: Pointer; const ServiceNumber: Longint; const Buffer: Pointer): Longint;

procedure rPut(const Name: String; var Data; Size: Longint); (* RESOURCE *)
procedure rGet(const Name: String; var Data);
procedure rPutStream(const Name: String; S: PStream; Size: Longint);
procedure rGetStream(const Name: String; S: PStream);
procedure rDelete(const Name: String);
function  rExist(const Name: String): Boolean;
procedure rGetInfo(const Name: String);
function  rGetSize(const Name: String): Longint;
function  rError: Boolean;
function  rGetErrorString: String;
procedure rReset;
function  rGetIndexSize: Longint;
function  rGetIndexName(I: Longint): String;

function diSeek(const Identifier: Longint): Pointer;         (* DIVISON *)
function diCreate(const Identifier: Longint): Pointer;
function diDestroy(const Identifier: Longint): Boolean;

function diSetString(const Structure: Pointer; const Name, Value: String): Boolean;
function diSetBool(const Structure: Pointer; const Name: String; const Value: Boolean): Boolean;
function diSetNum(const Structure: Pointer; const Name: String; const Value: Longint): Boolean;

function diGetString(const Structure: Pointer; const Name: String): String;
function diGetBool(const Structure: Pointer; const Name: String): Boolean;
function diGetNum(const Structure: Pointer; const Name: String): Longint;

function diDestroyString(const Structure: Pointer; const Name: String): Boolean;

function diCreateList(const Structure: Pointer; const Name: String): Pointer;
function diDestroyList(const Structure: Pointer; const Name: String): Boolean;
{end}

{$ENDIF}
implementation

{$IFNDEF SOLID}
(* MISC *)
procedure mCreate(Path: String); external 'MAIN';
function  mHasCreated(Path: String): Boolean; external 'MAIN';
procedure cmCreateStrings(var S: PStrings); external 'MAIN';
procedure cmCreateMemoryStream(var S: PMemoryStream); external 'MAIN';
procedure cmDisposeObject(S: PObject); external 'MAIN';
procedure cmAllocMem(P: Pointer; Size: Word); external 'MAIN';
procedure cmFreeMem(P: Pointer; Size: Word); external 'MAIN';
procedure cmInsert(C: PCollection; O: Pointer); external 'MAIN';
procedure cmDelete(C: PCollection; O: Pointer); external 'MAIN';
procedure cmFree(C: PCollection; O: Pointer); external 'MAIN';
procedure cmAtFree(C: PCollection; I: Integer); external 'MAIN';
procedure cmAtInsert(C: PCollection; O: Pointer; I: Integer); external 'MAIN';
procedure cmAtDelete(C: PCollection; I: Integer); external 'MAIN';
function  cmIndexOf(C: PCollection; O: Pointer): Longint; external 'MAIN';
function  cmAt(C: PCollection; I: Integer): Pointer; external 'MAIN';
function  cmNewStr(const S: String): PString; external 'MAIN';
procedure cmDisposeStr(S: PString); external 'MAIN';
function  cmCount(C: PCollection): Longint; external 'MAIN';
procedure cmSort(C: PCollection; H: TSortHandler); external 'MAIN';
procedure mCheckBreak; external 'MAIN';
function  mCheckWildcard(S, Mask: String): Boolean; external 'MAIN';
function  cmStreamGetPos(Stream: PStream): Longint; external 'MAIN';
function  cmStreamGetSize(Stream: PStream): Longint; external 'MAIN';
procedure cmStreamSeek(Stream: PStream; P: Longint); external 'MAIN';
function  cmStreamWrite(Stream: PStream; var Buf; Count: Word): word; external 'MAIN';
function  cmStreamRead(Stream: PStream; var Buf; Count: Word): word; external 'MAIN';
procedure cmStreamCopyFrom(Stream: PStream; var S: TStream; Count: Longint); external 'MAIN';
function  mExec(const CommandLine: String): Longint; external 'MAIN';
function  mCleanDir(ADirectory: String): Boolean; external 'MAIN';
function  cmStreamReadStr(Stream: PStream): String; external 'MAIN';
procedure cmStreamWriteStr(Stream: PStream; const S: String); external 'MAIN';
function  cmStreamGetStatus(Stream: PStream): Longint; external 'MAIN';
procedure cmFreeAll(C: PCollection); external 'MAIN';
procedure cmDeleteAll(C: PCollection); external 'MAIN';
procedure mCheckPlugin(const Caller, Name: String); external 'MAIN';
function  sysService(Number: Longint; Buffer: Pointer): Longint; external 'MAIN';
procedure mSetTitle(const S: String); external 'MAIN';

(* VIDEO *)
procedure vPrint(const S: String); external 'MAIN';
procedure vPrintLn(const S: String); external 'MAIN';
procedure vClrScr; external 'MAIN';
procedure vClrEol; external 'MAIN';
function vGetAttr: Byte; external 'MAIN';
procedure vSetAttr(Color: Byte); external 'MAIN';
function kKeypressed: Boolean; external 'MAIN';
function kReadkey: Char; external 'MAIN';
procedure vGotoY(Y:Byte); external 'MAIN';

(* LOG *)
procedure logCreate(Name, FName: String); external 'MAIN';
procedure logWrite(Name, S: String); external 'MAIN';
procedure logKill(Name: String); external 'MAIN';

(* SEMAPHOR *)
procedure sSetSemaphore(Name, Value: String); external 'MAIN';
function sGetSemaphore(Name: String): String; external 'MAIN';
function sGetBoolSemaphore(Name: String): Boolean; external 'MAIN';
function sGetNumSemaphore(Name: String): Longint; external 'MAIN';
function sGetPtrSemaphore(Name: String): Pointer; external 'MAIN';
function sExitNow: Boolean; external 'MAIN';
procedure sSetExitNow; external 'MAIN';

(* CONFIG *)
procedure cProcessList(const Key: String; List: PStrings); external 'MAIN';
procedure cProcessListEx(const Key: String; List: PStrings; Flags: Longint); external 'MAIN';
function  cGetParam(const Key: String): String; external 'MAIN';
function  cGetBoolParam(const Key: String): Boolean; external 'MAIN';
function  cGetNumParam(const Key: String): Longint; external 'MAIN';
function  cConfiguration: PStrings; external 'MAIN';
procedure iProcessList(C: PStrings; const Key: String; List: PStrings); external 'MAIN';
procedure iProcessListEx(C: PStrings; const Key: String; List: PStrings; Flags: Longint); external 'MAIN';
function  iGetParam(C: PStrings; const Key: String): String; external 'MAIN';
function  iGetBoolParam(C: PStrings; Key: String): Boolean; external 'MAIN';
function  iGetNumParam(C: PStrings; Key: String): Longint; external 'MAIN';
function  gGroups: PCollection; external 'MAIN';
procedure gProcessList(G: PStrings; const Key: String; List: PStrings); external 'MAIN';
procedure gProcessListEx(G: PStrings; const Key: String; List: PStrings; Flags: Longint); external 'MAIN';
function  gGetParam(G: PStrings; const Key: String): String; external 'MAIN';
function  gGetBoolParam(G: PStrings; const Key: String): Boolean; external 'MAIN';
function  gGetNumParam(G: PStrings; const Key: String): Longint; external 'MAIN';
function  gSearch(Name: String): PStrings; external 'MAIN';
function  gSearchByArea(Area: String): PStrings; external 'MAIN';
function  bSearch(Name: String): PStrings; external 'MAIN';
function  gGetDoubleBoolParam(G: PStrings; const Key: String): Boolean; external 'MAIN';
function  gGetDoubleParam(G: PStrings; const Key: String): String; external 'MAIN';
function  gGetDoubleNumParam(G: PStrings; const Key: String): Longint; external 'MAIN';

(* LANGUAGE *)
procedure lngBegin; external 'MAIN';
procedure lngPush(const Value: String); external 'MAIN';
procedure lngPrint(const LogName, Key: String); external 'MAIN';
procedure lngEnd; external 'MAIN';
function  lngGet(Key: String): String; external 'MAIN';

(* PLUGINS *)
function  pGet: PCollection; external 'MAIN';
function  pSearch(Name: String): PObject; external 'MAIN';
procedure pQueryPluginInfo(const Plugin: Pointer; var FName, Name, SearchName: String; var Service: Pointer); external 'MAIN';
procedure srvBroadcast(const ServiceNumber: Longint; const Buffer: Pointer); external 'MAIN';
function  srvExecute(const Name: String; const ServiceNumber: Longint; const Buffer: Pointer): Longint; external 'MAIN';
function  srvExecuteDirect(const Plugin: Pointer; const ServiceNumber: Longint; const Buffer: Pointer): Longint;
 external 'MAIN';

(* RESOURCE *)
procedure rPut(const Name: String; var Data; Size: Longint); external 'MAIN';
procedure rGet(const Name: String; var Data); external 'MAIN';
procedure rPutStream(const Name: String; S: PStream; Size: Longint); external 'MAIN';
procedure rGetStream(const Name: String; S: PStream); external 'MAIN';
procedure rDelete(const Name: String); external 'MAIN';
function  rExist(const Name: String): Boolean; external 'MAIN';
procedure rGetInfo(const Name: String); external 'MAIN';
function  rGetSize(const Name: String): Longint; external 'MAIN';
function  rError: Boolean; external 'MAIN';
function  rGetErrorString: String; external 'MAIN';
procedure rReset; external 'MAIN';
function  rGetIndexSize: Longint; external 'MAIN';
function  rGetIndexName(I: Longint): String; external 'MAIN';

(* DIVISION *)
function diSeek(const Identifier: Longint): Pointer; external 'MAIN';
function diCreate(const Identifier: Longint): Pointer; external 'MAIN';
function diDestroy(const Identifier: Longint): Boolean; external 'MAIN';

function diSetString(const Structure: Pointer; const Name, Value: String): Boolean; external 'MAIN';
function diSetBool(const Structure: Pointer; const Name: String; const Value: Boolean): Boolean; external 'MAIN';
function diSetNum(const Structure: Pointer; const Name: String; const Value: Longint): Boolean; external 'MAIN';

function diGetString(const Structure: Pointer; const Name: String): String; external 'MAIN';
function diGetBool(const Structure: Pointer; const Name: String): Boolean; external 'MAIN';
function diGetNum(const Structure: Pointer; const Name: String): Longint; external 'MAIN';

function diDestroyString(const Structure: Pointer; const Name: String): Boolean; external 'MAIN';

function diCreateList(const Structure: Pointer; const Name: String): Pointer; external 'MAIN';
function diDestroyList(const Structure: Pointer; const Name: String): Boolean; external 'MAIN';
{$ENDIF}

end.