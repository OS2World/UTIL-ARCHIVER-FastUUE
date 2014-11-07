{$IFDEF SOLID}
unit Announce;

interface

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint;

implementation
{$ELSE}
library Announce;
{$ENDIF}

{$IFDEF VIRTUALPASCAL}
uses Types, Consts_, Log, Video, Wizard, Misc, Language, Config,
     Plugins, Semaphor;
{$IFNDEF SOLID}
{$Dynamic MAIN.LIB}
{$ENDIF}
{$ENDIF}

{$IFDEF DPMI}
uses
{$IFDEF SOLID}
     Plugins, Semaphor, Language, Misc, Config,
{$ELSE}
     Decl,
{$ENDIF}
     Types, Consts_, Wizard, Dos, Macroz;
{$ENDIF}


const
 announceVersion     = $00010700;

{$I ANNOUNCE.INC}
{$I COMMON.INC}
{$I FASTUUE.INC}
{$I MSGOUT.INC}

var
 iLines: PStrings;
 iArea: String;
 iSenderName: String;
 iReceiverName: String;
 iSenderAddress: String;
 iReceiverAddress: String;
 iSubject: String;
 iFileName: String;
 iFileEcho: String;
 iFileDirectory: String;
 iFileSize: Longint;
 iType: Byte;
 iName: String;
 iHeader: PStrings;
 iFooter: PStrings;
 iDirectory: String;
 iSinglePacket: Boolean;
 iMode: Longint;
 iTitle: String;
 iFileNameFilesBBS: String;
 iFileNameHatcher: String;

 aID: String;

 G: PStrings;

procedure GetInfo;
 begin
  iLines:=sGetPtrSemaphore('Announcer.Lines');
  iArea:=sGetSemaphore('Announcer.Area');
  iSenderName:=sGetSemaphore('Announcer.Sender.Name');
  iSenderAddress:=sGetSemaphore('Announcer.Sender.Address');
  iReceiverName:=sGetSemaphore('Announcer.Receiver.Name');
  iReceiverAddress:=sGetSemaphore('Announcer.Receiver.Address');
  iSubject:=sGetSemaphore('Announcer.Subject');
  iFileName:=sGetSemaphore('Announcer.FileName');
  iFileSize:=sGetNumSemaphore('Announcer.FileSize');
  iFileEcho:=sGetSemaphore('Announcer.FileEcho');
  iFileDirectory:=FExpand(Trim(sGetSemaphore('Announcer.FileDirectory')));
  iMode:=sGetNumSemaphore('Announcer.Mode');
  G:=sGetPtrSemaphore('Announcer.Group');
  aID:=sGetSemaphore('Announcer.Prefix');
  iTitle:=sGetSemaphore('Announcer.Title');
  iFileNameFilesBBS:=sGetSemaphore('Announcer.FileName.FilesBBS');
  iFileNameHatcher:=sGetSemaphore('Announcer.FileName.Hatcher');
 end;

const
 itUnknown = 0;
 itFile = 1;
 itPacket = 2;
var
 M: Pointer;
 Target: PStrings;

procedure PutWithMacros(Src: PStrings);
 var
  K: Longint;
  S: String;
 begin
  for K:=1 to cmCount(Src) do
   begin
    S:=umProcessMacro(M, GetPString(cmAt(Src, K)));
    if not umEmptyLine(M) then cmInsert(Target, cmNewStr(S));
   end;
 end;

procedure PutNormal(Src: PStrings);
 var
  K: Longint;
  S: String;
 begin
  for K:=1 to cmCount(Src) do
   begin
    S:=uInvalidateLine(GetPString(cmAt(Src, K)));
    cmInsert(Target,cmNewStr(S));
   end;
 end;

procedure Put(Src: PStrings);
 var
  K: Longint;
  S: String;
 begin
  for K:=1 to cmCount(Src) do
   begin
    S:=GetPString(cmAt(Src, K));
    cmInsert(Target,cmNewStr(S));
   end;
 end;

var
 S: String;
 K: Longint;
 F: Text;

function ProcessAnnounce: longint;
 function Check(const Param, Value: String): String;
  begin
   if Param = '' then
    Check:=Value
   else
    Check:=Param;
  end;
 begin
  ProcessAnnounce:=srYes;
  GetInfo;
  if iMode <> 3 then
   begin
    G:=gSearchByArea(iArea);
    if G = Nil then
     begin
      lngBegin;
      lngPush(iArea);
      lngPrint('Main', 'announce.unknown.group');
      lngEnd;
      ProcessAnnounce:=srNo;
      Exit;
     end;
   end;
  if not gGetBoolParam(G, aID + 'Announcer.Enabled') then Exit;
  if not cGetBoolParam('Announcer.Enabled') then Exit;
  S:=Trim(StUpcase(gGetParam(G, aID + 'Announcer.Type'))) + ' ';
  case S[1] of
   'F': iType:=itFile;
   'T': iType:=itFile;
   'P': iType:=itPacket;
  else
   lngBegin;
   lngPush(gGetParam(G, 'Name'));
   lngPrint('Main', 'announce.bad.type');
   lngEnd;
   ProcessAnnounce:=srNo;
   Exit;
  end;
  iDirectory:=AddBackSlash(FExpand(Trim(gGetParam(G, aID + 'Announcer.Directory'))));
  mCreate(iDirectory);
  iName:=gGetParam(G, aID + 'Announcer.Name');
  cmCreateStrings(Target);
  M:=umCreateMacros;
  umAddMacro(M, '@filename', StUpcase(iFileName));
  umAddMacro(M, '@size', Long2Str(iFileSize));
  umAddMacro(M, '@echo', iArea);
  umAddMacro(M, '@8.3echo', u83echo(iArea));
  umAddMacro(M, '@fileecho', iFileEcho);
  umAddMacro(M, '@dirslash', AddBackSlash(iFileDirectory));
  umAddMacro(M, '@dir', RemoveBackSlash(iFileDirectory));
  umAddMacro(M, '@subject', iSubject);
  umAddMacro(M, '@sender.name', iSenderName);
  umAddMacro(M, '@sender.address', iSenderAddress);
  umAddMacro(M, '@receiver.name', iReceiverName);
  umAddMacro(M, '@receiver.address', iReceiverAddress);
  umAddMacro(M, '@systemorigin', gGetParam(G, aID + 'Announcer.Origin'));
  umAddMacro(M, '@systemname', Check(gGetParam(G, aID + 'Announcer.SystemName'), 'Dummy Zyztem'));
  umAddMacro(M, '@sysopname', Check(gGetParam(G, aID + 'Announcer.SysopName'), 'Another Lammah'));
  umAddMacro(M, '@systemaddress', Check(gGetParam(G, aID + 'Announcer.SystemAddress'), '2:5030/15.0'));
  umAddMacro(M, '@title', iTitle);
  umAddMacro(M, '@ffilename', iFileNameFilesBBS);
  umAddMacro(M, '@hfilename', iFileNameHatcher);
  if iMode = 1 then
   begin
    cmCreateStrings(iHeader);
    cmCreateStrings(iFooter);
    gProcessList(G, aID + 'Announcer.Header', iHeader);
    gProcessList(G, aID + 'Announcer.Footer', iFooter);
    PutWithMacros(iHeader);
    PutNormal(iLines);
    PutWithMacros(iFooter);
   end;
  if iMode <> 1 then
   PutWithMacros(iLines);
  case iType of
   itFile: sSetSemaphore('post.Format', 'Text');
   itPacket: sSetSemaphore('post.Format', 'Pkt');
  end;
  sSetSemaphore('post.Name', iName);
  sSetSemaphore('post.PathName', iDirectory);
  sSetSemaphore('post.Area.Tag', gGetParam(G, aID + 'Announcer.Area.Name'));
  sSetSemaphore('post.Area.Type', gGetParam(G, aID + 'Announcer.Area.Type'));
  sSetSemaphore('post.Msg.From', umProcessMacro(M, gGetParam(G, aID + 'Announcer.Msg.Source')));
  sSetSemaphore('post.Msg.To', umProcessMacro(M, gGetParam(G, aID + 'Announcer.Msg.Target')));
  sSetSemaphore('post.Msg.Subj', umProcessMacro(M, gGetParam(G, aID + 'Announcer.Msg.Subject')));
  sSetSemaphore('post.Flag', gGetParam(G, aID + 'Announcer.Flag'));
  sSetSemaphore('post.Data', HexPtr(Target));
  sSetSemaphore('post.pkt.From', gGetParam(G, aID + 'Announcer.Pkt.Source'));
  sSetSemaphore('post.pkt.To', gGetParam(G, aID + 'Announcer.Pkt.Target'));
  sSetSemaphore('post.pkt.Password', gGetParam(G, aID + 'Announcer.Pkt.Password'));
  sSetSemaphore('post.pkt.SinglePacket', gGetParam(G, aID + 'Announcer.Pkt.Single'));
  sSetSemaphore('post.pkt.StripStuff', 'No');
  if iSinglePacket then
   sSetSemaphore('post.SinglePacket', 'Yes')
  else
   sSetSemaphore('post.SinglePacket', 'No');
  ProcessAnnounce:=moPost;
  if iMode = 1 then
   begin
    cmDisposeObject(iHeader);
    cmDisposeObject(iFooter);
   end;
  umDestroyMacros(M);
  cmDisposeObject(Target);
  lngBegin;
  lngPush(iFileName);
  if iMode = 1 then
   lngPrint('Main', 'announce.done');
  lngEnd;
 end;

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint; {$IFNDEF SOLID}export;{$ENDIF}
 begin
  Service:=srYes;
  case ServiceNumber of
   snStartup:;
   snAfterStartup:
    begin
     mCheckPlugin('ANNOUNCER', 'MSGOUT');
     mCheckPlugin('ANNOUNCER', 'USER');
    end;
   snShutdown:;
   snQueryName: sSetSemaphore('Kernel.Plugins.Info.Name', 'ANNOUNCER');
   snQueryAuthor: sSetSemaphore('Kernel.Plugins.Info.Author', 'sergey korowkin');
   snQueryVersion: Service:=announceVersion;
   snQueryReqVer: Service:=kernelVersion;
   snanCheck: Service:=srYes;
   snanProcessAnnounce: Service:=ProcessAnnounce;
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
