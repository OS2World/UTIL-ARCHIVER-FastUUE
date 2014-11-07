;
; ฎโซ คฎ็ญ ๏ ชฎญไจฃใp ๆจ๏ :)
;
;ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
[Main]

include file rexx.ctl

Purchased Yes
Purchased.By sergey korowkin

Groups Groups.Configuration

Gate.Charset xlt\koi8r.xlt
Gate.Reverse Yes

MsgOut.Max.Message.Size 16384

dob.List Kill
dob.List Add 0,0,Dob.1

Twit.Enabled Yes

include file macros.ctl

Log (TheLog)
Log.Flush Yes

Debug.Config No
Debug.Semaphores No
Debug.Showhole Yes
Debug.Scan.DoNtKill Yes
Debug.Uue.DoNtKill Yes
Debug.Resource No
Debug.Language No

Announcer.Enabled Yes

Exec.Quiet No

Logo.Disable 2:5030/15.409

Language Kill
Language Add (DirLanguage)\*.lng

include file plugins.ctl

Resource.FileName (DirResource)\FastUUE.Res
Resource.Pack No
Resource.Pack.Step 1
Resource.TempFileName (DirTemp)\FastUUE.R!s

include block settings

include file scan.ctl

Archivers Kill
Archivers Add ARJ
Archivers Add HA
Archivers Add RAR
Archivers Add ZIP

Files.Database (DirData)\Filebase.Dat

Filesbbs.Repack.Directory (DirTemp)\Repack.BBS\

Hatcher.Repack.Directory (DirTemp)\Repack.HAT\

include file icq_em.ctl
include file uue.ctl
include file stuff.ctl
include file archiver.ctl
include file groups.ctl
include file twit1.ctl
include file twit_.ctl
include file dob1.ctl
include file crax.ctl
include file newstat.ctl
