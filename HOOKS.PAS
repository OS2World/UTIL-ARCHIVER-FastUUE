{&Use32+}
unit Hooks;

interface
uses
     Rexx,
     Strings,

     windows,
     Wizard,

     Video,
     Config,
     Semaphor,
     Language;

function ExecuteHook(const FName: String; const ArgC: Longint; Args: PRxString; var Ret: RxString): Boolean;

function GetHookFName(const Key: String): String;

procedure DestroyRx(var Rx: RxString);

function RxToString(var Rx: RxString): String;
function RxToLongint(var Rx: RxString): Longint;
function RxToBoolean(var Rx: RxString): Boolean;
function RxToPointer(var Rx: RxString): Pointer;

procedure StringToRx(const S: String; var Rx: RxString);
procedure LongintToRx(const S: Longint; var Rx: RxString);
procedure BooleanToRx(const S: Boolean; var Rx: RxString);
procedure PointerToRx(const S: Pointer; var Rx: RxString);

implementation
uses
     vpSysLow;

{ ExecuteHook }

function ExecuteHook(const FName: String; const ArgC: Longint; Args: PRxString; var Ret: RxString): Boolean;
 var
  S: String;
  rc: longint;
  rc2: system.word;
  FNameA: Array[0..255] of Char;
 begin
  ret.strptr:=nil;
  ret.strlength:=0;

  if FName = '' then
   begin
    Result:=False;

    Exit;
   end;

  if not ExistFile(FName) then
   begin
    Result:=False;

    lngBegin;
     lngPush(FName);
     lngPush('-1');

     lngPrint('Main', 'error.cant.open');
    lngEnd;

    Exit;
   end;

  StrPCopy(FNameA, FName);

  rc:=RexxStart(ArgC, Args, FNameA, nil, 'CMD', RxSubroutine, nil, rc2, Ret);

  if (rc <> 0) or (rc2 <> 0) then
   begin
    vPrintLn('');
    vPrintLn('');
    vPrintLn('');
    vPrintLn('');
    vPrintLn('');
    vPrintLn('');

    lngBegin;
     lngPush(FName);
     lngPush(HexL(rc));
     lngPush(HexW(rc2));

     lngPrint('Main', 'hook.error');
    lngEnd;

    Result:=False;
   end
  else
   Result:=True;
 end;

{ GetHookFName }

function GetHookFName(const Key: String): String;
 begin
  GetHookFName:=cGetParam(Concat('Hook.', Key));
 end;

{ DestroyRet }

procedure DestroyRx(var Rx: RxString);
 begin
  if Assigned(Rx.strptr) then
   begin
    SysMemFree(Rx.strptr);

    Rx.strptr:=nil;
    Rx.strlength:=0;
   end;
 end;

{ RxTo... series }

function RxToString(var Rx: RxString): String;
 begin
  if not Assigned(Rx.strptr) then
   Result:=''
  else
   Result:=StrPas(Rx.strptr);
 end;

function RxToLongint(var Rx: RxString): Longint;
 var
  rc: Integer;
  S: String;
 begin
  S:=RxToString(Rx);

  Val(S, Result, rc);

  if rc <> 0 then
   Result:=0;
 end;

function RxToBoolean(var Rx: RxString): Boolean;
 var
  S: String;
 begin
  S:=RxToString(Rx);

  StLocaseEx(S);

  RxToBoolean:=(S = 'yes') or (S = 'rulez');
 end;

function RxToPointer(var Rx: RxString): Pointer;
 var
  S: String;
  Code: Integer;
 begin
  S:=RxToString(Rx);

  if S = '' then
   Result:=Nil
  else
   begin
    Val(Concat('$', S), Longint(Result), Code);

    if Code <> 0 then
     Result:=Nil;
   end;
 end;

{ ...ToRx series }

procedure StringToRx(const S: String; var Rx: RxString);
 begin
  DestroyRx(Rx);

  Rx.strlength:=Length(S) + 1;

  GetMem(Rx.strptr, Rx.strlength);

  StrPCopy(Rx.strptr, S);
 end;

procedure LongintToRx(const S: Longint; var Rx: RxString);
 begin
  StringToRx(Long2Str(S), Rx);
 end;

procedure BooleanToRx(const S: Boolean; var Rx: RxString);
 begin
  case S of
   True: StringToRx('YES', Rx);
   False: StringToRx('NO', Rx);
  end;
 end;

procedure PointerToRx(const S: Pointer; var Rx: RxString);
 begin
  StringToRx(HexL(Longint(S)), Rx);
 end;

end.
