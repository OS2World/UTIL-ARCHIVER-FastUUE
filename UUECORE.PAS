unit uueCore;

{$IFDEF VIRTUALPASCAL}
 {$DEFINE USEUNITS}
{$ENDIF}
{$IFDEF SOLID}
 {$DEFINE USEUNITS}
{$ENDIF}

interface
uses
{$IFDEF USEUNITS}
     Misc, Language, Semaphor, Plugins, Config,
{$ELSE}
     Decl,
{$ENDIF}
     Consts_,
     Dos, Wizard, Types,
     uueOver, uueDec;

function __Startup: Longint;
procedure __CommandLine(const CommandLine: String);
procedure __AfterStartup;
procedure __Start;
procedure __Shutdown;

implementation

function __Startup: Longint;
 var
  C: Char;
  S: String;
  K: Longint;
  P: PString;
 begin
  __Startup:=srNo;

  lngPrint('Main', 'uue.Init');

  uueTempFilename:=cGetParam('uue.Temp.Filename');
  uueTempFilenameBackup:=cGetParam('uue.Temp.Filename.Backup');

  if uueTempFilename = uueTempFilenameBackup then
   begin
    lngPrint('Main', 'uue.temp.not.valid');

    sSetExitNow;

    Exit;
   end;

  mCreate(JustPathname(uueTempFilename));
  mCreate(JustPathname(uueTempFilenameBackup));

  uueDecoding:=cGetBoolParam('uue.Decoding');
  uueScanning:=cGetBoolParam('uue.Scanning');

  cmCreateStrings(uueHeaders);

  cProcessList('uue.Headers', uueHeaders);

  uueHeadersCount:=cmCount(uueHeaders);

  for C:=Low(uueTable) to High(uueTable) do
   uueTable[C]:=False;

  if uueHeadersCount = 0 then
   begin
    lngPrint('Main', 'uue.headers.not.valid');
    sSetExitNow;
    Exit;
   end;

  for K:=1 to uueHeadersCount do
   begin
    P:=cmAt(uueHeaders, K);
    StLocaseEx(P^);

    GetPStringEx(P, S);

    if (S = '') or (S[1] = '%') then
     begin
      lngPrint('Main', 'uue.headers.not.valid');
      sSetExitNow;
      Exit;
     end;

    uueTable[S[1]]:=True;
   end;

  __Startup:=srYes;
 end;

procedure __CommandLine(const CommandLine: String);
 begin
  if CommandLine = 'UUESCAN' then uueScanning:=True;
  if CommandLine = 'UUENOSCAN' then uueScanning:=False;
  if CommandLine = 'UUEDECODE' then uueDecoding:=True;
  if CommandLine = 'UUENODECODE' then uueDecoding:=False;
 end;

procedure __AfterStartup;
 begin
  mCheckPlugin('UUE', 'USER');
 end;

procedure __Start;
 begin
  __Decode;
 end;

procedure __Shutdown;
 begin
  cmDisposeObject(uueHeaders);

  EraseFile(uueTempFileName);
  EraseFile(uueTempFileNameBackup);

  lngPrint('Main', 'uue.done');
 end;

end.