var
 Stuff: TSecretStuff;

{$IFDEF VIRTUALPASCAL}
var
 LeakFixed: Longint;

procedure Leaker(const Start: Boolean);
 begin
  if Start then
   LeakFixed:=MemUsed
  else
   if Stuff.ShowHole then
    begin
     vSetAttr($0C);
     vPrint('    In asshole ');
     vSetAttr($0F);
     vPrint(Long2StrFmt(LeakFixed - MemUsed));
     vSetAttr($0C);
     vPrint(' bytes.');
     vSetAttr(Stuff.OldAttr);
     vPrintLn('');
    end;
 end;
{$ELSE}
procedure Leaker(const Start: Boolean);
 begin
 end;
{$ENDIF}
