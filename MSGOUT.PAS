{$IFDEF SOLID}
unit MsgOut;

interface

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint;

implementation
{$ELSE}
library MsgOut;
{$ENDIF}

{$IFDEF VIRTUALPASCAL}
uses Types, Consts_, Log, Video, Wizard, Misc, Language, Config, Resource,
     Plugins, Semaphor;
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
 msgoutVersion   = $00010400;

{$i msgout.inc}
{$i common.inc}
{$i fastuue.inc}

var
 iType          : longint;
 iName          : String;
 iPathname      : String;
 iMessageData   : PStrings;
 iAreaTag       : String;
 iAreaType      : Longint;
 iMessageFromA  : TAddress;
 iMessageToA    : TAddress;
 iMessageFrom   : String;
 iMessageTo     : String;
 iMessageSubj   : String;
 ipktFrom       : TAddress;
 ipktTo         : TAddress;
 ipktPassword   : String;
 iFlag          : String;
 iSinglePacket  : Boolean;
 iStripStuff    : Boolean;
 MaxMessageSize : Longint;

function GetInfo: boolean;
 var
  S: String;
 begin
  GetInfo:=False;
  S:=StUpcase(Trim(sGetSemaphore('post.Format')));
  if S[0]=#0 then Exit;
  case S[1] of
   'T': iType:=itTextFile;
   'F': iType:=itTextFile;
   'P': iType:=itPktFile;
  else
   Exit;
  end;
  iName:=Trim(sGetSemaphore('post.Name'));
  iPathName:=AddBackSlash(FExpand(Trim(sGetSemaphore('post.PathName'))));
  iAreaTag:=Trim(sGetSemaphore('post.Area.Tag'));
  S:=StUpcase(Trim(sGetSemaphore('post.Area.Type')));
  if S[0] = #0 then Exit;
  case S[1] of
   'E': iAreaType:=iaEchoMail;
   'N': iAreaType:=iaNetMail;
  else
   Exit;
  end;
  S:=Ltrim(sGetSemaphore('post.Msg.From'));
  Str2Address(ExtractWord(1, S, [',']), iMessageFromA);
  iMessageFrom:=GetAllAfterChar(S, 1, ',');
  S:=Ltrim(sGetSemaphore('post.Msg.To'));
  Str2Address(ExtractWord(1, S, [',']), iMessageToA);
  iMessageTo:=GetAllAfterChar(S, 1, ',');
  iMessageSubj:=sGetSemaphore('post.Msg.Subj');
  Str2Address(Trim(sGetSemaphore('post.pkt.From')), ipktFrom);
  Str2Address(Trim(sGetSemaphore('post.pkt.To')), ipktTo);
  ipktPassword:=StUpcase(Trim(sGetSemaphore('post.pkt.Password')));
  iFlag:=StUpcase(Trim(sGetSemaphore('post.Flag')));
  iSinglePacket:=sGetBoolSemaphore('post.pkt.SinglePacket');
  iStripStuff:=sGetBoolSemaphore('post.pkt.StripStuff');
  mCreate(iPathname);
  GetInfo:=True;
 end;

function Post_TextFile: longint;
 var
  F: Text;
  K: Longint;
  S: String;
 begin
  {$I-}
  Assign(F, iPathName + iName);
  Append(F);
  if IOResult<>0 then ReWrite(F);
  if IOResult<>0 then
   begin
    Post_TextFile:=srmoIOerror;
    Exit;
   end;
  for K:=1 to cmCount(iMessageData) do
   begin
    S:=GetPString(cmAt(iMessageData, K));
    WriteLn(F, S);
    if IOResult<>0 then
     begin
      Post_TextFile:=srmoIOerror;
      Close(F);
      Exit;
     end;
   end;
  Close(F);
  Post_TextFile:=srYes;
 end;

type
 TPKTHeader    = record
  OrigNode     : system.word;
  DestNode     : system.word;
  Year         : system.word;
  Month        : system.word;
  Day          : system.word;
  Hour         : system.word;
  Minute       : system.word;
  Second       : system.word;
  Rate         : system.word;
  Version      : system.word;
  OrigNet      : system.word;
  DestNet      : system.word;
  PCodeLo      : system.byte;
  PRevMajor    : system.byte;
  Password     : array[1..8] of system.char;
  QMOrigZone   : system.word;
  QMDestZone   : system.word;
  AuxNet       : system.word;
  CWValidate   : system.word;
  PCodeHi      : system.byte;
  PRevMinor    : system.byte;
  CWCapWord    : system.word;
  OrigZone     : system.word;
  DestZone     : system.word;
  OrigPoint    : system.word;
  DestPoint    : system.word;
  LongData     : system.longint;
 end;

 TPktMessage = record
  magic        : system.word;
  origNode     : system.word;
  destNode     : system.word;
  origNet      : system.word;
  destNet      : system.word;
  Attribute    : system.word;
  cost         : system.word;
 end;

procedure Check(var S: String);
 var
  K: Byte;
 begin
  for K:=1 to Length(S) do
   case S[K] of
    #0: S[K]:=#32;
    #141: S[K]:=#72;
   end;
 end;

const
 SinglePacketOpened: Boolean = False;
 SinglePacketCount: Longint = 0;
var
 SinglePacket: PStream;

procedure CloseSinglePacket;
 var
  W: Word;
 begin
  W:=0;
  SinglePacket^.Write(W, SizeOf(W));
 end;

function Post_PktFile: longint;
 var
  Packet: PStream;
  PktHead: TPktHeader;
  PktMsg: TPktMessage;
  W: System.Word;
  B: System.Byte;
  K: Longint;
  Error: Boolean;
 procedure _write(S: String);
  begin
   Check(S);
   B:=0;
   Packet^.Write(S[1], Length(S));
   Packet^.Write(B, SizeOf(B));
  end;
 procedure _writeln(S: String);
  begin
   Check(S);
   B:=13;
   Packet^.Write(S[1], Length(S));
   Packet^.Write(B, SizeOf(B));
  end;
 function OpenPacket: Longint;
  begin
   OpenPacket:=srYes;
   if iSinglePacket then
    if (not SinglePacketOpened) then
     begin
      SinglePacket:=New(PBufStream, Init(iPathName + iName, stCreate, 2048));
      if SinglePacket^.Status <> stOk then
       begin
        Post_PktFile:=srmoIOerror;
        Dispose(SinglePacket, Done);
        Error:=True;
        Exit;
       end;
      Packet:=SinglePacket;
      SinglePacketOpened:=True;
     end
    else
     Packet:=SinglePacket
   else
    begin
     Packet:=New(PBufStream, Init(iPathName + iName, stCreate, 2048));
     if Packet^.Status <> stOk then
      begin
       OpenPacket:=srmoIOerror;
       Dispose(Packet, Done);
       Error:=True;
       Exit;
      end;
    end;
  end;
 procedure ClosePacket;
  begin
   if iSinglePacket then
    Packet^.Flush
   else
    begin
     W:=0;
     Packet^.Write(W, SizeOf(W));
     Dispose(Packet, Done);
    end;
  end;
 var
  RepeatPost: Boolean;
  S: String;
  Size: Longint;
 begin
  Error:=False;
  Post_PktFile:=OpenPacket;
  if Error then Exit;

  repeat
   if iSinglePacket then
    begin
     Inc(SinglePacketCount);
     if SinglePacketCount <> 1 then Break;
    end;

   ipktPassword:=Copy(ipktPassword, 1, 8);
   while Length(ipktPassword) < 8 do ipktPassword:=ipktPassword + #0;

   FillChar(pktHead, SizeOf(pktHead), 0);
   FillChar(pktMsg, SizeOf(pktMsg), 0);

   with PktHead do
    begin
     OrigNode:=ipktFrom.Node;
     DestNode:=ipktTo.Node;
     iWannaDate(Day, Month, Year);
     iWannaTime(Hour, Minute, Second);
     Rate:=0;
     Version:=2;
     OrigNet:=ipktFrom.Net;
     DestNet:=ipktTo.Net;
     PCodeLo:=0;
     PRevMajor:=0;
     Move(ipktPassword[1], Password, 8);
     QMOrigZone:=ipktFrom.Zone;
     QMDestZone:=ipktTo.Zone;
     AuxNet:=0;
     CWValidate:=$100;
     PCodeHi:=0;
     PRevMinor:=0;
     CWCapWord:=1;
     OrigZone:=ipktFrom.Zone;
     DestZone:=ipktTo.Zone;
     OrigPoint:=ipktFrom.Point;
     DestPoint:=ipktTo.Point;
     LongData:=0;
    end;
   Packet^.Write(PktHead, SizeOf(PktHead));
  until True;

  with PktMsg do
   begin
    magic:=2;
    origNode:=iMessageFromA.Node;
    destNode:=iMessageToA.Node;
    origNet:=iMessageFromA.Net;
    destNet:=iMessageToA.Net;
    attribute:=0;
    cost:=0;
   end;

  K:=0;
  repeat
   Packet^.Write(PktMsg, SizeOf(PktMsg));
   _Write(GetPktDateTime);
   _Write(iMessageTo);
   _Write(iMessageFrom);
   _Write(iMessageSubj);
   if not iStripStuff then
    begin
     if iAreaType = iaNetmail then
       begin
        _WriteLn('INTL ' + ExtractWord(1, Address2Str(iMessageFromA), ['.']) + ' ' +
         ExtractWord(1, Address2Str(iMessageToA), ['.']));
        if iMessageFromA.Point <> 0 then
         _WriteLn('FMPT ' + Long2Str(iMessageFromA.Point));
        if iMessageToA.Point <> 0 then
         _WriteLn('TOPT ' + Long2Str(iMessageToA.Point));
       end
     else
      _WriteLn('AREA:' + iAreaTag);
     _WriteLn('MSGID: ' + Address2Str(iMessageFromA) + ' ' + uGetMSGiD);
     _WriteLn('PID: FastUUE/' + OS_Short + ' v' + sGetSemaphore('Kernel.Version') + ' (c) sk');
    end;

   RepeatPost:=False;
   Size:=0;
   repeat
    Inc(K);
    if K > cmCount(iMessageData) then Break;
    GetPStringEx(cmAt(iMessageData, K), S);

    if not iStripStuff then
     ReplaceEx(S, '@originaddr', Address2StrTrim(iMessageFromA));

    _WriteLn(S);

    Inc(Size, Length(S) + 1);

    if (Size > MaxMessageSize) and (not iStripStuff) then
     begin
      _WriteLn('--- FastUUE/' + OS_Short + ' ' + sGetSemaphore('Kernel.Version') + ' (c) by sergey korowkin, 1999.');
      _WriteLn(' * Origin: http://www.mart.ru/~fidonet/fastuue/ (' + Address2StrTrim(iMessageFromA) + ')');

      RepeatPost:=True;
      Break;
     end;
   until False;

   B:=0;
   Packet^.Write(B, SizeOf(B));
   if not RepeatPost then Break;
  until False;

  ClosePacket;
 end;

function Unique: boolean;
 var
  S: String;
  K: Longint;
 begin
  K:=0;
  repeat
   S:=uGetUnique(iName);
   Inc(K);
   if K=1024 then
    begin
     Unique:=False;
     Exit;
    end;
  until not ExistFile(iPathName+S);
  Unique:=True;
  iName:=S;
 end;

function IsNeedUnique:boolean;
 var I:Longint;
 begin
  IsNeedUnique:=false;
  for I:=1 to length(iName) do
   if (iName[I]='*') or (iName[I]='$') or (iName[I]='#') then
   begin
    IsNeedUnique:=true;
    Break;
   end;
 end;

function Post: longint;
 begin
  iMessageData:=sGetPtrSemaphore('post.Data');
  if not GetInfo then
   begin
    Post:=srmoWrongInfo;
    Exit;
   end;
  case iType of

   itTextFile: begin
                if IsNeedUnique then if not Unique then begin 
                                                         Post:=srmoNotUnique;
                                                         Exit;
                                                        end;
                Post:=Post_TextFile;
               end;
   itPktFile:  if not Unique then Post:=srmoNotUnique else Post:=Post_PktFile;
  end;
  uCreateFlag(iFlag);
 end;

procedure Shutdown;
 begin
  if SinglePacketOpened then
   begin
    CloseSinglePacket;
    Dispose(SinglePacket, Done);
   end;
 end;

function SERVICE(ServiceNumber: Longint; Buffer: Pointer): Longint; {$IFNDEF SOLID}export;{$ENDIF}
 begin
  Service:=srYes;
  case ServiceNumber of
   snStartup:
    begin
     if cGetParam('MsgOut.Max.Message.Size') = '' then
      MaxMessageSize:=16384
     else
      begin
       MaxMessageSize:=cGetNumParam('MsgOut.Max.Message.Size');
       if MaxMessageSize < 1024 then MaxMessageSize:=1024;
       if MaxMessageSize > 32768 then MaxMessageSize:=32768;
      end;
    end;
   snAfterStartup:
    begin
     mCheckPlugin('MSGOUT', 'USER');
    end;
   snShutdown: Shutdown;
   snQueryName: sSetSemaphore('Kernel.Plugins.Info.Name','MSGOUT');
   snQueryAuthor: sSetSemaphore('Kernel.Plugins.Info.Author','sergey korowkin');
   snQueryVersion: Service:=msgoutVersion;
   snQueryReqVer: Service:=kernelVersion;
   snmoCheck:;
   snmoGetVersion: Service:=msgoutVersion;
   snmoPost: Service:=Post;
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
