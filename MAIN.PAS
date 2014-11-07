{$C FIXED PRELOAD PERMANENT}
{$S-,R-,I-,Q-}
{$IFDEF WIN32}
library Main32;
{$ELSE}
{$IFDEF OS2}
library Main2;
{$ELSE}
library Main;
{$ENDIF}
{$ENDIF}

uses Types, Consts_, Vars, Video, Config, Semaphor, Log,
     Language, Startup, Plugins, Misc, Resource, Division;

{$IFDEF SOLID}
äÄäéÉé ïÖêÄ?
{$ENDIF}

{$IFDEF VIRTUALPASCAL}
{$EXPORT Video, Config, Semaphor, Log, Language, Startup, Plugins, Misc, Resource, Division}
{$ELSE}
exports
 StartupProc;
{$I EXPORTS.INC}
{$ENDIF}

begin
end.
