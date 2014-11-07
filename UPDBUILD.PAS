{&Use32+}
uses Dos, Wizard;

var
 F: Text;
 Date, Build: String;
 K: Longint;
 Year, Month, Day, Dow: Word;
begin
 {$I-}
 Assign(F, 'date.inc');
 Reset(F);
 ReadLn(F, Date);
 ReadLn(F, Date);
 ReadLn(F, Build);
 Close(F);
 Delete(Build, 1, 26);
 Dec(Build[0]);
 Str2Longint(Build, K);
 Inc(K);
 GetDate(Year, Month, Day, Dow);
 Date:=' __DATE__               = '''+LeftPadCh(Long2Str(Day), '0', 2)+'/'+
                                     +LeftPadCh(Long2Str(Month), '0', 2)+'/'+
                                     +LeftPadCh(Long2Str(Year), '0', 4)+''';';
 Build:=' __BUILD__              = '+Long2Str(K)+';';
 Rewrite(F);
 WriteLn(F, 'const');
 WriteLn(F, Date);
 WriteLn(F, Build);
 Close(F);
end.
