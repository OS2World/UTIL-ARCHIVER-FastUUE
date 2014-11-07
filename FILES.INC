const
 snfilCheck             = $00006100;
 snfilAdd               = $00006101;
 snfilAddSpool          = $00006102;
 snfilFlushSpool        = $00006103;

 fsgName                = $00000001;
 fsgCRC                 = $00000002;
 fsgSize                = $00000004;

function filesOk: boolean;
 begin
  filesOk:=pSearch('FILES') <> nil;
 end;

function filesCheck(const Name: String; const Size, CRC, Strategy: Longint): boolean;
 begin
  sSetSemaphore('Files.FileName', Name);
  sSetSemaphore('Files.Size', Long2Str(Size));
  sSetSemaphore('Files.CRC', Long2Str(CRC));
  sSetSemaphore('Files.Strategy', Long2Str(Strategy));

  filesCheck:=srvExecute('FILES', snfilCheck, nil) = srYes;
 end;

procedure filesAdd(const Name: String; const Size, CRC: Longint);
 begin
  sSetSemaphore('Files.FileName', Name);
  sSetSemaphore('Files.Size', Long2Str(Size));
  sSetSemaphore('Files.CRC', Long2Str(CRC));

  srvExecute('FILES', snfilAdd, nil);
 end;

procedure filesAddSpool(const Name: String; const Size, CRC: Longint);
 begin
  sSetSemaphore('Files.FileName', Name);
  sSetSemaphore('Files.Size', Long2Str(Size));
  sSetSemaphore('Files.CRC', Long2Str(CRC));

  srvExecute('FILES', snfilAddSpool, nil);
 end;

procedure filesFlushSpool;
 begin
  srvExecute('FILES', snfilFlushSpool, nil);
 end;
