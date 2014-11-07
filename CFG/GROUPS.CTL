[Groups.Configuration]

Begin
 Name basic.definitions
 Desc Основные опpеделения
 Areas Kill

 uue.Scan.Disabled No
 uue.Kill KeepFirst
 uue.Cut Yes

 uue.Skip.Cut.Areas Kill
 uue.Remain.Cut.Areas Kill
 uue.Skip.Cut.Address Kill
 uue.Remain.Cut.Address Kill

 uue.inf.exclude.lines Kill
 uue.inf.exclude.lines Add *
 uue.inf.exclude.lines Add SEEN-BY*
 uue.inf.exclude.lines Add AREA:*
 uue.inf.remain.lines Kill
 uue.inf.remain.lines Add MSGID*
 uue.inf.header replacefile (DirTemplate)\Header.UUE
 uue.inf.center replacefile (DirTemplate)\Center.UUE
 uue.inf.footer replacefile (DirTemplate)\Footer.UUE
 uue.inf replacefile (DirTemplate)\Inf.UUE

 uue.Decode.Disabled No
 uue.KeepDays 100
 uue.Kill.Bad Yes

 uue.put Yes
 uue.put.filesbbs yes
 uue.put.filesbbs.name Files.Bbs
 uue.put.filesbbs.directory (DirUUE)\@8.3echo
 uue.put.filesbbs.lines replacefile (DirTemplate)\FilesBBS.TPL
 uue.put.directory (DirUUE)\@8.3echo
 uue.put.packer
 uue.put.repacker RAR
 uue.put.fileiddiz yes
 uue.put.fileiddiz.name file_id.diz
 uue.put.fileiddiz.lines replacefile (DirTemplate)\FileIdDz.tpl
 uue.put.inf yes
 uue.put.inf.pack yes
 uue.put.inf.name Read!Me.Plz
 uue.put.inf.directory (DirUUE)\@8.3echo
 uue.put.list yes
 uue.put.list.filename (DirUUE)\@8.3echo\$new$.lst
 uue.put.DirDesc yes
 uue.put.DirDesc.FileName Files.BBS
 uue.put.DirDesc.Lines ReplaceFile (DirTemplate)\DirDesc.Tpl
 uue.put.checkdupes yes
 uue.put.checkdupes.memorize yes
 uue.put.83 yes

 uue.hatch No
 uue.hatch.packer
 uue.hatch.repacker
 uue.hatch.inf yes
 uue.hatch.inf.name FastUUE.INF
 uue.hatch.fileiddiz yes
 uue.hatch.fileiddiz.name file_id.diz
 uue.hatch.fileiddiz.lines ReplaceFile (DirTemplate)\FileIdDz.fpl
 uue.hatch.fileecho AFTNFASTUUE
 uue.hatch.tic.name f*******.tic
 uue.hatch.tic.directory (DirUUE)\INBOUND.HAT\
 uue.hatch.tic.lines ReplaceFile (DirTemplate)\Tic.Fpl
 uue.hatch.inbound (DirUUE)\INBOUND.HAT\
 uue.hatch.list yes
 uue.hatch.list.filename (DirUUE)\INBOUND\hatched.lst
 uue.hatch.checkdupes yes
 uue.hatch.checkdupes.memorize yes
 uue.hatch.83 yes

 uue.CheckDupes no
 uue.CheckDupes.Memorize No

 uue.Announce No
 uue.Announcer.Enabled Yes
 uue.Announcer.Type Packet
 uue.Announcer.Name Ann*****.Pkt
 uue.Announcer.Header ReplaceFile (dirtemplate)\annhead.tpl
 uue.Announcer.Footer ReplaceFile (dirtemplate)\annfoot.tpl
 uue.Announcer.Directory E:\Engine\FastUUE\Out.PKT
 uue.Announcer.Area.Type Echomail
 uue.Announcer.Area.Name POWER.ANNOUNCES
 uue.Announcer.Msg.Source 2:5033/27.0,FastUUE
 uue.Announcer.Msg.Target 2:5033/27.0,All
 uue.Announcer.Msg.Subject new warez came here -- "@filename" [@size] (c) SfY... ;
 uue.Announcer.Pkt.Source 2:5033/27.0
 uue.Announcer.Pkt.Target 2:5033/27.0
 uue.Announcer.Pkt.Password FASTUUE
 uue.Announcer.Pkt.Single Yes
 uue.Announcer.Flag (DirFlags)\Arcmail

 uue.List.Announce Yes
 uue.List.Announcer.Enabled Yes
 uue.List.Announcer.Header ReplaceFile (DirTemplate)\AnnList.Hpl
 uue.List.Announcer.Center ReplaceFile (DirTemplate)\AnnList.Cpl
 uue.List.Announcer.Footer ReplaceFile (DirTemplate)\AnnList.Fpl
 uue.List.Announcer.Type Packet
 uue.List.Announcer.Name Ann*****.Pkt
 uue.List.Announcer.Directory E:\Engine\FastUUE\Out.PKT
 uue.List.Announcer.Area.Type Echomail
 uue.List.Announcer.Area.Name POWER.ANNOUNCES
 uue.List.Announcer.Msg.Source 2:5033/27.0,FastUUE
 uue.List.Announcer.Msg.Target 2:5033/27.0,All
 uue.List.Announcer.Msg.Subject [дубль 2] new warez came here (q) SfY! lezen2me! ;-)
 uue.List.Announcer.Pkt.Source 2:5033/27.0
 uue.List.Announcer.Pkt.Target 2:5033/27.0
 uue.List.Announcer.Pkt.Password FASTUUE
 uue.List.Announcer.Pkt.Single Yes
 uue.List.Announcer.Origin (MacroOrigin)
 uue.List.Announcer.SystemName (MacroSystemName)
 uue.List.Announcer.SysopName (MacroSysopName)
 uue.List.Announcer.SystemAddress (MacroSystemAddress)
 uue.List.Announcer.Merge Kill
; uue.List.Announcer.Flag \Arcmail

 uue.83 Yes
End

Begin
 Inherite Basic.Definitions
 Name Other
 Desc Пpочие
 Areas Replace *
 uue.Put.Directory (DirUUE)\OTHER\@8.3echo

 Twit.Enabled Yes
 Twit.Extended Replace Twit.Extended.1
End

