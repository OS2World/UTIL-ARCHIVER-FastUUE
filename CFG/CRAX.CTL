[crax.1]
crax.xck.id kill
crax.xck.id add ? description
crax.xck.id add ?? description
crax.xck.id add ??? description
crax.xck.id add ? crack subject
crax.xck.id add ?? crack subject
crax.xck.id add ??? crack subject
crax.xck.id add ? what is it
crax.xck.id add ?? what is it
crax.xck.id add ??? what is it
crax.xck.id add ? program name
crax.xck.id add ?? program name
crax.xck.id add ??? program name

crax.Temp Temp\Crax\cracked.elk
crax.CheckDupes Yes
crax.CheckDupes.Memorize no
crax.Cut Yes

 crax.BadFiles No
 ; если Yes, то кряки с ошибками будут дампиться в каталог crax.BadFiles.Dir 
 crax.BadFiles.Dir Debug\BadFiles\
 ; каталог для дампов
 crax.BadFiles.83 No
 ; Приводить BadFiles к формату 8.3?
 crax.BadFiles.Serial Yes
 ; Если No, то файл дампа с тем же именем переписывает старый


[crax.2]
begin
 name common
 desc common!
 areas kill

 crax.Disabled No
 crax.83 Yes
 crax.CheckDupes.Memorize no
 crax.CheckDupes Yes

 crax.Skip.Cut.Areas Kill
 crax.Remain.Cut.Areas Kill

 crax.Skip.Cut.Address Kill
 crax.Remain.Cut.Address Kill

 crax.inf.exclude.lines Kill
 crax.inf.remain.lines Kill

 crax.inf.header replacefile (DirTemplate)\crax\Header.crx
 crax.inf.center replacefile (DirTemplate)\crax\Center.crx
 crax.inf.footer replacefile (DirTemplate)\crax\Footer.crx
 crax.inf replacefile (DirTemplate)\crax\Inf.crx

 crax.put No
 crax.put.filesbbs Yes
 crax.put.filesbbs.name Files.Bbs
 crax.put.filesbbs.directory crax\@8.3echo
 crax.put.filesbbs.lines replacefile (DirTemplate)\crax\FilesBBS.TPL
 crax.put.directory crax\@8.3echo
 crax.put.inf Yes
 crax.put.inf.name anothersux.inf
 crax.put.inf5.directory crax\@8.3echo
 crax.put.list Yes
 crax.put.list.filename crax\@8.3echo\$new$.lst
 crax.put.dirdesc Yes
 crax.put.dirdesc.FileName dirz.BBS
 crax.put.dirdesc.Lines ReplaceFile (DirTemplate)\crax\DirDesc.Tpl
 crax.put.checkdupes yes
 crax.put.checkdupes.memorize yes
 crax.put.83 yes

 crax.hatch Yes
 crax.hatch.fileecho VL.craXX
 crax.hatch.tic.name f*******.tic
 crax.hatch.tic.directory (DirUUE)\INBOUND\
 crax.hatch.tic.lines ReplaceFile (DirTemplate)\crax\Tic.Fpl

 crax.hatch.inbound (DirUUE)\INBOUND\
 crax.hatch.list yes
 crax.hatch.list.filename (DirUUE)\INBOUND\@8.3echo\!new.lst
 crax.hatch.checkdupes yes
 crax.hatch.checkdupes.memorize yes
 crax.hatch.83 yes


 crax.Announce No
 crax.Announcer.Enabled Yes
 crax.Announcer.Type Packet
 crax.Announcer.Name Ann*****.Pkt
 crax.Announcer.Header ReplaceFile (dirtemplate)\crax\annhead.tpl
 crax.Announcer.Footer ReplaceFile (dirtemplate)\crax\annfoot.tpl
 crax.Announcer.Directory E:\Engine\FastUUE\Out.PKT
 crax.Announcer.Area.Type Echomail
 crax.Announcer.Area.Name POWER.ANNOUNCES
 crax.Announcer.Msg.Source 2:5033/27.0,FastUUE
 crax.Announcer.Msg.Target 2:5033/27.0,All
 crax.Announcer.Msg.Subject new warez came here -- "@filename" [@size] (c) SfY... ;
 crax.Announcer.Pkt.Source 2:5033/27.0
 crax.Announcer.Pkt.Target 2:5033/27.0
 crax.Announcer.Pkt.Password FASTUUE
 crax.Announcer.Pkt.Single Yes
 crax.Announcer.Flag (DirFlags)\Arcmail

 crax.List.Announce Yes
 crax.List.Announcer.Enabled Yes
 crax.List.Announcer.Header ReplaceFile (DirTemplate)\Crax\AnnList.Hpl
 crax.List.Announcer.Center ReplaceFile (DirTemplate)\Crax\AnnList.Cpl
 crax.List.Announcer.Footer ReplaceFile (DirTemplate)\Crax\AnnList.Fpl
 crax.List.Announcer.Type Packet
 crax.List.Announcer.Name Ann*****.Pkt
 crax.List.Announcer.Directory E:\Engine\FastUUE\Out.PKT
 crax.List.Announcer.Area.Type Echomail
 crax.List.Announcer.Area.Name POWER.ANNOUNCES
 crax.List.Announcer.Msg.Source 2:5033/27.0,FastUUE
 crax.List.Announcer.Msg.Target 2:5033/27.0,All
 crax.List.Announcer.Msg.Subject [дубль 2] new warez came here (q) SfY! lezen2me! ;-)
 crax.List.Announcer.Pkt.Source 2:5033/27.0
 crax.List.Announcer.Pkt.Target 2:5033/27.0
 crax.List.Announcer.Pkt.Password FASTUUE
 crax.List.Announcer.Pkt.Single Yes
 crax.List.Announcer.Origin (MacroOrigin)
 crax.List.Announcer.SystemName (MacroSystemName)
 crax.List.Announcer.SysopName (MacroSysopName)
 crax.List.Announcer.SystemAddress (MacroSystemAddress)
 crax.List.Announcer.Flag (DirFlags)\Arcmail
end

begin
 inherite common
 name netmail
 desc muaha
 areas replace NETMAIL

 crax.List.Announcer.Msg.Subject !netmail!
end

begin
 inherite common
 name others
 desc jopa!
 areas replace *

 crax.List.Announcer.Msg.Subject !other!

 crax.List.Announcer.Merge Replace netmail
end

