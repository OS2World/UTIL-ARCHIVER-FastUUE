const
 snanCheck              = $00006000;
 snanProcessAnnounce    = $00006001;

function annCheck: boolean;
 begin
  annCheck:=srvExecute('ANNOUNCER', snanCheck, nil) = srYes;
 end;

function annProcessAnnounce: longint;
 begin
  annProcessAnnounce:=srvExecute('ANNOUNCER', snanProcessAnnounce, nil);
 end;
