{$IFDEF SOLID}
unit FilesBBS;

interface

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint;

implementation
{$ELSE}
library FilesBBS;
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

const
 bbsVersion     = $00010600;

var
 iArea: String;
 iSenderName: String;
 iReceiverName: String;
 iSenderAddress: String;
 iReceiverAddress: String;
 iSubject: String;
 iBBSLines: PStrings;
 iTempFilename: String;
 iFilename: String;
 iDirFilename: String;
 iFilesBBS: String;
 iDirFilesBBS: String;
 iPacker: String;
 iRepacker: String;
 iFileIdDizName: String;
 iFileIdDizLines: PStrings;
 iFileIdDiz: Boolean;
 iInfName: String;
 iInfLines: PStrings;
 iInf: Boolean;
 iInfDir: String;
 iConvert: Boolean;
 iPackInf: Boolean;
 iList: Boolean;
 iListFileName: String;
 iDirDesc: Boolean;
 iDirDescFileName: String;
 iDirDescLines: PStrings;
 iTitle: String;
 Error: Boolean;
 tempRepackDir: String;
 tempRepackDirNoSlash: String;
 iCheckDupes, iCheckDupesMemorize, i83: Boolean;

{$I FILESBBS.INC}
{$I ARCHIVER.INC}
{$I COMMON.INC}
{$I FILES.INC}
{$I THEDUPE.INC}

const
 Host = 'FilesBBS.FileInfo.';

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
  umAddMacro(M, '@subject', iSubject);
  umAddMacro(M, '@sender.name', iSenderName);
  umAddMacro(M, '@sender.address', iSenderAddress);
  umAddMacro(M, '@receiver.name', iReceiverName);
  umAddMacro(M, '@receiver.address', iReceiverAddress);
  umAddMacro(M, '@title', iTitle);
 end;

function SingleProcess(S: String): String;
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
  iArea:=sGetSemaphore(Host+'Area');
  iSenderName:=sGetSemaphore(Host+'Sender.Name');
  iSenderAddress:=sGetSemaphore(Host+'Sender.Address');
  iReceiverName:=sGetSemaphore(Host+'Receiver.Name');
  iReceiverAddress:=sGetSemaphore(Host+'Receiver.Address');
  iSubject:=sGetSemaphore(Host+'Subject');
  iBBSLines:=sGetPtrSemaphore(Host+'BBSLines');
  iTempFilename:=FExpand(sGetSemaphore(Host+'TempFilename'));
  iFilename:=Trim(sGetSemaphore(Host+'Filename'));
  iDirFilename:=SingleProcess(sGetSemaphore(Host+'DirFilename'));
  iFilesBBS:=Trim(sGetSemaphore(Host+'FilesBBS'));
  iDirFilesBBS:=SingleProcess(sGetSemaphore(Host+'DirFilesBBS'));
  iPacker:=StUpcase(sGetSemaphore(Host+'Packer'));
  iRepacker:=StUpcase(sGetSemaphore(Host+'Repacker'));
  iConvert:=sGetBoolSemaphore(Host+'Convert');
  iPackInf:=sGetBoolSemaphore(Host+'PackInf');
  iFileIdDizName:=sGetSemaphore(Host+'File_Id.Diz.Name');
  iFileIdDizLines:=sGetPtrSemaphore(Host+'File_Id.Diz.Lines');
  iFileIdDiz:=sGetBoolSemaphore(Host+'File_Id.Diz');
  iInfName:=sGetSemaphore(Host+'Inf.Name');
  iInfLines:=sGetPtrSemaphore(Host+'Inf.Lines');
  iInf:=sGetBoolSemaphore(Host+'Inf');
  if sGetSemaphore(Host+'Inf.Dir')<>'' then
   iInfDir:=SingleProcess(AddBackSlash(FExpand(sGetSemaphore(Host+'Inf.Dir'))))
  else
   iInfDir:='';
  if iDirFilesBBS='' then
   iDirFilesBBS:=iDirFilename;
  iList:=sGetBoolSemaphore(Host + 'List');
  if iList then
   iListFileName:=sGetSemaphore(Host + 'List.FileName');
  iDirDesc:=sGetBoolSemaphore(Host + 'DirDesc');
  iDirDescFileName:=sGetSemaphore(Host + 'DirDesc.FileName');
  iDirDescLines:=sGetPtrSemaphore(Host + 'DirDesc.Lines');

  iCheckDupes:=sGetBoolSemaphore(Host + 'CheckDupes');
  iCheckDupesMemorize:=sGetBoolSemaphore(Host + 'CheckDupes.Memorize');
  i83:=sGetBoolSemaphore(Host + '83');

  iTitle:=sGetSemaphore(Host + 'Title');
  GetInfo:=True;
 end;

function PrepareDirectory(Directory: String): boolean;
 begin
  if not mCleanDir(Directory) then
   begin
    lngBegin;
    lngPush(Directory);
    lngPrint('Main','FilesBBS.CanNot.Clean');
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
  Source:=FExpand(Source);
  Destination:=FExpand(Destination);
  mCreate(JustPathName(Source));
  mCreate(JustPathName(Destination));
  CopyFile:=False;
  repeat
   B1:=New(PDosStream, Init(Source, stOpenRead));
   B2:=Nil;
   if B1^.Status<>stOk then
    begin
     lngBegin;
     lngPush(Source);
     lngPrint('Main','filesbbs.copy.source.error');
     lngEnd;
     Break;
    end;
   B2:=New(PDosStream, Init(Destination, stCreate));
   if B2^.Status<>stOk then
    begin
     lngBegin;
     lngPush(Destination);
     lngPrint('Main','filesbbs.copy.destination.error');
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
    lngPush(Long2Str(IOResult));
    lngPrint('Main','filesbbs.cannot.kill');
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
    lngPush(Long2Str(IOresult));
    lngPrint('Main','filesbbs.cannot.create');
    lngEnd;
    WriteFile:=False;
    Exit;
   end;
  P:=umCreateMacros;
  AddDefaultMacros(P);
  for K:=1 to cmCount(S) do
   begin
    Z:=GetPString(cmAt(S, K));
    Z:=umProcessMacro(P, Z);
    if not umEmptyLine(P) then WriteLn(F, Z);
   end;
  umDestroyMacros(P);
  Close(F);
  InOutRes:=0;
 end;

(*****************************************************************************)
(*****************************************************************************)
(*****************************************************************************)

procedure pfPack;
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
  lngPrint('Main','filesbbs.msm.packed');
  lngEnd;
 end;

procedure pfRepack;
 var
  S, Unpack, Pack: String;
 begin
  if (not aExist(iRepacker)) or (not iConvert) or (not aIsArchive(iFileName)) then Exit;
  if Trim(StUpcase(aGetExtension(iRepacker)))=stUpcase(Trim(JustExtension(iFilename))) then
   begin
    lngPrint('Main','filesbbs.msm.repack.eq');
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

procedure pfPackInf;
 var
  S: String;
 begin
  if (not iPackInf) or (not iInf) then Exit;
  if not PrepareDirectory(tempRepackDir) then Exit;
  if aSearchArchiver(JustExtension(iFilename))='' then Exit;
  if not WriteFile(iInfLines, tempRepackDir+iInfName) then Exit;
  if not aPackSingle(aSearchArchiver(JustExtension(iFilename)), iTempFileName, tempRepackDir+iInfName) then Exit;
  if not KillFile(tempRepackDir+iInfName) then Exit;
  lngEnd;
  lngBegin;
  lngPush(iInfName);
  lngPush(aSearchArchiver(JustExtension(iFileName)));
  lngPrint('Main','filesbbs.msm.inf.packed');
  lngEnd;
 end;

procedure pfPackFileIdDiz;
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
  lngPrint('Main', 'filesbbs.msm.file_id.diz.packed');
  lngEnd;
 end;

procedure pfPlaceInf;
 var
  S: String;
 begin
  if (not iInf) or (iInfDir = '') then Exit;

  mCreate(iInfDir);

  if not ExistDir(iInfDir) then
   begin
    lngBegin;
    lngPush(iInfDir);
    lngPrint('Main','filesbbs.inf.wrong.dir');
    lngEnd;
    Exit;
   end;

  S:=JustFileNameOnly(iFileName) + '.' + JustExtension(iInfName);

  if not WriteFile(iInfLines, iInfDir + S) then Exit;

  lngBegin;
   lngPush(iInfDir + S);
   lngPrint('Main','filesbbs.msm.inf.saved');
  lngEnd;
 end;

procedure pfMakeFilesBBS;
 var
  S: String;
  F: Text;
  K: Longint;
  P: Pointer;
 begin
  if (iFilesBBS = '') or (iDirFilesBBS = '') then Exit;

  iDirFilesBBS:=AddBackSlash(iDirFilesBBS);

  mCreate(iDirFilesBBS);

  if not ExistDir(iDirFilesBBS) then
   begin
    lngBegin;
     lngPush(iDirFilesBBS);
     lngPrint('Main','filesbbs.bbs.wrong.dir');
    lngEnd;
    Exit;
   end;

  {$I-}
  if IOResult <> 0 then;
  Assign(F, iDirFilesBBS + iFilesBBS);
  Append(F);
  if IOResult <> 0 then Rewrite(F);

  if InOutRes <> 0 then
   begin
    lngBegin;
     lngPush(iDirFilesBBS + iFilesBBS);
     lngPush(Long2Str(IOResult));
     lngPrint('Main','filesbbs.bbs.cannot.create');
    lngEnd;
    Exit;
   end;

  P:=umCreateMacros;
  AddDefaultMacros(P);
  for K:=1 to cmCount(iBBSLines) do
   begin
    S:=GetPString(cmAt(iBBSLines, K));
    S:=umProcessMacro(P, S);
    if not umEmptyLine(P) then WriteLn(F, S);
   end;
  umDestroyMacros(P);

  Close(F);

  lngBegin;
   lngPush(iDirFilesBBS + iFilesBBS);
   lngPrint('Main', 'filesbbs.msm.bbs.updated');
  lngEnd;
 end;

procedure pfPlaceFile;
 begin
  if iDirFilename='' then Exit;

  iDirFilename:=AddBackSlash(Trim(iDirFilename));

  mCreate(iDirFilename);

  if not ExistDir(iDirFilename) then
   begin
    lngBegin;
    lngPush(iDirFilename);
    lngPrint('Main','filesbbs.file.wrong.dir');
    lngEnd;
    Exit;
   end;

  if not CopyFile(iTempFileName, iDirFilename + iFilename) then
   Exit;

  lngBegin;
   lngPush(iDirFileName + iFileName);
   lngPrint('Main','FilesBBS.msm.file.saved');
  lngEnd;
 end;

procedure pfUpdateList;
 var
  F: Text;
 begin
  if (not iList) or (iDirFilename = '') then Exit;

  {$I-}
  if IOResult <> 0 then;

  iListFileName:=SingleProcess(iListFileName);

  mCreate(JustPathName(iListFileName));

  Assign(F, iListFileName);
  Append(F);

  if IOResult <> 0 then
   ReWrite(F);

  if InOutRes <> 0 then
   begin
    lngBegin;
     lngPush(iListFileName);
     lngPush(Long2Str(IOResult));
     lngPrint('Main', 'error.cant.create');
    lngEnd;
    Exit;
   end;

  WriteLn(F, iDirFilename + iFilename);
  Close(F);

  lngBegin;
   lngPush(iListFilename);
   lngPrint('Main','FilesBBS.msm.list.updated');
  lngEnd;
 end;

procedure pfUpdateDir;
 var
  S, D: String;
  A: PString;
  F: Text;
  M: Pointer;
  K: Longint;
 begin
  if not iDirDesc then Exit;
  if iDirDescFileName = '' then Exit;
  if iDirFileName = '' then Exit;
  if Length(iDirFileName) = 3 then Exit;
  if not mHasCreated(iDirFilename) then Exit;

  S:='FilesBBS\' + StUpcase(FExpand(iDirFilename)) + '\Updated';

  if sGetBoolSemaphore(S) then Exit;

  sSetSemaphore(S, 'Yes');

  S:=RemoveBackSlash(iDirFileName);
  S:=JustPathName(S);
  S:=AddBackSlash(S) + iDirDescFileName;

  {$I-}
  Assign(F, S);
  Append(F);
  if IOResult <> 0 then ReWrite(F);
  if InOutRes <> 0 then
   begin
    lngBegin;
    lngPush(S);
    lngPush(Long2Str(IOResult));
    lngPrint('Main', 'error.cant.create');
    lngEnd;
    Exit;
   end;
  M:=umCreateMacros;
  AddDefaultMacros(M);
  umAddMacro(M, '@directory', JustFileName(RemoveBackSlash(iDirFileName)));
  for K:=1 to cmCount(iDirDescLines) do
   begin
    GetPStringEx(cmAt(iDirDescLines, K), D);
    D:=umProcessMacro(M, D);
    if not umEmptyLine(M) then
     WriteLn(F, D);
   end;
  umDestroyMacros(M);
  Close(F);
  if IOResult <> 0 then;

  lngBegin;
   lngPush(S);
   lngPrint('Main','FilesBBS.msm.dirdesc.updated');
  lngEnd;
 end;

procedure pfCheckDupes;
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
     lngPrint('Main', 'filesbbs.msm.renamed');
    lngEnd;

    iFileName:=S;
   end;

  if iCheckDupesMemorize then
   filesAddSpool(S, GetFileSize(iTempFileName), uGetCRC(iTempFileName));
 end;

function PutFile: Longint;
 begin
  PutFile:=srfOk;
  Error:=False;
  if not GetInfo then
   begin
    PutFile:=srfWrongInfo;
    Exit;
   end;

  {*}
  lngBegin;
   lngPush(iFileName);
   lngPush(iArea);
   lngPrint('Main','filesbbs.msm.start');
  lngEnd;
  {*}

  pfPack;
  pfRepack;
  pfPackInf;
  pfPackFileIdDiz;
  pfCheckDupes;
  pfPlaceInf;
  pfMakeFilesBBS;
  pfPlaceFile;
  pfUpdateDir;
  pfUpdateList;
  lngPrint('Main','FilesBBS.msm.done');

  sSetSemaphore('FilesBBS.FeedBack.FileName', iFileName);
 end;

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint; {$IFNDEF SOLID}export;{$ENDIF}
 begin
  Service:=srYes;
  case ServiceNumber of
   snAfterStartup:
    begin
     mCheckPlugin('FILESBBS', 'ARCHIVER');
     mCheckPlugin('FILESBBS', 'USER');
    end;
   snStartup:
    begin
     tempRepackDir:=cGetParam('FilesBBS.Repack.Directory');
     mCreate(tempRepackDir);
     if not ExistDir(tempRepackDir) then
      begin
       lngPrint('Main','FilesBBS.Bad.Repack.Dir');
       Service:=srNo;
       sSetExitNow;
       Exit;
      end;
     tempRepackDir:=AddBackSlash(tempRepackDir);
     tempRepackDirNoSlash:=tempRepackDir;
     if (tempRepackDirNoSlash[Length(tempRepackDirNoSlash)]='\') and (tempRepackDirNoSlash[0]<>#3) then
      Dec(tempRepackDirNoSlash[0]);
     sSetSemaphore('FilesBBS.Loaded','Yes');
     sSetSemaphore('FilesBBS.Info.Version',Version2Str(bbsVersion));
    end;
   snQueryName: sSetSemaphore('Kernel.Plugins.Info.Name','FILESBBS');
   snQueryAuthor: sSetSemaphore('Kernel.Plugins.Info.Author','sergey korowkin');
   snQueryVersion: Service:=bbsVersion;
   snQueryReqVer: Service:=kernelVersion;
   snfPutFile: Service:=PutFile;
   snCommandLine:;
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
