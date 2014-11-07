uses OS2base;
var
 l: longint;
 k: longint;
begin
 randomize;
 for k:=1 to random(100)+1 do
  l:=random(2500);
 dossleep(1500+l);
end.
