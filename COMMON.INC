const
 sruReadyToSir                  = $00005000;
 snuCheck                       = $00005000;
 snuGetCRC                      = $00005001;
 snuCreateMacros                = $00005010;

 snuAddMacro                    = $00005011;
 snuAddFunction                 = $00005012;
 snuRemoveMacro                 = $00005013;
 snuProcessMacro                = $00005014;
 snuEmptyLine                   = $00005015;
 snuGetMacrosInfo               = $0000501E;
 snuDestroyMacros               = $0000501F;

 snuGetUnique                   = $00005020;
 snuGetMSGiD                    = $00005021;
 snuInvalidateLine              = $00005022;
 snuLFNto83                     = $00005023;
 snuChangeFilename              = $00005024;
 snuCheckBadFName               = $00005025;
 snuCreateFlag                  = $00005026;
 snuCleanupSubj                 = $00005027;
 snu83echo                      = $00005028;

 mcSystem                       = 1;
 mcUser                         = 2;

function uCheck: boolean;
 begin
  uCheck:=srvExecute('USER', snuCheck, nil)=sruReadyToSir;
 end;

function uGetCRC(const FName: String): Longint;
 begin
  sSetSemaphore('User.Filename', FName);
  uGetCRC:=srvExecute('USER', snuGetCRC, nil);
 end;

function uGetCRCerror: boolean;
 var
  A: Longint;
 begin
  Str2Longint(sGetSemaphore('User.Crc32.Error'), A);
  uGetCRCerror:=A<>0;
 end;

function umCreateMacros: pointer;
 begin
  umCreateMacros:=pointer(srvExecute('USER', snuCreateMacros, nil));
 end;

procedure umAddMacro(M: pointer; const ID, Data: String);
 begin
  sSetSemaphore('User.Macros', HexPtr(M));
  sSetSemaphore('User.Macros.ID', ID);
  sSetSemaphore('User.Macros.Data', Data);
  srvExecute('USER', snuAddMacro, nil);
 end;

procedure umAddFunction(M: pointer; const ID: String; Func: Pointer);
 begin
  sSetSemaphore('User.Macros', HexPtr(M));
  sSetSemaphore('User.Macros.ID', ID);
  sSetSemaphore('User.Macros.Func', HexPtr(Func));
  srvExecute('USER', snuAddFunction, nil);
 end;

procedure umRemoveFunction(M: pointer; const ID: String);
 begin
  sSetSemaphore('User.Macros', HexPtr(M));
  sSetSemaphore('User.Macros.ID', ID);
  srvExecute('USER', snuRemoveMacro, nil);
 end;

function umProcessMacro(M: pointer; const S: String): String;
 begin
  sSetSemaphore('User.Macros', HexPtr(M));
  sSetSemaphore('User.Macros.String', S);
  srvExecute('USER', snuProcessMacro, nil);
  umProcessMacro:=sGetSemaphore('User.Macros.String');
 end;

function umEmptyLine(M: pointer): boolean;
 begin
  umEmptyLine:=sGetBoolSemaphore('User.Macros.Emptyline');
 end;

procedure umDestroyMacros(M: pointer);
 begin
  sSetSemaphore('User.Macros', HexPtr(M));
  srvExecute('USER', snuDestroyMacros, nil);
 end;

procedure umGetMacrosInfo(M: pointer; const ID: String);
 begin
  sSetSemaphore('User.Macros', HexPtr(M));
  sSetSemaphore('User.Macros.ID', ID);
  srvExecute('USER', snuGetMacrosInfo, nil);
 end;

function uGetUnique(const S: String): String;
 begin
  sSetSemaphore('User.Unique', S);
  srvExecute('USER', snuGetUnique, nil);
  uGetUnique:=sGetSemaphore('User.Unique');
 end;

function uGetMSGiD: String;
 begin
  srvExecute('USER', snuGetMSGiD, nil);
  uGetMSGiD:=sGetSemaphore('User.MSGiD');
 end;

function uInvalidateLine(const S: String): String;
 begin
  sSetSemaphore('User.InvLine', S);
  srvExecute('USER', snuInvalidateLine, nil);
  uInvalidateLine:=sGetSemaphore('User.InvLine');
 end;

function uLFNto83(const S: String): String;
 begin
  sSetSemaphore('User.83', S);
  srvExecute('USER', snuLFNto83, nil);
  uLFNto83:=sGetSemaphore('User.83');
 end;

function u83echo(const S: String): String;
 begin
  sSetSemaphore('User.83', S);
  srvExecute('USER', snu83echo, nil);
  u83echo:=sGetSemaphore('User.83');
 end;

function uChangeFilename(const S: String; Counter: Longint; _83: Boolean): String;
 begin
  sSetSemaphore('User.FName', S);
  sSetSemaphore('User.Counter', Long2Str(Counter));
  if _83 then
   sSetSemaphore('User.83', 'Yes')
  else
   sSetSemaphore('User.83', 'No');
  srvExecute('USER', snuChangeFilename, nil);
  uChangeFilename:=sGetSemaphore('User.FName');
 end;

function uCheckBadFName(const S: String): String;
 begin
  sSetSemaphore('User.FName', S);
  srvExecute('USER', snuCheckBadFName, nil);
  uCheckBadFName:=sGetSemaphore('User.FName');
 end;

procedure uCreateFlag(const S: String);
 begin
  sSetSemaphore('User.Flag', S);
  srvExecute('USER', snuCreateFlag, nil);
 end;

function uCleanupSubj(const S: String): String;
 begin
  sSetSemaphore('User.Subj', S);
  srvExecute('USER', snuCleanupSubj, nil);
  uCleanupSubj:=sGetSemaphore('User.Subj');
 end;