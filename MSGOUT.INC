const
 snmoCheck        = $00006200;
 snmoGetVersion   = $00006201;
 snmoPost         = $00006222;

 srmoWrongInfo    = $00006010;
 srmoNotSupported = $00006021;
 srmoIOerror      = $00006022;
 srmoNotUnique    = $00006023;

 itTextFile       = $00000001; {filename, dir}
 itPktFile        = $00000002; {filename, dir, areatype, pktfrom, pktto, pktpwd}
 itJamBase        = $00000003;
 itSquishBase     = $00000004;
 itMsgBase        = $00000005;

 iaNetmail        = $00000001;
 iaEchomail       = $00000002;
{
 semaphores
 ~~~~~~~~~~
*(required fields)*
 post.Format pkt | text(file)
 post.Name ********[macros here].pkt
 post.PathName inbound.loc\
 post.Area.Tag Ru.FASTUUE
 post.Area.Type Echomail | Netmail
 post.Msg.From 2:5033/27.0,Sergey Korowkin
 post.Msg.To 2:5033/27.0,All
 post.Msg.Subj New FASTUUE released!
 post.Flag flags\posted!.flg | absent, created with 'uCreateFlag' (common.dll)
 post.Data hexptr(msgdata) (created with cmCreateStrings)
*(post.pkt.* required only for .pkt-posting)*
 post.pkt.From 2:5033/27.0
 post.pkt.To 2:5033/27.0
 post.pkt.Password YOU_KNOW
}

function moCheck: boolean;
 begin
  moCheck:=srvExecute('MSGOUT', snmoCheck, nil) = srYes;
 end;

function moGetVersion: longint;
 begin
  moGetVersion:=srvExecute('MSGOUT', snmoGetVersion, nil);
 end;

function moPost: longint;
 begin
  moPost:=srvExecute('MSGOUT', snmoPost, nil);
 end;