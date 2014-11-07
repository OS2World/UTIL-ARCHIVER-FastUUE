{$IFDEF VIRTUALPASCAL}
function VideoService(ServiceNumber: Longint; _Number: Longint; const _String: String): byte; far;
 begin
  case ServiceNumber of
   1: Write(_String);
   2: WriteLn;
   3: ClrScr;
   4: ClrEol;
   5: VideoService:=TextAttr;
   6: TextAttr:=_Number;
   7: VideoService:=Byte(Keypressed);
   8: VideoService:=Byte(ReadKey);
   9: GotoXY(1, _Number);
  end;
 end;
{$ENDIF}

{$IFDEF VIRTUALPASCAL}
function ExecService(CommandLine: String): Longint;
 begin
  if sGetBoolSemaphore('Kernel.Exec.Quiet') then
   Exec(GetEnv('COMSPEC'),' /C '+CommandLine+' >nul')
  else
   Exec(GetEnv('COMSPEC'),' /C '+CommandLine);
  ExecService:=DosExitCode;
 end;

procedure Init;
 begin
 end;

procedure Done;
 begin
 end;
{$ENDIF}

