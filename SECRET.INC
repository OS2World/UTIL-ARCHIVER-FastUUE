type
 TGetLogsProc = function(const LogName, LogFName: String): Longint;
 TVideoService = function(const ServiceNumber: Longint; const _Number: Byte; const _String: String): byte;

type
 PSecretStuff = ^TSecretStuff;
 TSecretStuff = record
  VideoService: Pointer;
  ExecService: Pointer;
  ShowHole: Boolean;
  OldAttr: Byte;
 end;
