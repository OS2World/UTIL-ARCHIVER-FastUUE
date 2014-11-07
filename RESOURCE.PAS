unit Resource;

interface
uses Types;

procedure rInit;
procedure rDone;

procedure rPut(const Name: String; var Data; Size: Longint); {$IFNDEF SOLID}export;{$ENDIF}
procedure rGet(const Name: String; var Data); {$IFNDEF SOLID}export;{$ENDIF}
procedure rPutStream(const Name: String; S: PStream; Size: Longint); {$IFNDEF SOLID}export;{$ENDIF}
procedure rGetStream(const Name: String; S: PStream); {$IFNDEF SOLID}export;{$ENDIF}
procedure rDelete(const Name: String); {$IFNDEF SOLID}export;{$ENDIF}
function  rExist(const Name: String): boolean; {$IFNDEF SOLID}export;{$ENDIF}
procedure rGetInfo(const Name: String); {$IFNDEF SOLID}export;{$ENDIF}
function  rGetSize(const Name: String): longint; {$IFNDEF SOLID}export;{$ENDIF}
function  rError: Boolean; {$IFNDEF SOLID}export;{$ENDIF}
function  rGetErrorString: String; {$IFNDEF SOLID}export;{$ENDIF}
procedure rReset; {$IFNDEF SOLID}export;{$ENDIF}
function  rGetIndexSize: longint; {$IFNDEF SOLID}export;{$ENDIF}
function  rGetIndexName(I: longint): String; {$IFNDEF SOLID}export;{$ENDIF}

implementation
uses
     Video, Config, Log, Wizard, FileLib, Vars, Language, Semaphor,
     Misc;

const
 Lib            : PLibrary = Nil;
 CountKey                  = 'resource.pack.count';
 Count          : Longint  = 0;

var
 FName          : String;
 TempFName      : String;

procedure rInit;
 begin
  lngPrint('Main', 'resmanager.init');
  FName:=cGetParam('Resource.FileName');
  TempFName:=cGetParam('Resource.TempFileName');
  if (FName = '') or (TempFName = '') then
   begin
    lngPrint('Main', 'resmanager.notspec');
    sSetExitNow;
    Exit;
   end;
  mCreate(JustPathName(FName));
  mCreate(JustPathName(TempFName));
  Lib:=New(PLibrary, Init(FName));
  if Lib^.Error then
   begin
    lngBegin;
    lngPush(Lib^.ErrorString);
    lngPrint('Main', 'resmanager.cannotstart');
    lngEnd;
    ErrorLevel:=2;
    sSetExitNow;
    Exit;
   end;
  lngBegin;
  lngPush(FExpand(FName));
  lngPrint('Main', 'resmanager.info');
  lngEnd;
  Lib^.Debugging:=cGetBoolParam('Debug.Resource');
 end;

procedure rPut(const Name: String; var Data; Size: Longint);
 begin
  if Lib = Nil then Exit;
  Lib^.AddResourceFromMemory(Name, @Data, Size);
 end;

procedure rGet(const Name: String; var Data);
 begin
  if Lib = Nil then Exit;
  Lib^.GetResourceToMemory(Name, @Data);
 end;

procedure rDelete(const Name: String);
 begin
  if Lib = Nil then Exit;
  Lib^.KillResource(Name);
 end;

function  rExist(const Name: String): boolean;
 begin
  if Lib = Nil then Exit;
  rExist:=Lib^.QueryResource(Name) <> Nil;
 end;

procedure rGetInfo(const Name: String);
 var
  I: PItem;
 begin
  if Lib = Nil then Exit;
  I:=Lib^.QueryResource(Name);
  if I = Nil then
   begin
    sSetSemaphore('Resource.Info', 'Error');
    Exit;
   end;
  sSetSemaphore('Resource.Info.ID', Long2Str(I^.ID));
  sSetSemaphore('Resource.Info.Offset', Long2Str(I^.Offset));
  sSetSemaphore('Resource.Info.Size', Long2Str(I^.Size));
  sSetSemaphore('Resource.Info.Name', I^.Name);
  sSetSemaphore('Resource.Info.ChunkSize', Long2Str(SizeOf(TItem)));
 end;

function rGetSize(const Name: String): longint;
 begin
  if Lib = Nil then Exit;
  rGetSize:=Lib^.GetResourceSize(Name);
 end;

function rError: boolean;
 begin
  if Lib = Nil then Exit;
  rError:=Lib^.Error;
 end;

function rGetErrorString: String;
 begin
  if Lib = Nil then Exit;
  rGetErrorString:=Lib^.ErrorString;
 end;

procedure rReset;
 begin
  if Lib = Nil then Exit;
  Lib^.Reset;
 end;

procedure rDone;
 var
  Ok: Boolean;
  S: TBufStream;
  F: File;
 begin
  if cGetBoolParam('Resource.Pack') and (not sExitNow) then
   begin
    Ok:=True;
     if cGetParam('Resource.Pack.Step') <> '' then
      begin
       if not rExist(CountKey) then
        rPut(CountKey, Count, SizeOf(Count));
       rGet(CountKey, Count);
       Inc(Count);
       if Count >= cGetNumParam('Resource.Pack.Step') then
        begin
         Count:=0;
         Ok:=True;
        end
       else
        Ok:=False;
       rPut(CountKey, Count, SizeOf(Count));
      end;
    if Ok then
     begin
      lngPrint('Main', 'resmanager.packing');
      Lib^.Error:=False;
      S.Init(TempFName, stCreate, 2048);
      if S.Status <> stOk then
       Lib^.DoError('Cannot pack resourcefile, rc#' + Long2Str(S.Status))
      else
       Lib^.Pack(@S);
      S.Done;
      if Lib^.Error then
       begin
        lngBegin;
        lngPush(Lib^.ErrorString);
        lngPrint('Main', 'resmanager.packing.error');
        lngEnd;
       end
      else
       begin
        {$I-}
        if IOResult <> 0 then;
        Assign(F, TempFName);
        Erase(F);
        if IOResult <> 0 then;
       end;
     end
    else
     begin
      lngBegin;
      lngPush(Long2Str(Count));
      lngPush(Long2Str(cGetNumParam('Resource.Pack.Step')));
      lngPrint('Main', 'resmanager.packing.notnow');
      lngEnd;
     end;
   end;
  if Lib <> Nil then Dispose(Lib, Done);
  lngPrint('Main', 'resmanager.done');
 end;

procedure rPutStream(const Name: String; S: PStream; Size: Longint);
 begin
  Lib^.AddResource(Name, S, Size);
 end;

procedure rGetStream(const Name: String; S: PStream);
 begin
  Lib^.GetResource(Name, S);
 end;

function rGetIndexSize: longint;
 begin
  rGetIndexSize:=Lib^.Index^.Count;
 end;

function rGetIndexName(I: Longint): String;
 var
  Z: PItem;
 begin
  Z:=Lib^.Index^.At(I);
  if Z = Nil then
   rGetIndexName:=''
  else
   rGetIndexName:=Z^.Name;
 end;

end.