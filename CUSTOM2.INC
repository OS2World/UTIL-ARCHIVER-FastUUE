function QueryPluginService(const FName: String): Pointer; Far;
 begin
  if FName = 'COMMON.DLL'   then QueryPluginService:=@Common.Service else
  if FName = 'UUE.DLL'   then QueryPluginService:=@Uue.Service else
  if FName = 'CRAX.DLL'   then QueryPluginService:=@Crax.Service else
  if FName = 'FILESBBS.DLL'   then QueryPluginService:=@FilesBBS.Service else
  if FName = 'HATCHER.DLL'   then QueryPluginService:=@Hatcher.Service else
  if FName = 'FILES.DLL'   then QueryPluginService:=@Files.Service else
  if FName = 'EMAIL.DLL'   then QueryPluginService:=@EMail.Service else
  if FName = 'ICQ.DLL'   then QueryPluginService:=@ICQ.Service else
  if FName = 'ARCHIVER.DLL'   then QueryPluginService:=@Archiver.Service else
  if FName = 'SCAN.DLL'   then QueryPluginService:=@Scan.Service else
   QueryPluginService:=Nil;
 end;
