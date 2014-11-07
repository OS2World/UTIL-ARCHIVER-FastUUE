{$C FIXED PRELOAD PERMANENT}
{$A+,B-,D+,E+,F+,G-,I-,L+,N-,P+,Q-,R-,S-,T-,V-,X+,Y+}

{$IFDEF VIRTUALPASCAL}
{$M 65536,512000}
{$ELSE}
{$M 65521,0,655000}
{$ENDIF}

{$IFDEF SOLID}
uses
{$IFDEF WIN32}
     Windows,
{$ENDIF}
{$IFDEF VIRTUALPASCAL}
     VPUtils,
{$ENDIF}
     Startup, Video, Wizard;

{$I FASTUUE.INC}
{$I SECRET.INC}
{$I LEAKER.INC}

procedure Go;
 var
  CommandLine: String;
  K, C: Longint;
 begin
  Leaker(True);

  CommandLine:=ParamStr(0);
  for K:=1 to ParamCount do
   CommandLine:=CommandLine + ' ' + ParamStr(K);

  C:=StartupProc(CommandLine, @Stuff);

  Leaker(False);

  Halt(C);
 end;
{$ELSE}

{$IFDEF VIRTUALPASCAL}
uses Windows, Crt, Dos, Startup, Video, Semaphor, Wizard, VPUtils;
{$PMType Vio}
{$DYNAMIC MAIN.LIB}
{$ENDIF}

{$IFDEF DPMI}
uses WinApi, Dos, Wizard, Types;
{$ENDIF}

{$I FASTUUE.INC}
{$I SECRET.INC}
{$I LEAKER.INC}

{$IFDEF DPMI}
function StartupProc(CmdLine: String; Stuff1: Pointer): longint; external 'MAIN';
{$ENDIF}

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
  end;
 end;
{$ENDIF}

var
 OldExitProc: Pointer;

{$IFDEF DPMI}
var
 old66: procedure;
 old10: procedure;

procedure sSetSemaphore(Name, Value: String); external 'MAIN';
function sGetSemaphore(Name: String): String; external 'MAIN';
function sGetBoolSemaphore(Name: String): Boolean; external 'MAIN';

procedure Busy; interrupt;
 begin
 end;

procedure New66; interrupt;
 const
  Busy: Boolean = False;
 begin
  if Busy then Exit;
  Busy:=True;
  InOutRes:=0;
  DosError:=0;
  if sGetBoolSemaphore('Kernel.Exec.Quiet') then
   begin
    GetIntVec($10, @Old10);
    SetIntVec($10, @Busy);
   end;
  SwapVectors;
  if sGetBoolSemaphore('Kernel.Exec.Quiet') then
   Exec(GetEnv('COMSPEC'),' /C '+sGetSemaphore('Kernel.Exec.Commandline')+' >nul')
  else
   Exec(GetEnv('COMSPEC'),' /C '+sGetSemaphore('Kernel.Exec.Commandline'));
  SwapVectors;
  if sGetBoolSemaphore('Kernel.Exec.Quiet') then
   SetIntVec($10, @Old10);
  sSetSemaphore('Kernel.Exec.ReturnValue',Long2Str(ExitCode));
  Busy:=False;
 end;

procedure Init;
 begin
  GetIntVec($66, @old66);
  SetIntVec($66, @new66);
 end;

procedure Done;
 begin
  SetIntVec($66, @old66);
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

procedure NewExitProc; far;
 begin
  Done;
  ExitProc:=OldExitProc;
 end;

procedure Go;
 var
  CommandLine: String;
  K: Longint;
  C: Byte;
 begin
  Leaker(True);

  OldExitProc:=ExitProc;
  ExitProc:=@NewExitProc;
  Init;

  CommandLine:=ParamStr(0);
  for K:=1 to ParamCount do
   CommandLine:=CommandLine + ' ' + ParamStr(K);

 {$IFDEF VIRTUALPASCAL}
  Stuff.VideoService:=@VideoService;
  Stuff.ExecService:=@ExecService;
 {$ENDIF}

  C:=StartupProc(CommandLine, @Stuff);

  Leaker(False);

  Halt(C);
 end;
{$ENDIF}

begin
{$IFDEF WIN32}
 SetFileApisToOem;
{$ENDIF}
 Go;
end.
