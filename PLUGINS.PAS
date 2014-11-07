unit Plugins;

interface

uses
{$IFDEF DPMI}
{     WinProcs, }
      WinApi,
{$ENDIF}
{$IFDEF WIN32}
     Windows,
{$ENDIF}
{$IFDEF OS2}
     OS2base,
{$ENDIF}
     Types,
     Language, Video, Config, Semaphor, Consts_,
     Wizard, Strings;

const
 Pool: PCollection = Nil;

type
 PService = ^TService;
 TService = function(ServiceNumber: Longint; Buffer: Pointer): Longint;

 PPlugin = ^TPlugin;
 TPlugin = object(TObject)
  FName, Name, SearchName: PString;
  Service: TService;
  ErrorCode: Longint;
 {$IFDEF VIRTUALPASCAL}
  Handle: Longint;
 {$ELSE}
  Handle: Word;
 {$ENDIF}
  constructor Init(const AFName: String);
  function Load: Boolean;
  procedure Unload;
  procedure Boot;
  destructor Done; virtual;
 end;

{$IFDEF SOLID}
type
 TQueryPluginService = function(const FName: String): Pointer;

const
 QueryPluginService: TQueryPluginService = Nil;
{$ENDIF}

{ called by plugins & kernel }

function pGet: PCollection; {$IFNDEF SOLID}export;{$ENDIF}
function pSearch(Name: String): PPlugin; {$IFNDEF SOLID}export;{$ENDIF}
procedure pQueryPluginInfo(const Plugin: Pointer; 
                           var FName, Name, SearchName: String; 
                           var Service: Pointer); {$IFNDEF SOLID}export;{$ENDIF}
procedure srvBroadcast(const ServiceNumber: Longint; const Buffer: Pointer); {$IFNDEF SOLID}export;{$ENDIF}
function srvExecute(const Name: String; const ServiceNumber: Longint; 
                    const Buffer: Pointer): Longint; {$IFNDEF SOLID}export;{$ENDIF}
function srvExecuteDirect(const Plugin: Pointer; const ServiceNumber: Longint; 
                          const Buffer: Pointer): Longint; {$IFNDEF SOLID}export;{$ENDIF}

implementation
{$IFDEF SOLID}
const
 MaxHandle: Longint = 0;
{$ENDIF}

constructor TPlugin.Init(const AFName: String);
 begin
  inherited Init;
  FName:=NewStr(AFName);
  Name:=Nil;
  SearchName:=Nil;
  Service:=Nil;
 end;

function TPlugin.Load: Boolean;
{$IFDEF SOLID}
 var
  FileName: String;
 begin
  FileName:=FName^;
  TrimEx(FileName);
  StUpCaseEx(FileName);
  FileName:=JustFileName(FileName);
  @Service:=QueryPluginService(FileName);
  if @Service = Nil then
   begin
    sSetSemaphore('Plugin.Subsystem.ErrorString', 'plugin.internal.x3');
    Load:=False;
    Exit;
   end;
  Load:=True;
  Inc(MaxHandle);
  Handle:=MaxHandle;
 end;
{$ELSE}
 var
  Temp, FileName: array[0..256] of Char;
 begin
  sSetSemaphore('Plugin.Subsystem.ErrorString', 'plugin.error.linking');
  StrPCopy(@FileName, FName^);
  {$IFDEF OS2}
   ErrorCode:=DosLoadModule(Temp, SizeOf(Temp), FileName, Handle);
   if ErrorCode <> 0 then
    begin
     Load:=False;
     Exit;
    end;
   DosQueryProcAddr(Handle, 0, 'SERVICE', @Service);
  {$ELSE}
   Handle:=LoadLibrary(@FileName);
   {$IFDEF DPMI}
   if Handle < 22 then
    begin
     ErrorCode:=Handle;
     Load:=False;
     Exit;
    end;
   @Service:=GetProcAddress(Handle, 'Service');
   {$ELSE}
   if Handle = 0 then
    begin
     ErrorCode:=GetLastError;
     Load:=False;
     Exit;
    end;
   @Service:=GetProcAddress(Handle, 'SERVICE');
   {$ENDIF}
  {$ENDIF}
  if @Service = Nil then
   begin
    sSetSemaphore('Plugin.Subsystem.ErrorString', 'plugin.error.noservice');
    Load:=False;
    Exit;
   end;
  Load:=True;
 end;
{$ENDIF}

procedure TPlugin.Unload;
{$IFDEF SOLID}
 begin
 end;
{$ELSE}
 begin
  {$IFDEF OS2}
  DosFreeModule(Handle);
  {$ELSE}
  FreeLibrary(Handle);
  {$ENDIF}
 end;
{$ENDIF}

procedure TPlugin.Boot;
 begin
  Service(snQueryName, Nil);
  DisposeStr(Name);
  DisposeStr(SearchName);
  Name:=NewStr(sGetSemaphore('Kernel.Plugins.Info.Name'));
  SearchName:=NewStr(StUpCase(Trim(Name^)));
 end;

destructor TPlugin.Done;
 begin
  DisposeStr(FName);
  inherited Done;
 end;

function pGet: PCollection;
 begin
  pGet:=Pool;
 end;

function pSearch(Name: String): PPlugin;
 var
  K: Longint;
 begin
  StUpCaseEx(Name);
  for K:=1 to Pool^.Count do
   if PPlugin(Pool^.At(K))^.SearchName^ = Name then
    begin
     pSearch:=Pool^.At(K);
     Exit;
    end;
  pSearch:=Nil;
 end;

procedure pQueryPluginInfo(const Plugin: Pointer; var FName, Name, SearchName: String; var Service: Pointer);
 begin
  GetPStringEx(PPlugin(Plugin)^.FName, FName);
  GetPStringEx(PPlugin(Plugin)^.Name, Name);
  GetPStringEx(PPlugin(Plugin)^.SearchName, SearchName);
  Service:=@PPlugin(Plugin)^.Service;
 end;

procedure srvBroadcast(const ServiceNumber: Longint; const Buffer: Pointer);
 var
  K: Longint;
 begin
  for K:=1 to Pool^.Count do
   PPlugin(Pool^.At(K))^.Service(ServiceNumber, Buffer);
 end;

function srvExecute(const Name: String; const ServiceNumber: Longint; const Buffer: Pointer): Longint;
 var
  P: PPlugin;
 begin
  P:=pSearch(Name);
  if P = Nil then
   srvExecute:=$FFFFFFFF
  else
   srvExecute:=P^.Service(ServiceNumber, Buffer);
 end;

function srvExecuteDirect(const Plugin: Pointer; const ServiceNumber: Longint; const Buffer: Pointer): Longint;
 begin
  srvExecuteDirect:=PPlugin(Plugin)^.Service(ServiceNumber, Buffer);
 end;

end.
