unit Startup;

interface

function StartupProc(CmdLine: String; Stuff1: Pointer): Longint; {$IFNDEF SOLID}export;{$ENDIF}

implementation

uses
{$IFDEF WIN32}
     vpSysLow,
{$ENDIF}
{$IFDEF SOLID}
     Strings,
{$ENDIF}
     Types, Consts_, Vars, Video, Config, Semaphor, Log, Language,
     Plugins, Resource, Misc, {Logo,} PlugCore, Division,
     Wizard, Dos, Titles{, Rexx}{, Hooks};

{$I FASTUUE.INC}
{$I SECRET.INC}

const
{$IFDEF SOLID}
{$IFNDEF CUSTOMSOLID}
 __SOLID__ = '/SOLID';
{$ELSE}
 __SOLID__ = '/SOLIDc';
{$ENDIF}
{$ELSE}
 __SOLID__ = '';
{$ENDIF}

var
 ConfigFile, ConfigBlock, OldTitle: String;
 ChangeDir, MakeLogo: Boolean;
 FixedTime: Longint;
 Stuff: PSecretStuff;
 Year, Month, Day: System.Word;

procedure CheckForSomeDates;
 begin
  ReloadAnyway:=0;

  iWannaDate(Day, Month, Year);


  if (Month = 4) and (Day = 27) then
   begin
    lngAddToPool('scr.you.wanna.dance','$0A(:) $0EKuzmich was born 27 of april in 1981 :)$07#0d#0a');
    lngAddToPool('log.you.wanna.dance','Kuzmich was born 27 of april in 1981 :)');
    ReloadAnyway:=18;
   end
  else
  if (Month = 7) and (Day = 15) then
   begin
    lngAddToPool('scr.you.wanna.dance','$0A(:) $0EHappy birthday, $0AAlexander$0E! Please go drink $0Abeer$0E!$07#0d#0a');
    lngAddToPool('log.you.wanna.dance','Happy birthday, Alexander! Please go drink beer! :-)');

    ReloadAnyway:=15;
   end
  else
   if (Day = 15) then
    begin
     if cGetBoolParam('Elks.Must.Die') then
      Exit;
     lngAddToPool('scr.elk.твою.мать', '$0A(:) $0EElk''s DAY TODAY! Muahahahahahahahahehehehehohohoho... ;-)#0d#0a');
     lngAddToPool('log.elk.твою.мать', 'Elk''s DAY TODAY! Enjoy''em! [don''t forget to write some lettaz to 2:503?/15 ;-))]');
     ReloadAnyway:=1;
    end;
  if (Month = 8) and (Day = 28) then
   begin
    lngAddToPool('scr.you.wanna.dance','$0A(:) $0EHappy birthday, $0Ask$0E! Please go drink $0Abeer$0E!$07#0d#0a');
    lngAddToPool('log.you.wanna.dance','Happy birthday, sk! Please go drink beer! :-)');
    ReloadAnyway:=2;
   end;
  if ((Month = 12) and (Day = 31)) or ((Month = 1) and (Day = 1)) then
   begin
    lngAddToPool('scr.you.wanna.dance','$0A(:) $0EHappy New Year, $0ASergey$0E! Please go drink $0Abeer$0E!$07#0d#0a');
    lngAddToPool('log.you.wanna.dance','Happy New Year, Sergey! Please go drink beer! :-)');
    ReloadAnyway:=3;
   end;
  if (Month = 5) and (Day = 21) then
   begin
    lngAddToPool('scr.you.wanna.dance','$0A(:) $0EHappy birthday, $0AMike$0E! Please go drink $0Abeer$0E!$07#0d#0a');
    lngAddToPool('log.you.wanna.dance','Happy birthday, Mike! Please go drink beer! :-)');
    ReloadAnyway:=4;
   end;
  if (Month = 4) and (Day = 23) then
   begin
    lngAddToPool('scr.you.wanna.dance','$0A(:) $0EHappy birthday, $0AFather$0E! Please go drink $0Abeer$0E!$07#0d#0a');
    lngAddToPool('log.you.wanna.dance','Happy birthday, Father! Please go drink beer! :-)');
    ReloadAnyway:=5;
   end;
  if (Month = 2) and (Day = 3) then
   begin
    lngAddToPool('scr.you.wanna.dance','$0A(:) $0EMy greetz to $0APasha Vovk$0E! Please go drink $0Abeer$0E!$07#0d#0a');
    lngAddToPool('log.you.wanna.dance','Happy birthday, Pasha! Please go drink beer! :-)');
    ReloadAnyway:=6;
   end;
  if (Month = 10) and (Day = 13) then
   begin
    lngAddToPool('scr.you.wanna.dance','$0A(:) $0EHappy birthday, $0ASp0Raw$0E! Please go drink $0Abeer$0E!$07#0d#0a');
    lngAddToPool('log.you.wanna.dance','Happy birthday, Sp0Raw! Please go drink beer! :-)');
    ReloadAnyway:=6;
   end;
  if (Month = 2) and (Day = 27) then
   begin
    ReloadAnyway:=16;
    lngAddToPool('scr.you.wanna.dance',
    '$0A(:) $0CVyacheslav Kuznetsov$02 родился. А то б не вышла эта версия :)$07#0d#0a');
    lngAddToPool('log.you.wanna.dance','Vyacheslav Kuznetsov родился. А то б не вышла эта версия :)');
   end else
  if (Day = 27) then
   begin
    lngAddToPool('scr.you.wanna.dance','$0A(:) $0Cthe MAGIC of 27! $0a(:)$07#0d#0a');
    lngAddToPool('log.you.wanna.dance','');
    ReloadAnyway:=7;
   end;
  if (Day = 11) then
   begin
    lngAddToPool('scr.you.wanna.dance','$0A(:) $0CБИОЛОГИЯ -- MD! $0a(:)$07#0d#0a');
    lngAddToPool('log.you.wanna.dance','');
    ReloadAnyway:=8;
   end;
  if (Month = 5) and (Day = 22) then
   begin
    lngAddToPool('scr.you.wanna.dance','$0A(:) $0EHappy birthday, $0ABeck$0E! Please go drink $0Abeer$0E!$07#0d#0a');
    lngAddToPool('log.you.wanna.dance','Happy birthday, Beck! Please go drink beer! :-)');
    ReloadAnyway:=9;
   end;
  if (Day = 24) then
   begin
    lngAddToPool('scr.you.wanna.dance','$0A(:) $0Cнастойка бояpышника -- pуле.. $0a(:)$07#0d#0a');
    lngAddToPool('log.you.wanna.dance','');
    ReloadAnyway:=10;
   end;
  if (Month = 7) and (Day = 17) then
   begin
    ReloadAnyway:=11;
    lngAddToPool('scr.you.wanna.dance','$0A(:) $0EHappy birthday, $0Anick$0E! Please go drink $0Abeer$0E!$07#0d#0a');
    lngAddToPool('log.you.wanna.dance','Happy birthday, nick! Please go drink beer! :-)');
   end;
  if (Month = 9) and (Day = 2) then
   begin
    ReloadAnyway:=12;
    lngAddToPool('scr.you.wanna.dance','$0A(:) $0EHappy birthday, $0Alena$0E! Please go drink $0Abeer$0E!$07#0d#0a');
    lngAddToPool('log.you.wanna.dance','Happy birthday, lena! Please go drink beer! :-)');
   end;
  if (Month = 8) and (Day = 2) then
   begin
    ReloadAnyway:=13;
    lngAddToPool('scr.you.wanna.dance',
    '$0A(:) $0DПоздравляю себя, любимого, с $0CД$0Dнем $0CР$0Dождения. $0AAlexander Reznikov$0E$07#0d#0a');
    lngAddToPool('log.you.wanna.dance','Поздравляю себя, любимого. Alexander Reznikov');
   end;
  if (Month = 6) and (Day = 3) then
   begin
    ReloadAnyway:=14;
    lngAddToPool('scr.you.wanna.dance',
    '$0A(:) $0D$0CAleks A.Zol$0D, с Днём Рождения тебя!$07#0d#0a');
    lngAddToPool('log.you.wanna.dance','Aleks A.Zol, с Днём Рождения тебя!');
   end;
  if (Month = 9) and (Day = 12) then
   begin
    ReloadAnyway:=15;
    lngAddToPool('scr.you.wanna.dance',
    '$0A(:) $0CГлотыч, ты ещё не пропил свой узел? :)$0D Happy birthday to you!$07#0d#0a');
    lngAddToPool('log.you.wanna.dance','Глотыч, ты ещё не пропил свой узел? :) Happy birthday to you!');
   end;
  if (Month = 6) and (Day = 21) then
   begin
    ReloadAnyway:=16;
    lngAddToPool('scr.you.wanna.dance',
    '$0A(:) $0CA$0Anton $0CT$0Aumilovich$0F вряд ли это прочитает, так как сегодня его $0BДР$0F!$07#0d#0a');
    lngAddToPool('log.you.wanna.dance','Anton Tumilovich вряд ли это прочитает, так как сегодня его ДР!');
   end;
  if (Month = 5) and (Day = 26) then
   begin
    ReloadAnyway:=17;
    lngAddToPool('scr.you.wanna.dance',
    '$0A(:) $0AС Днём Рождения, $0CArtyom Timchenko$0F!$07#0d#0a');
    lngAddToPool('log.you.wanna.dance','С Днём Рождения, Artyom Timchenko!');
   end;
 end;

function StartupProc(CmdLine: String; Stuff1: Pointer): Longint;
 var
  K, L, Leak: Longint;
  S: String;
  DT: DateTime;
  Plugin: PPlugin;
  Help: Boolean;
{$IFDEF SOLID}
  SolidPluginsC: integer;
  SolidPlugins: Boolean;
{$ENDIF}
{  Rx: RxString; }
 label
  Shutdown,
  Shutdown_Language;
 begin
  Leak:=MemAvail;

  OldTitle:=GetSessionTitle;

  FixedTime:=TimeFix;
  ErrorLevel:=0;
  Quiet:=False;
  Stuff:=Stuff1;
  MakeLogo:=True;
  mSetTitle('Startup');
  repeat
   vInit(Stuff^.VideoService);
   Stuff^.OldAttr:=vGetAttr;

   { parse commandline }
   ChangeDir:=True;
   HomeDir:=RemoveBackSlash(FExpand(JustPathName(ExtractWord(1, CmdLine, [' ']))));
   ConfigFile:=FExpand(ForceExtension(ExtractWord(1, CmdLine, [' ']), 'CTL'));
   ConfigBlock:='MAIN';
   Help:=False;
{$IFDEF SOLID}
   SolidPlugins:=False;
{$ENDIF}
   for K:=1 to WordCount(CmdLine, [' ']) do
    begin
     S:=ExtractWord(K, CmdLine, [' ']);
     TrimEx(S);
     StUpcaseEx(S);

     if Copy(S, 1, 3) = '/F:' then ConfigFile:=Copy(S, 4, 255) else
     if Copy(S, 1, 3) = '/C:' then
      begin
       ConfigBlock:=Copy(S, 4, 255);
       TrimEx(ConfigBlock);
       StUpcaseEx(ConfigBlock);
      end else
{$IFDEF SOLID}
     if S = '/S' then SolidPlugins:=true else
{$ENDIF}
     if S = '/Q' then Quiet:=True else
     if S = '/NCD' then ChangeDir:=False else
     if S = '/NOLOGO' then MakeLogo:=False else
     if S = '/RELOADCFG' then ReloadForce:=True else
     if S = '/?' then Help:=True;
    end;

   vSetAttr(7);
   vClrScr;

   vSetAttr(14);
   vPrint('8*) ');

   vSetAttr(15);
   vPrint(Pad('FastUUE/' + OS_Type + ' ' + Version2Str(KernelVersion) +'hb' + '/' +
    Long2Str(__BUILD__) + '/' + __DATE__ + __SOLID__ + ' [FREEWARE]', 57));

   vSetAttr(12);
   vPrint({'ONLY }'NOT FOR LAME USERS!');
   vGotoY(2);

   vSetAttr(7);
   vPrintLn('    Copyright (c) by sergey korowkin, 1998-99. All rights reserved.');
   vPrintLn('             (pc) by nick markewitch, 1999.');
   vPrintLn('         (bugfix) by Alexander Reznikov, 2002.');

   if ChangeDir then
    begin
     if IOResult <> 0 then;

     ChDir(RemoveBackSlash(HomeDir));

     if InOutRes <> 0 then
      vPrintLn('Unable to change directory to ' + HomeDir + ', rc=#' + HexL(IOResult));
    end;

   cInit;

   lngInit;
   vSetAttr($0E);
   if cLoadConfiguration(ConfigFile, ConfigBlock) then
    begin
     vSetAttr($0a);
     vPrint(#13);
     vClrEol;
     vPrintLn('    The configuration was loaded from ' + JustFileName(GetCompiledExtension(ConfigFile)) + ' (' +
      cGetErrorString + ' bytes).');
    end
   else
    begin
     if not cLoad(ConfigFile) then
      begin
       vPrintLn('');
       vSetAttr(12);
       vPrintLn('    ' + cGetErrorString);
       vPrintLn('');
       ErrorLevel:=1;
       cDone;
       Break;
      end;
     if not cParse(ConfigBlock) then
      begin
       vPrintLn(' ');
       vSetAttr(12);
       vPrintLn('    ' + cGetErrorString);
       vPrintLn('');
       ErrorLevel:=2;
       cDone;
       Break;
      end;
     if not lngLoad then Goto Shutdown_Language;
     vSetAttr($0a);
     vPrint(#13);
     vClrEol;
     vPrintLn('    The configuration was parsed from ' + JustFileName(ConfigFile) + ' because');
     vPrintLn('    ' + cGetErrorString);
    end;
   logInit;
   Stuff^.ShowHole:=cGetBoolParam('Debug.ShowHole');
   logCreate('Main', cGetParam('Log'));
   if MakeLogo then
    MakeLogo:=cGetParam('Logo.Disable') <> '2:5030/15.409';

   { OS detection }
   lngBegin;
    lngPush(Version2Str(KernelVersion));
    lngPush(Long2StrFmt(MemAvail));
    lngPush(OS_Type);
    {$IFDEF WIN32}
    case SysPlatformID of
     0: lngPush('Win32');
     1: lngPush('Windows');
     2: lngPush('Windows NT');
    else
     lngPush(OS_Name);
    end;
    {$ELSE}
    lngPush(OS_Name);
    {$ENDIF}
    {$IFDEF OS2}
    lngPush(Long2Str(Hi(DosVersion) div 10) + '.' + Long2Str(Hi(DosVersion) - (Hi(DosVersion) div 10 * 10)));
    {$ENDIF}
    {$IFDEF DPMI}
    lngPush(Long2Str(Lo(DosVersion))+'.'+Long2Str(Hi(DosVersion)));
    {$ENDIF}
    {$IFDEF WIN32}
    lngPush(Long2Str(Lo(DosVersion)) + '.' + Long2Str(Hi(DosVersion)));
    {$ENDIF}
    lngPrint('Main','Startup');
   lngEnd;

   if cGetBoolParam('Purchased') and (cGetParam('Purchased.By') <> '') then
    begin
     lngAddToPool('scr.purchased', '%info% Registered to: %title%%1%normal%.#0d#0a#0d#0a');
     lngBegin;
      lngPush(cGetParam('Purchased.By'));
      lngPrint('Main', 'purchased');
     lngEnd;
    end;

   CheckForSomeDates;
   lngPrint('Main', 'elk.твою.мать');
   lngPrint('Main','you.wanna.dance');

   {!}

   lngPrint('Main','Semaphore.Startup');
   sInit;
   sSetSemaphore('Kernel.Version', Version2Str(KernelVersion));
   mInit(Stuff^.ExecService);
   rInit;

   if Help then
    begin
     lngPrint('Main', 'user.wanna.help');

     sSetExitNow;
    end;

{$IFDEF SOLID}
   if SolidPlugins then
    begin
    lngBegin;
{$IFDEF CUSTOMSOLID}
     lngPush('custom');
{$ELSE}
     lngPush('standart');
{$ENDIF}
     lngPrint('Main', 'user.solid');
    lngEnd;
    for SolidPluginsC:=1 to SolidDllcnt do
    begin
     lngBegin;
      lngPush(LeftPadCh(Long2Str(SolidPluginsC), ' ', 2));
      lngPush(StrPas(SolidDll[SolidPluginsC]));
      lngPrint('Main', 'user.solid.dll');
     lngEnd;
    end; 
     sSetExitNow;
    end;
{$ENDIF}     

   if sExitNow then
    Goto Shutdown;

   if cGetBoolParam('Debug.Config') then
    cDump;

   if cGetBoolParam('Debug.Language') then
    lngDump;

   diInit;

   pInit;

{   ExecuteHook(GetHookFName('Startup'), 0, nil, Rx);
   DestroyRx(Rx);
}
   for L:=1 to WordCount(CmdLine,[' ']) do
    begin
     S:=Trim(StUpcase(ExtractWord(L, CmdLine, [' '])));

     if (S[0] <> #0) and (S[1] in ['/','-']) then
      Delete(S,1,1);

     sSetSemaphore('Kernel.CommandLine', S);

     srvBroadcast(snCommandLine, nil);
    end;

   if not sExitNow then
    for L:=1 to pGet^.Count do
     begin
      Plugin:=pGet^.At(L);

      if sExitNow then
       begin
        lngBegin;
        lngPush(Plugin^.Name^);
        lngPrint('Main','Plugin.ExitNow');
        lngEnd;
        Break;
       end;

      Plugin^.Service(snAfterStartup, nil);
     end;

   if (not sExitNow) and (pSearch('USER') = Nil) then
    begin
     lngPrint('Main', 'where.is.my.favorite.plugin');
     sSetExitNow;
    end;

   mSetTitle('Working');

{   ExecuteHook(GetHookFName('Start'), 0, nil, Rx);
   DestroyRx(Rx);
}
   if not sExitNow then
    pStart;
{
   ExecuteHook(GetHookFName('Shutdown'), 0, nil, Rx);
   DestroyRx(Rx);
}
   mSetTitle('Shutting down');
   lngPrint('Main', 'store');
   GeneralBlock:=ConfigBlock;
   if cStoreConfiguration(ConfigFile) then
    begin
     lngBegin;
     lngPush(cGetErrorString);
     lngPrint('Main', 'stored');
     lngEnd;
    end
   else
    begin
     lngBegin;
     lngPush(cGetErrorString);
     lngPrint('Main', 'store.error');
     lngEnd;
    end;
   pDone;
   diDone;
Shutdown:
   rDone;
   lngPrint('Main','Semaphore.Shutdown');
   sDone;
   lngBegin;
   lngPush(Long2StrFmt(CacheCount));
   lngPush(Long2StrFmt(CacheTotal));
   lngPush(Long2StrFmt(CacheHits));
   if CacheTotal = 0 then Inc(CacheTotal);
   lngPush(Long2StrFmt(Round(CacheHits/CacheTotal*100)));
   lngPrint('Main', 'Cache');
   lngEnd;
   lngBegin;
   TimeDif(TimeFix - FixedTime, DT);
   lngPush(Version2Str(KernelVersion));
   lngPush(Long2Str(DT.Hour));
   lngPush(Long2Str(DT.Min));
   lngPush(Long2Str(DT.Sec));
   lngPrint('Main','Shutdown');
   lngEnd;
   lngBegin;
   lngPush(Long2Str(Errorlevel));
   lngPush(OS_Name);
   lngPrint('Main','Exit');
   lngEnd;
Shutdown_Language:
   lngDone;
   logDone;
   cDone;
  until True;
  mDone;
  vDone;
  vSetAttr(7);
  StartupProc:=ErrorLevel;
  {$IFDEF DPMI}
  if Stuff^.ShowHole then
   begin
    vSetAttr($0c);
    vPrint('    ');
    vSetAttr($0F);
    vPrint(Long2StrFmt(Leak - MemAvail));
    vSetAttr($0C);
    vPrint(' bytes in asshole.');
    vSetAttr(Stuff^.OldAttr);
    vPrintLn('');
   end;
  {$ENDIF}
{  if MakeLogo then ShowLogo; }
  SetSessionTitle(OldTitle);
 end;

end.
