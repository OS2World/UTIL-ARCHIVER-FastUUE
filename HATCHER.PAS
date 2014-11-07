{$IFDEF SOLID}
unit Hatcher;

interface

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint;

implementation
{$ELSE}
library Hatcher;
{$ENDIF}

{$IFDEF VIRTUALPASCAL}
uses Types, Consts_, Log, Video, Wizard, Misc, Language, Config, Semaphor,
     Plugins;
{$IFNDEF SOLID}
{$Dynamic MAIN.LIB}
{$ENDIF}
{$ENDIF}
{$IFDEF DPMI}
uses
{$IFDEF SOLID}
     Plugins, Semaphor, Language, Misc, Config, Video,
{$ELSE}
     Decl,
{$ENDIF}
     Wizard, Consts_, Dos, Macroz, Types;
{$ENDIF}

{$I hatcher.inc}
{$I archiver.inc}
{$I common.inc}
{$I files.inc}
{$I thedupe.inc}

const
 hatVersion     = $00010600;
 fileinfohost = 'Hatcher.FileInfo.';
 fileechohost = 'Hatcher.Fileecho.';

var
 tempRepackDir                  : String;
 tempRepackDirNoSlash           : String;
 error                          : Boolean;
 crc                            : longint;
 iArea                          : String;
 iSenderName                    : String;
 iSenderAddress                 : String;
 iReceiverName                  : String;
 iReceiverAddress               : String;
 iSubject                       : String;
 iTitle                         : String;
 iTempFilename                  : String;
 iFilename                      : String;
 iPacker                        : String;
 iRepacker                      : String;
 iConvert                       : Boolean;
 iFileIdDiz                     : Boolean;
 iFileIdDizName                 : String;
 iFileIdDizLines                : PStrings;
 iInfName                       : String;
 iInfLines                      : PStrings;
 iInf                           : Boolean;
 iFileecho                      : String;
 iTicName                       : String;
 iTicDir                        : String;
 iTicLines                      : PStrings;
 iInbound                       : String;
 iList                          : Boolean;
 iListFilename                  : String;
 iCheckDupes, iCheckDupesMemorize, i83: Boolean;

function iGetSize: longint;
 var
  F: File;
 begin
  {$I-} InOutRes:=0;
  Assign(F, iTempFileName);
  Reset(F, 1);
  if IOResult<>0 then
   begin
    iGetSize:=-1;
    Exit;
   end;
  iGetSize:=FileSize(F);
  Close(F);
  InOutRes:=0;
 end;

procedure AddDefaultMacros(M: pointer);
 begin
  umAddMacro(M, '@filename', iFileName);
  umAddMacro(M, '@size', Long2Str(iGetSize));
  umAddMacro(M, '@echo', iArea);
  umAddMacro(M, '@8.3echo', u83echo(iArea));
  umAddMacro(M, '@fileecho', iFileEcho);
  umAddMacro(M, '@inboundslash', AddBackSlash(iInbound));
  umAddMacro(M, '@inbound', RemoveBackSlash(iInbound));
  umAddMacro(M, '@subject', iSubject);
  umAddMacro(M, '@sender.name', iSenderName);
  umAddMacro(M, '@sender.address', iSenderAddress);
  umAddMacro(M, '@receiver.name', iReceiverName);
  umAddMacro(M, '@receiver.address', iReceiverAddress);
  umAddMacro(M, '@crc', HexL(crc));
  umAddMacro(M, '@title', iTitle);
 end;

function SingleProcess(const S: String): String;
 var
  M: Pointer;
 begin
  M:=umCreateMacros;
  AddDefaultMacros(M);
  SingleProcess:=umProcessMacro(M, S);
  umDestroyMacros(M);
 end;

function GetInfo: boolean;
 begin
  iArea:=sGetSemaphore(fileinfohost+'Area');
  iSenderName:=sGetSemaphore(fileinfohost+'Sender.Name');
  iSenderAddress:=sGetSemaphore(fileinfohost+'Sender.Address');
  iReceiverName:=sGetSemaphore(fileinfohost+'Receiver.Name');
  iReceiverAddress:=sGetSemaphore(fileinfohost+'Receiver.Address');
  iSubject:=sGetSemaphore(fileinfohost+'Subject');
  iTitle:=sGetSemaphore(fileinfohost+'Title');
  iTempFilename:=FExpand(sGetSemaphore(fileinfohost+'TempFilename'));
  iFilename:=Trim(sGetSemaphore(fileinfohost+'Filename'));
  iPacker:=StUpcase(sGetSemaphore(fileinfohost+'Packer'));
  iRepacker:=StUpcase(sGetSemaphore(fileinfohost+'Repacker'));
  iConvert:=sGetBoolSemaphore(fileinfohost+'Convert');
  iFileIdDizName:=sGetSemaphore(fileinfohost+'File_Id.Diz.Name');
  iFileIdDizLines:=sGetPtrSemaphore(fileinfohost+'File_Id.Diz.Lines');
  iFileIdDiz:=sGetBoolSemaphore(fileinfohost+'File_Id.Diz');
  iInfName:=sGetSemaphore(fileinfohost+'Inf.Name');
  iInfLines:=sGetPtrSemaphore(fileinfohost+'Inf.Lines');
  iInf:=sGetBoolSemaphore(fileinfohost+'Inf');
  iFileEcho:=sGetSemaphore('Hatcher.Fileecho');
  iTicName:=sGetSemaphore(fileechohost+'Tic.Name');
  iTicDir:=SingleProcess(AddBackSlash(FExpand(sGetSemaphore(fileechohost+'Tic.Dir'))));
  iTicLines:=sGetPtrSemaphore(fileechohost+'Tic.Lines');
  iInbound:=SingleProcess(AddBackSlash(FExpand(Trim(sGetSemaphore(fileechohost+'Inbound')))));
  iList:=sGetBoolSemaphore(fileinfoHost + 'List');
  if iList then
   iListFileName:=sGetSemaphore(fileinfoHost + 'List.FileName');

  iCheckDupes:=sGetBoolSemaphore(fileinfoHost + 'CheckDupes');
  iCheckDupesMemorize:=sGetBoolSemaphore(fileinfoHost + 'CheckDupes.Memorize');
  i83:=sGetBoolSemaphore(fileinfoHost + '83');

  GetInfo:=True;
 end;

function PrepareDirectory(Directory: String): boolean;
 begin
  if not mCleanDir(Directory) then
   begin
    lngBegin;
     lngPush(Directory);
     lngPrint('Main','Hatcher.CanNot.Clean');
    lngEnd;
    PrepareDirectory:=False;
   end
  else
   PrepareDirectory:=True;
 end;

function CopyFile(Source, Destination: String): boolean;
 var
  B1, B2: PDosStream;
 begin
  CopyFile:=False;
  Source:=FExpand(Source);
  Destination:=FExpand(Destination);
  mCreate(JustPathName(Source));
  mCreate(JustPathName(Destination));
  repeat
   B1:=New(PDosStream, Init(Source, stOpenRead));
   B2:=Nil;
   if B1^.Status<>stOk then
    begin
     lngBegin;
      lngPush(Source);
      lngPrint('Main','hatcher.copy.source.error');
     lngEnd;
     Break;
    end;
   B2:=New(PDosStream, Init(Destination, stCreate));
   if B2^.Status<>stOk then
    begin
     lngBegin;
      lngPush(Destination);
      lngPrint('Main','hatcher.copy.destination.error');
     lngEnd;
     Break;
    end;
   B2^.CopyFrom(B1^, B1^.GetSize);
   CopyFile:=True;
  until True;
  Dispose(B1, Done);
  if B2<>Nil then Dispose(B2, Done);
 end;

function KillFile(S: String): boolean;
 var
  F: File;
 begin
  InOutRes:=0;
  Assign(F, S);
  Erase(F);
  if InOutRes<>0 then
   begin
    lngBegin;
     lngPush(S);
     lngPush(HexL(IOResult));
     lngPrint('Main','hatcher.cannot.kill');
    lngEnd;
    KillFile:=False;
   end
  else
   KillFile:=True;
 end;

function WriteFile(S: PStrings; FName: String): boolean;
 var
  F: Text;
  K: Longint;
  P: Pointer;
  Z: String;
 begin
  WriteFile:=True;
  InOutRes:=0;
  Assign(F, FName);
  ReWrite(F);
  if InOutRes<>0 then
   begin
    lngBegin;
     lngPush(FName);
     lngPush(HexL(IOresult));
     lngPrint('Main','hatcher.cannot.create');
    lngEnd;
    WriteFile:=False;
    Exit;
   end;
  if S<>nil then
   begin
    P:=umCreateMacros;
    AddDefaultMacros(P);
    for K:=1 to cmCount(S) do
     begin
      Z:=GetPString(cmAt(S, K));
      Z:=umProcessMacro(P, Z);
      if not umEmptyLine(P) then WriteLn(F, Z);
     end;
    umDestroyMacros(P);
   end;
  Close(F);
  InOutRes:=0;
 end;

(*****************************************************************************)
(*****************************************************************************)
(*****************************************************************************)

procedure hfPack;
 var
  CmdLine, S: String;
 begin
  if not PrepareDirectory(tempRepackDir) then Exit;
  if aIsArchive(iFileName) or (not aExist(iPacker)) then Exit;
  S:=AddBackSlash(JustPathName(iTempFileName))+iFileName;
  if not CopyFile(iTempFileName, S) then Exit;
  if not aPackSingle(iPacker, tempRepackDir+ForceExtension(iFileName, aGetExtension(iPacker)), S) then
   begin
    KillFile(S);
    Error:=True;
    Exit;
   end;
  KillFile(S);
  if not CopyFile(tempRepackDir+ForceExtension(iFileName, aGetExtension(iPacker)), iTempFileName) then Exit;
  iFileName:=ForceExtension(iFileName, aGetExtension(iPacker));
  lngBegin;
   lngPush(iFileName);
   lngPush(iPacker);
   lngPrint('Main','hatcher.msm.packed');
  lngEnd;
 end;

procedure hfRepack;
 var
  S, Unpack, Pack: String;
 begin
  if (not aExist(iRepacker)) or (not iConvert) or (not aIsArchive(iFileName)) then Exit;
  if Trim(StUpcase(aGetExtension(iRepacker)))=stUpcase(Trim(JustExtension(iFilename))) then
   begin
    lngPrint('Main','hatcher.msm.repack.eq');
    Exit;
   end;
  if not PrepareDirectory(tempRepackDir) then Exit;
  if not aUnpackAll(aSearchArchiver(justExtension(iFilename)), iTempFileName, tempRepackDir) then Exit;
  if not KillFile(iTempFileName) then Exit;
  if not aPackAll(iRepacker, iTempFileName, tempRepackDir) then Exit;
  PrepareDirectory(tempRepackDir);
  iFileName:=ForceExtension(iFileName, aGetExtension(iRepacker));
  lngBegin;
   lngPush(iFilename);
   lngPush(iRepacker);
   lngPrint('Main','filesbbs.msm.repacked');
  lngEnd;
 end;

procedure hfPackInf;
 var
  S: String;
 begin
  if (not iInf) then Exit;
  if not PrepareDirectory(tempRepackDir) then Exit;
  if aSearchArchiver(JustExtension(iFilename))='' then Exit;
  if not WriteFile(iInfLines, tempRepackDir+iInfName) then Exit;
  if not aPackSingle(aSearchArchiver(JustExtension(iFilename)), iTempFileName, tempRepackDir+iInfName) then Exit;
  if not KillFile(tempRepackDir+iInfName) then Exit;
  lngBegin;
   lngPush(iInfName);
   lngPush(aSearchArchiver(JustExtension(iFileName)));
   lngPrint('Main','hatcher.msm.inf.packed');
  lngEnd;
 end;

procedure hfPackFileIdDiz;
 var
  S: String;
 begin
  if not iFileIdDiz then Exit;
  if aSearchArchiver(JustExtension(iFilename))='' then Exit;
  if not PrepareDirectory(tempRepackDir) then Exit;
  if not WriteFile(iFileIdDizLines, tempRepackDir+iFileIdDizName) then Exit;
  if not aPackSingle(aSearchArchiver(JustExtension(iFileName)), iTempFileName, tempRepackDir+iFileIdDizName) then Exit;
  if not KillFile(tempRepackDir+iFileIdDizName) then Exit;
  lngBegin;
   lngPush(iFileIdDizName);
   lngPush(aSearchArchiver(JustExtension(iFilename)));
   lngPrint('Main', 'hatcher.msm.file_id.diz.packed');
  lngEnd;
 end;

procedure hfMakeTic;
 var
  K: Byte;
  L: Longint;
  S: String;
 begin
  if iTicName='' then Exit;
  CRC:=uGetCRC(iTempFilename);
  L:=0;
  mCreate(iTicDir);
  if not ExistDir(iTicDir) then
   begin
    lngBegin;
     lngPush(iTicDir);
     lngPrint('Main','hatcher.cannot.create.dir');
    lngEnd;
    Exit;
   end;
  repeat
   Inc(L);
   if L>16384 then
    begin
     lngBegin;
      lngPush(iTicName);
      lngPrint('Main', 'hatcher.tic.unable');
     lngEnd;
     Error:=true;
     Exit;
    end;
   S:=uGetUnique(iTicName);
   if not ExistFile(iTicDir+S) then Break;
  until False;
  if not WriteFile(iTicLines, iTicDir + S) then Exit;
  lngBegin;
   lngPush(iTicDir + S);
   lngPrint('Main','hatcher.msm.tic');
  lngEnd;
 end;

procedure hfPlaceFile;
 begin
  if iInbound='' then Exit;
  mCreate(iInbound);
  if not ExistDir(iInbound) then
   begin
    lngBegin;
    lngPush(iInbound);
    lngPrint('Main','hatcher.wrong.inbound');
    lngEnd;
    Exit;
   end;
  if not CopyFile(iTempFileName, iInbound+iFilename) then Exit;
  lngBegin;
   lngPush(iInbound + iFileName);
   lngPrint('Main','hatcher.msm.saved');
  lngEnd;
 end;

procedure hfUpdateList;
 var
  F: Text;
 begin
  if not iList then Exit;
  if iInbound = '' then Exit;
  {$I-}
  if IOResult <> 0 then;
  iListFileName:=SingleProcess(iListFileName);
  mCreate(JustPathName(iListFileName));
  Assign(F, iListFileName);
  Append(F);
  if IOResult <> 0 then ReWrite(F);
  if InOutRes <> 0 then
   begin
    lngBegin;
     lngPush(iListFileName);
     lngPush(Long2Str(IOResult));
     lngPrint('Main', 'error.cant.create');
    lngEnd;
    Exit;
   end;
  WriteLn(F, iInbound + iFilename);
  Close(F);
  lngBegin;
   lngPush(iListFilename);
   lngPrint('Main','hatcher.msm.list.updated');
  lngEnd;
 end;

procedure hfCheckDupes;
 var
  S: String;
  Encountered: Boolean;
 begin
  if not iCheckDupes then Exit;

  ComprehensiveDupeChecking(iFilename, 0, 0, fsgName, _83 or i83, S, Encountered, False);

  if iFileName <> S then
   begin
    lngBegin;
     lngPush(iFileName);
     lngPush(S);
     lngPrint('Main', 'hatcher.msm.renamed');
    lngEnd;

    iFileName:=S;
   end;

  if iCheckDupesMemorize then
   filesAddSpool(S, GetFileSize(iTempFileName), uGetCRC(iTempFileName));
 end;

function HatchFile: Longint;
 begin
  Crc:=0;
  HatchFile:=srhOk;
  Error:=False;

  if not GetInfo then
   begin
    HatchFile:=srhWrongInfo;
    Exit;
   end;

  lngBegin;
   lngPush(iFileName);
   lngPush(iArea);
   lngPrint('Main','hatcher.msm.start');
  lngEnd;

  hfPack;
  hfRepack;
  hfPackInf;
  hfPackFileIdDiz;

  hfCheckDupes;

  hfMakeTic;
  hfPlaceFile;
  hfUpdateList;

  lngPrint('Main','hatcher.msm.done');

  sSetSemaphore('Hatcher.FeedBack.FileName', iFileName);
 end;

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint; {$IFNDEF SOLID}export;{$ENDIF}
 begin
  Service:=srYes;
  case ServiceNumber of
   snAfterStartup:
    begin
     mCheckPlugin('HATCHER', 'ARCHIVER');
     mCheckPlugin('HATCHER', 'USER');
    end;
   snStartup:
    begin
     tempRepackDir:=cGetParam('Hatcher.Repack.Directory');
     mCreate(tempRepackDir);
     if not ExistDir(tempRepackDir) then
      begin
       lngPrint('Main','Hatcher.Bad.Repack.Dir');
       Service:=srNo;
       sSetExitNow;
       Exit;
      end;
     tempRepackDir:=AddBackSlash(tempRepackDir);
     tempRepackDirNoSlash:=tempRepackDir;
     if (tempRepackDirNoSlash[Length(tempRepackDirNoSlash)]='\') and (tempRepackDirNoSlash[0]<>#3) then
      Dec(tempRepackDirNoSlash[0]);
     sSetSemaphore('Hatcher.Loaded','Yes');
     sSetSemaphore('Hatcher.Info.Version',Version2Str(hatVersion));
    end;
   snQueryName: sSetSemaphore('Kernel.Plugins.Info.Name','HATCHER');
   snQueryAuthor: sSetSemaphore('Kernel.Plugins.Info.Author','sergey korowkin');
   snQueryVersion: Service:=hatVersion;
   snQueryReqVer: Service:=kernelVersion;
   snhHatchFile: Service:=HatchFile;
   snCommandLine:;
  else
   Service:=srNotSupported;
  end;
 end;

{$IFNDEF SOLID}
exports
 Service;

begin
{$ENDIF}
end.
