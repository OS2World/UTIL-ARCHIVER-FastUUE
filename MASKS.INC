function CheckForMask(S: String; Ss: PStrings): Boolean;
 var
  K: Longint;
 begin
  CheckForMask:=False;
  for K:=1 to cmCount(Ss) do
   if mCheckWildCard(S, GetPString(cmAt(Ss, K))) then
    begin
     CheckForMask:=True;
     Exit;
    end;
 end;

function xCheckForMask(S: String; Ss: PStrings): Boolean;
 var
  K: Longint;
 begin
  xCheckForMask:=False;
  S:=Trim(StUpcase(S));
  for K:=1 to cmCount(Ss) do
   if mCheckWildCard(S, Trim(StUpcase(GetPString(cmAt(Ss, K))))) then
    begin
     xCheckForMask:=True;
     Exit;
    end;
 end;

