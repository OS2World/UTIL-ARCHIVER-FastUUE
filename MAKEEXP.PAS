uses wizard, 
{$IFDEF VIRTUALPASCAL}
crt;
{$else}
crt_p2;
{$endif}

var
 I,O: Text;
 S, C: String;
 Ok: Boolean;
 Count: Longint;
begin
 write('Generating...');
 {$I-}
 Assign(I,'decl.pas');
 Assign(O,'exports.inc');
 Reset(I);
 ReWrite(O);

 Count:=0;

 Ok:=False;
 WriteLn(O,'exports');
 Ok:=False;
 C:='';
 while not eof(I) do
  begin
   ReadLn(I,S);
   if S='{begin}' then Ok:=True else
   if S='{end}' then Ok:=False else
   if not Ok then Continue;
   S:=ExtractWord(2,S,[' ',':','(',';']);
   if S='' then Continue;
   if C<>'' then
    begin
     WriteLn(O,' ',C,',');
     Inc(Count);
     C:='';
    end;
   C:=S;
  end;
 WriteLn(O,' ',C,';');
 Inc(Count);

 Close(I);
 Close(O);
 InOutRes:=0;
 writeln(' done.'#13#10);
 WriteLn('Total API entries: ',Count);
end.