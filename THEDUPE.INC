{
 comprehensive dupe-checking algorithm(tm) for fastuue
 (q) by sk // [rAN], 1999.

 dedicated to Vera Pletneva, 2:5051/28@fidonet.
}
procedure ComprehensiveDupeChecking(OriginalFileName: String;
                                    const OriginalSize, OriginalCRC, Flags: Longint;
                                    const _83: Boolean;
                                    var S: String; var Encountered: Boolean;
                                    const EncounteringPossible: Boolean);
 var
  CounteR: Longint;
 begin
  S:=OriginalFileName;

  Encountered:=False;
  Counter:=0;

  repeat
   if not filesCheck(S, 0, 0, fsgName) then
    Break;

   if filesCheck(S, OriginalSize, OriginalCRC, Flags) and EncounteringPossible then
    begin
     Encountered:=True;
     Break;
    end;

   Inc(Counter);

   S:=uChangeFilename(OriginalFileName, Counter, _83);
  until False;
 end;
