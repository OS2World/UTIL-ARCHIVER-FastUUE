{$IFDEF SOLID}
unit LogCut;

interface

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint;

implementation
{$ELSE}
library LogCut;
{$ENDIF}

{$IfDef VIRTUALPASCAL}
uses Types, Consts_, Log, Video, Wizard, Misc, Language, Config, Semaphor,
     Plugins;
{$IFNDEF SOLID}
{$Dynamic MAIN.LIB}
{$ENDIF}
{$EndIF}
{$IFDEF DPMI}
uses
{$IFDEF SOLID}
     Plugins, Semaphor, Language, Misc, Config, Video,
{$ELSE}
     Decl,
{$ENDIF}
     Wizard, Consts_, Dos, Macroz, Types;
{$ENDIF}

const
 CuttedTitle = '[...skipped...]';
 logcutVersion = $00010100;

var
 CurDay, CurMonth, CurYear: Word;

var
 F: Text;
 T: File;
 S: String;
 sMonth, cMonth: String[20];
 Day, Month, Year, K: Longint;
 Found: Boolean;
 FileName, TempFileName: String;

procedure Cut;
 begin
  IWannaDate(CurDay, CurMonth, CurYear);
  case CurMonth of
   01: cMonth:='January';
   02: cMonth:='February';
   03: cMonth:='March';
   04: cMonth:='April';
   05: cMonth:='May';
   06: cMonth:='June';
   07: cMonth:='July';
   08: cMonth:='August';
   09: cMonth:='September';
   10: cMonth:='October';
   11: cMonth:='November';
   12: cMonth:='December';
  end;
  if IOResult<>0 then;
  {$I-}
  Assign(F, FileName);
  Reset(F);
  if IOResult<>0 then Exit;
  Assign(T, TempFileName);
  Rewrite(T, 1);
  if IOResult<>0 then
   begin
    Close(F);
    Exit;
   end;

  Found:=False;
  while not Eof(F) do
   begin
    ReadLn(F, S);
    if S[0] = #0 then Continue;
    if S[1] <> #12 then Continue;
    ReadLn(F, S);
    if Copy(S, 1, 20) <> '컴컴컴컴컴컴컴컴컴컴' then Continue;
    Str2Longint(ExtractWord(2, S, [' ']), Day);
    sMonth:=ExtractWord(3, S, [' ']);
    Str2Longint(ExtractWord(4, S, [' ',',']), Year);
    if (Day = CurDay) and (sMonth = cMonth) and (Year = CurYear) then
     begin
      Found:=True;
      Break;
     end;
   end;

  if Found then
   begin
    S:=CuttedTitle+#13#10+#13#10+#12+#13#10+S+#13#10;
    BlockWrite(T, S[1], Length(S));
    while not Eof(F) do
     begin
      ReadLn(F, S);
      S:=S+#13#10;
      BlockWrite(T, S[1], Length(S));
     end;
   end;

  Close(F);
  Close(T);
  if IOResult<>0 then;
  Erase(F);
  Rename(T, FileName);
  if IOResult<>0 then;
 end;

procedure LogsProc(const _LogName, LogFileName: String); far;
 begin
  FileName:=logFileName;
  TempFileName:=ForceExtension(LogFileName, '$$$');
  srvBroadcast(snStopThreads, nil);
  S:=_LogName;
  sysService(ssCloseLog, @S);

  Cut;

  S:=_LogName;
  sysService(ssOpenLog, @S);
  srvBroadcast(snResumeThreads, nil);
 end;

procedure Start;
 begin
  sysService(ssGetLogs, @LogsProc);
 end;

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint; {$IFNDEF SOLID}export;{$ENDIF}
 begin
  Service:=srYes;
  case ServiceNumber of
   snStartup:;
   snShutdown:;
   snQueryName: sSetSemaphore('Kernel.Plugins.Info.Name','LogCut');
   snQueryAuthor: sSetSemaphore('Kernel.Plugins.Info.Author','sergey korowkin');
   snQueryVersion: Service:=logcutVersion;
   snQueryReqVer: Service:=kernelVersion;
   snStart: Start;
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
