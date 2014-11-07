unit Misc;

interface
uses
     Types;

{ not for them }
procedure mInit(ExecService: Pointer);
procedure mDone;

{ objects â¨¯  emulation :) }
procedure cmCreateStrings(var S: PStrings); {$IFNDEF SOLID}export;{$ENDIF}
procedure cmCreateMemoryStream(var S: PMemoryStream); {$IFNDEF SOLID}export;{$ENDIF}
procedure cmDisposeObject(S: PObject); {$IFNDEF SOLID}export;{$ENDIF}
procedure cmAllocMem(P: Pointer; Size: Word); {$IFNDEF SOLID}export;{$ENDIF}
procedure cmFreeMem(P: Pointer; Size: Word); {$IFNDEF SOLID}export;{$ENDIF}
procedure cmInsert(C: PCollection; O: Pointer); {$IFNDEF SOLID}export;{$ENDIF}
procedure cmDelete(C: PCollection; O: Pointer); {$IFNDEF SOLID}export;{$ENDIF}
procedure cmFree(C: PCollection; O: Pointer); {$IFNDEF SOLID}export;{$ENDIF}
procedure cmAtFree(C: PCollection; I: Integer); {$IFNDEF SOLID}export;{$ENDIF}
procedure cmAtInsert(C: PCollection; O: Pointer; I: Integer); {$IFNDEF SOLID}export;{$ENDIF}
procedure cmAtDelete(C: PCollection; I: Integer); {$IFNDEF SOLID}export;{$ENDIF}
function  cmIndexOf(C: PCollection; O: Pointer): Longint; {$IFNDEF SOLID}export;{$ENDIF}
function  cmAt(C: PCollection; I: Integer): Pointer; {$IFNDEF SOLID}export;{$ENDIF}
function  cmNewStr(const S: String): PString; {$IFNDEF SOLID}export;{$ENDIF}
procedure cmDisposeStr(S: PString); {$IFNDEF SOLID}export;{$ENDIF}
function  cmCount(C: PCollection): Longint; {$IFNDEF SOLID}export;{$ENDIF}
procedure cmSort(C: PCollection; H: TSortHandler); {$IFNDEF SOLID}export;{$ENDIF}
function  cmStreamGetPos(Stream: PStream): Longint; {$IFNDEF SOLID}export;{$ENDIF}
function  cmStreamGetSize(Stream: PStream): Longint; {$IFNDEF SOLID}export;{$ENDIF}
procedure cmStreamSeek(Stream: PStream; P: Longint); {$IFNDEF SOLID}export;{$ENDIF}
function  cmStreamWrite(Stream: PStream; var Buf; Count: Word): word; {$IFNDEF SOLID}export;{$ENDIF}
function  cmStreamRead(Stream: PStream; var Buf; Count: Word): word; {$IFNDEF SOLID}export;{$ENDIF}
procedure cmStreamCopyFrom(Stream: PStream; var S: TStream; Count: Longint); {$IFNDEF SOLID}export;{$ENDIF}
function  cmStreamReadStr(Stream: PStream): string; {$IFNDEF SOLID}export;{$ENDIF}
procedure cmStreamWriteStr(Stream: PStream; const S: String); {$IFNDEF SOLID}export;{$ENDIF}
function  cmStreamGetStatus(Stream: PStream): Longint; {$IFNDEF SOLID}export;{$ENDIF}
procedure cmFreeAll(C: PCollection); {$IFNDEF SOLID}export;{$ENDIF}
procedure cmDeleteAll(C: PCollection); {$IFNDEF SOLID}export;{$ENDIF}

{ other stuff.. }
procedure mCreate(Path: String); {$IFNDEF SOLID}export;{$ENDIF}
function  mHasCreated(Path: String): Boolean; {$IFNDEF SOLID}export;{$ENDIF}
procedure mCheckBreak; {$IFNDEF SOLID}export;{$ENDIF}
function  mCheckWildcard(S, Mask: String): boolean; {$IFNDEF SOLID}export;{$ENDIF}
function  mExec(const CommandLine: String): Longint; {$IFNDEF SOLID}export;{$ENDIF}
function  mCleanDir(ADirectory: String): boolean; {$IFNDEF SOLID}export;{$ENDIF}
procedure mCheckPlugin(const Caller, Name: String); {$IFNDEF SOLID}export;{$ENDIF}
function  sysService(Number: Longint; Buffer: Pointer): longint; {$IFNDEF SOLID}export;{$ENDIF}
procedure mSetTitle(const S: String); {$IFNDEF SOLID}export;{$ENDIF}

implementation
uses
     Dos, Wizard, Language, Video, Semaphor, Config, Consts_, Plugins, Log,
     Titles;

{$I FASTUUE.INC}

procedure cmCreateStrings(var S: PStrings);
 begin
  S:=New(PStrings, Init);
 end;

procedure cmDisposeStrings(var S: PStrings);
 begin
  Dispose(S, Done);
 end;

function cmNewStr(const S: String): PString;
 begin
  cmNewStr:=NewStr(S);
 end;

procedure cmDisposeStr(S: PString);
 begin
  DisposeStr(S);
 end;

procedure cmInsert(C: PCollection; O: Pointer);
 begin
  C^.Insert(O);
 end;

procedure cmDelete(C: PCollection; O: Pointer);
 begin
  C^.Delete(O);
 end;

procedure cmFree(C: PCollection; O: Pointer);
 begin
  C^.Free(O);
 end;

procedure cmDeleteAll(C: PCollection);
 begin
  C^.DeleteAll;
 end;

procedure cmFreeAll(C: PCollection);
 begin
  C^.FreeAll;
 end;

procedure cmAtFree(C: PCollection; I: Integer);
 begin
  C^.AtFree(I);
 end;

procedure cmAtInsert(C: PCollection; O: Pointer; I: Integer);
 begin
  C^.AtInsert(I, O);
 end;

procedure cmAtDelete(C: PCollection; I: Integer);
 begin
  C^.AtDelete(I);
 end;

function cmIndexOf(C: PCollection; O: Pointer): Longint;
 begin
  cmIndexOf:=C^.IndexOf(O);
 end;

function cmAt(C: PCollection; I: Integer): Pointer;
 begin
  cmAt:=C^.At(I);
 end;

function cmCount(C: PCollection): Longint;
 begin
  cmCount:=C^.Count;
 end;

procedure cmSort(C: PCollection; H: TSortHandler);
 begin
  C^.Sort(H);
 end;

procedure mCheckBreak;
 begin
  if kKeypressed then
   while kKeypressed do
    if kReadKey = #27 then sSetExitNow;
 end;

{
 mCheckWildcard: Alexander Starostin, 2:5020/1297.153, 22 ˆî« 98, 23:40:30.
}

const
 ItsFirst: integer = 0;

function mCheckWildcard;
 var
  I: integer;
  J: integer;
  Ok: boolean;
  St: string;
  Msk: string;
 begin
  if (Pos('*', Mask) = 0) and (Pos('?', Mask) = 0) then
   begin
    mCheckWildcard:=S = Mask;
    Exit;
   end;
  Inc(ItsFirst);
  I:=1;
  if ItsFirst=1 then
   begin
    while True do
     begin
      J:=Length(Mask);
      while I<Length(Mask) do
       begin
        if (Mask[I]='?') And (Mask[I+1]='*') Then Delete(Mask,I,1);
        if (Mask[I]='*') And (Mask[I+1]='?') And (I<Length(Mask)) Then Delete(Mask,I+1,1);
        If (Mask[I]='*') And (Mask[I+1]='*') And (I<Length(Mask)) Then Delete(Mask,I,1);
        Inc(I);
       end;
      if J=Length(Mask) then Break;
      I:=1;
     end;
   end;
  Ok:=True;
  I:=1;
  J:=1;
  while True do
   begin
    case Mask[I] Of
    '*':
      Begin
        Msk:=Copy(Mask,I+1,Length(Mask)-I+1);
        St:=Copy(S,J,Length(S)-J+1);
        while (St<>'') and (not mCheckWildcard(St,Msk)) do Delete(St,1,1);
        If (St='') and (Msk<>'') then Ok:=False else J:=Pos(St,S);
      End;
    '?':
      Begin
        If (I=Length(Mask)) And (J<Length(S)) Then Ok:=False;
        If J>Length(S) Then Ok:=False;
        Inc(J);
      End;
    else
     if Mask[I]<>S[J] then Ok:=False else Inc(J);
    end;
    if J-1>Length(S) then Ok:=False;
    if not Ok then Break;
    Inc(I);
    if I>Length(Mask) then Break;
   end;
  mCheckWildcard:=Ok;
  Dec(ItsFirst);
 end;

procedure cmCreateMemoryStream(var S: PMemoryStream);
 begin
  S:=New(PMemoryStream, Init);
 end;

procedure cmDisposeObject(S: PObject);
 begin
  Dispose(S, Done);
 end;

function cmStreamGetPos(Stream: PStream): Longint;
 begin
  cmStreamGetPos:=Stream^.GetPos;
 end;

function cmStreamGetSize(Stream: PStream): Longint;
 begin
  cmStreamGetSize:=Stream^.GetSize;
 end;

procedure cmStreamSeek(Stream: PStream; P: Longint);
 begin
  Stream^.Seek(P);
 end;

function cmStreamWrite(Stream: PStream; var Buf; Count: Word): word;
 begin
  Stream^.Write(Buf, Count);
  cmStreamWrite:=Count;
 end;

function cmStreamRead(Stream: PStream; var Buf; Count: Word): word;
 begin
  Stream^.Read(Buf, Count);
  cmStreamRead:=Count;
 end;

procedure cmStreamCopyFrom(Stream: PStream; var S: TStream; Count: Longint);
 begin
  Stream^.CopyFrom(S, Count);
 end;

procedure cmAllocMem(P: Pointer; Size: Word);
 begin
  GetMem(P, Size);
 end;

procedure cmFreeMem;
 begin
  FreeMem(P, Size);
 end;

{$IFDEF SOLID}
function mExec(const CommandLine: String): Longint;
 begin
  SwapVectors;
  if sGetBoolSemaphore('Kernel.Exec.Quiet') then
   Exec(GetEnv('COMSPEC'), '/C ' + CommandLine + '>nul')
  else
   Exec(GetEnv('COMSPEC'), '/C ' + CommandLine);
  mExec:=DosError;
  SwapVectors;
 end;
{$ELSE}
{$IFDEF DPMI}
function mExec(const CommandLine: String): Longint;
 begin
  sSetSemaphore('Kernel.Exec.CommandLine', CommandLine);
  lngBegin;
  lngPush(CommandLine);
  lngPrint('Main','Exec.Start');
  lngEnd;
  asm
   int 66h
  end;
  mExec:=sGetNumSemaphore('Kernel.Exec.ReturnValue');
  lngBegin;
  lngPush(sGetSemaphore('Kernel.Exec.ReturnValue'));
  lngPrint('Main','Exec.Done');
  lngEnd;
 end;
{$ENDIF}

{$IFDEF VIRTUALPASCAL}
var
 VPExec: function(CommandLine: String): Longint;

function mExec(const CommandLine: String): Longint;
 begin
  mExec:=VPExec(CommandLine);
 end;
{$ENDIF}
{$ENDIF}

{* mCleanDir stuff *}

type
 PFile = ^TFile;
 TFile = object(TObject)
 public
  Level: byte;
  FName: pstring;
  destructor Done; virtual;
 end;

destructor TFile.Done;
 begin
  inherited Done;
  DisposeStr(fname);
 end;

function mCleanDir(ADirectory: String): boolean;
 var
  Files: PCollection;
  CurrentLevel: Byte;
  AllOk: Boolean;
 procedure Scan(Dir: String);
  var
   Sr: Dos.SearchRec;
   F: PFile;
  begin
   Inc(CurrentLevel);
   Dir:=AddBackSlash(Dir);
   F:=New(PFile, Init);
   Files^.Insert(F);
   F^.Level:=CurrentLevel;
   F^.FName:=NewStr(Dir+'.');
   FindFirst(Dir+'*.*', AnyFile, Sr);
   while DosError=0 do
    begin
     if (Sr.Name[1]='.') then else
     if (Sr.Attr and (Directory+VolumeId)=(Directory)) then Scan(Dir+Sr.Name) else
     if (Sr.Attr and (Directory+VolumeId)=0) then
      begin
       F:=New(PFile, Init);
       Files^.Insert(F);
       F^.Level:=CurrentLevel;
       F^.FName:=NewStr(Dir+Sr.Name);
      end;
     FindNext(Sr);
    end;
   FindClose(Sr);
   Dec(CurrentLevel);
  end;
 var
  K: Longint;
  Level: Byte;
  S: String;
  F: File;
 begin
  ADirectory:=AddBackSlash(FExpand(Trim(ADirectory)));
  if Length(ADirectory)=3 then
   begin
    mCleanDir:=False;
    lngBegin;
    lngPush(ADirectory);
    lngPrint('Main','clean.suicide');
    lngEnd;
    Exit;
   end;
  CurrentLevel:=0;
  AllOk:=True;
  Files:=New(PCollection, Init);
  Scan(ADirectory);
  repeat
   Level:=0;
   for K:=1 to Files^.Count do
    if PFile(Files^.At(K))^.Level>Level then Level:=PFile(Files^.At(K))^.Level;
   for K:=1 to Files^.Count do
    if PFile(Files^.At(K))^.Level=Level then
     begin
      S:=GetPString(PFile(Files^.At(K))^.FName); {$I-} InOutRes:=0;
      if Copy(S,Length(S)-1,2)<>'\.' then
       begin
        if IOResult <> 0 then;
        SetAttr(S, 0);
        if IOResult <> 0 then;
        Assign(F,S);
        if IOResult <> 0 then;
        Erase(F);
        if IOResult<>0 then
         AllOk:=False;
        S:=JustPathName(S);
       end
      else
       S:=Copy(S,1,Length(S)-2);
      if PFile(Files^.At(K))^.Level<>1 then
       RmDir(S);
      InOutRes:=0;
     end;
   K:=0;
   repeat
    Inc(K);
    if K>Files^.Count then Break;
    if PFile(Files^.At(K))^.Level=Level then
     begin
      Files^.Free(Files^.At(K));
      K:=0;
     end;
   until False;
  until Files^.Count=0;
  Dispose(Files, Done);
  mCleanDir:=AllOk;
 end;

function cmStreamReadStr(Stream: PStream): string;
 begin
  cmStreamReadStr:=Stream^.ReadStr;
 end;

procedure cmStreamWriteStr(Stream: PStream; const S: String);
 begin
  Stream^.WriteStr(S);
 end;

function cmStreamGetStatus(Stream: PStream): Longint;
 begin
  cmStreamGetStatus:=Stream^.Status;
 end;

procedure mCheckPlugin(const Caller, Name: String);
 begin
  if pSearch(Name) = Nil then
   begin
    lngBegin;
    lngPush(Caller);
    lngPush(Name);
    lngPrint('Main', 'check.plugin');
    lngEnd;
    sSetExitNow;
   end;
 end;

function sysService(Number: Longint; Buffer: Pointer): longint;
 begin
  sysService:=srYes;
  case Number of
   ssGetLogs: Log._ssGetLogs(Buffer);
   ssOpenLog: Log._ssChangeLogStatus(Buffer, True);
   ssCloseLog: Log._ssChangeLogStatus(Buffer, False);
  else
   sysService:=srNotSupported;
  end;
 end;

procedure mSetTitle(const S: String);
 begin
  if S = '' then
   SetSessionTitle('FastUUE ' + Version2Str(KernelVersion))
  else
   SetSessionTitle('FastUUE ' + Version2Str(KernelVersion) + ', ' + S);
 end;

const
 CreatedList: PStrings = Nil;

function mHasCreated(Path: String): Boolean;
 var
  S: PString;
  K: Longint;
 begin
  if CreatedList = Nil then
   begin
    mHasCreated:=False;
    Exit;
   end;
  TrimEx(Path);
  StUpcaseEx(Path);
  Path:=AddBackSlash(Path);
  Path:=FExpand(Path);
  for K:=1 to CreatedList^.Count do
   begin
    S:=CreatedList^.At(K);
    if S = Nil then Continue;
    iF S^ = Path then
     begin
      mHasCreated:=True;
      Exit;
     end;
   end;
  mHasCreated:=False;
 end;

procedure mCreate(Path: String);
 var
  K: Integer;
  S: String absolute Path;
  _S: String;
  D: String;
 procedure Created(S: String);
  begin
   if CreatedList = Nil then Exit;
   TrimEx(S);
   StUpcaseEx(S);
   S:=AddBackSlash(S);
   S:=FExpand(S);
   CreatedList^.Insert(NewStr(S));
  end;
 begin
  S:=FExpand(AddBackSlash(S));
  if Copy(S,Length(S),1)='\' then Dec(S[0]);
  {$I-} InOutRes:=0;
  MkDir(S);
  if IOResult=0 then
   begin
    lngBegin;
    lngPush(S);
    lngPrint('Main','Misc.Created');
    lngEnd;
    Created(S);
   end else
   begin
    GetDir(0,_S);
    ChDir(S);
    if IOResult=0 then
     begin
      ChDir(_S);
      InOutRes:=0;
      Exit;
     end;
    ChDir(_S);
    D:=ExtractWord(1,S,['\'])+'\';
    for K:=2 to WordCount(S,['\']) do
     begin
      D:=D + ExtractWord(K,S,['\'])+'\';
      Dec(D[0]);
      {$I-}
      InOutRes:=0;
      MkDir(D);
      if IOResult=0 then
       begin
        lngBegin;
        lngPush(D);
        lngPrint('Main','Misc.Created');
        lngEnd;
        Created(D);
       end;
      InOutRes:=0;
      D:=AddBackSlash(D);
     end;
   end;
 end;

procedure mInit;
 begin
  CreatedList:=New(PStrings, Init);
  if cGetBoolParam('Exec.Quiet') then
   sSetSemaphore('Kernel.Exec.Quiet','Yes')
  else
   sSetSemaphore('Kernel.Exec.Quiet','No');
{$IFDEF VIRTUALPASCAL}
{$IFNDEF SOLID}
  @VPExec:=ExecService;
{$ENDIF}
{$ENDIF}
 end;

procedure mDone;
 begin
  if CreatedList <> Nil then Dispose(CreatedList, Done);
 end;

end.
