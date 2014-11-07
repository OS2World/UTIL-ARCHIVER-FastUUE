unit Consts_;

interface

const
 diTempDivisionIdentifier       = $00000666;

const
(* Service Numbers *)
 snNone                      = $00000000;
 snStartup                   = $00000001;
 snShutdown                  = $00000002;
 snQueryName                 = $00000003;
 snQueryAuthor               = $00000004;
 snQueryVersion              = $00000005;
 snQueryReqVer               = $00000006;
 snStopThreads               = $00000007;
 snResumeThreads             = $00000008;
 snStart                     = $00000100;
 snCommandLine               = $00000101;
 snAfterStartup              = $00000102;
 snKillHDD                   = $00000666; { ;-) }
 snHangSystem                = $00000667; { ;-) }

 ssGetLogs                   = $000000001;
 ssOpenLog                   = $000000002;
 ssCloseLog                  = $000000003;

 srNo                        = $00000000;
 srYes                       = $00000001;
 srKillEm                    = $00000666;
 srNotSupported              = $FFFFFFFF;

 KernelVersion               = $00160000;

 cplUpCase                   = $00000001;
 cplLoCase                   = $00000002;

 {$IFDEF DPMI}
 LFN                         = False;
 _83                         = True;
 {$ELSE}
 LFN                         = True;
 _83                         = False;
 {$ENDIF}

implementation

end.
