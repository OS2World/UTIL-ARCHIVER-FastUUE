unit Core;

interface
uses
{$IFDEF VIRTUALPASCAL}
     Misc, Video,
{$ENDIF}

{$IFDEF DPMI}
{$IFDEF SOLID}
     Misc, Video,
{$ELSE}
     Decl,
{$ENDIF}
{$ENDIF}
     Wizard, Types;

function CheckForMask(const S: String; Masks: PStrings): Boolean;
function xCheckForMask(S: String; Masks: PStrings): Boolean;
function Check2Masks(S: String; Exclude, Remain: PStrings):Boolean;

function CheckForZero(const Number: Longint): String;

implementation

function CheckForMask(const S: String; Masks: PStrings): Boolean;
 var
  K: Longint;
 begin
  for K:=1 to cmCount(Masks) do
   if mCheckWildCard(S, GetPString(cmAt(Masks, K))) then
    begin
     CheckForMask:=True;
     Exit;
    end;
  CheckForMask:=False;
 end;

function xCheckForMask(S: String; Masks: PStrings): Boolean;
 var
  K: Longint;
  D: PString;
  T: String;
 begin
  TrimEx(S);
  StUpCaseEx(S);
  for K:=1 to cmCount(Masks) do
   begin
    D:=cmAt(Masks, K);
    if (D = Nil) and (S[0] = #0) then
     begin
      xCheckForMask:=True;
      Exit;
     end;
    T:=D^;
    TrimEx(T);
    StUpcaseEx(T);
    if mCheckWildCard(S, T) then
     begin
      xCheckForMask:=True;
      Exit;
     end;
   end;
  xCheckForMask:=False;
 end;

function Check2Masks(S: String; Exclude, Remain: PStrings):Boolean;
var B:boolean;
begin
 B:=not xCheckForMask(S, Exclude);
 if not B then B:= xCheckForMask(S, Remain);
 Check2Masks:=B;
end;

function CheckForZero(const Number: Longint): String;
 begin
  if Number = 0 then
   CheckForZero:='?'
  else
   CheckForZero:=Long2Str(Number);
 end;

end.