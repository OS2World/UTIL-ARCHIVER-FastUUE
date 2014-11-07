uses
     Wizard,
{$IFDEF VIRTUALPASCAL}
     Crt;
{$Else}
     Crt_p2;
{$EndIf}

var ALL:boolean;

function YesNo(S:String; Default:Boolean):Boolean;
var c:char;
    r:Boolean;
begin
 write(S);
 if All then 
 begin
  writeln('(y,n,A): Y');
  YesNo:=true;
  exit;
 end;

 if Default then write('(Y,n,a): ')
            else write('(y,N,a): ');

 repeat
  c:=readkey;
 until (c='y')or(c='Y')or(c='n')or(c='N')or(c=#13)or(c='a')or(c='A');

 if c=#13 then r:=Default else
  if (c='Y') or (c='y') then r:=true else
   if (c='N') or (c='n') then r:=false;
    if (c='a') or (c='A') then begin r:=true; All:=true; end;
 if r then writeln('Y')
      else writeln('N');
 YesNo:=r;
end;

type plug = (Common ,Uue, Crax, FilesBBS, Hatcher, Files, Gate, H,
             LogCut, Pathbld, Seenby, Twit, NS, EMail,
             ICQ, Stat, Archiver, Dob, BinkStat, Announce, MsgOut, Scan);
const
 plugcount = 21;

 plugstr:array [1..plugcount] of String =
 ('Uue', 'Crax', 'FilesBBS', 'Hatcher', 'Files', 'Gate', 'H',
  'LogCut', 'Pathbld', 'Seenby', 'Twit', 'NS',  'EMail',
  'ICQ', 'Stat', 'Archiver', 'Dob', 'BinkStat', 'Announce', 'MsgOut', 'Scan');

 plugd:array [1..plugcount] of boolean =
 (true,  true,   true,       true,      true,    true,   true,
  true,      true,      true,     true,  false,  false,
  false,  false,  true,      true,    false,     true,       true,    true);

var plugf:array[1..plugcount] of boolean;

 procedure Request(i:plug);
 begin
  plugf[Ord(i)]:=YesNo(StUpCase(plugstr[Ord(i)])+'.DLL', plugd[Ord(i)]);
 end;

var i, l, lc:integer;
    t1:text;
    t2:text;
    t3:text;
begin
 All:=false;
 l:=0; lc:=0;
 for i:=1 to plugcount do plugf[i]:=false;

 for i:=1 to plugcount do
 begin
  if not plugf[i] then
   plugf[i]:=YesNo(StUpCase(plugstr[i])+'.DLL', plugd[i]);

  if plugf[i] then
  begin
   inc(l);
   case plug(i) of
    Dob: plugf[Ord(Announce)]:=true;
    Announce: plugf[Ord(MsgOut)]:=true;
    Twit: plugf[Ord(Scan)]:=true;
    H: plugf[Ord(Scan)]:=true;
    Hatcher: plugf[Ord(Archiver)]:=true;
    FilesBBS: plugf[Ord(Archiver)]:=true;
    BinkStat: begin plugf[Ord(Announce)]:=true; plugf[Ord(MsgOut)]:=true; end;
   end;
  end;
 end;

 assign(t1, 'custom1.inc'); rewrite(t1);
 assign(t2, 'custom2.inc'); rewrite(t2);
 assign(t3, 'custom3.inc'); rewrite(t3);
 writeln(t2, 'function QueryPluginService(const FName: String): Pointer; Far;');
 writeln(t2, ' begin');
 writeln(t2, '  if FName = ''COMMON.DLL''   then QueryPluginService:=@Common.Service else');

 writeln(t3,'const SolidDllcnt = ',l+1,';');
 writeln(t3,'const SolidDll:array[1..',l+1,'] of PChar = (');
 writeln(t3,' ''COMMON'',');

  for i:=1 to plugcount do
   if plugf[i] then
   begin
    inc(lc);
    writeln(t1, '     ',plugstr[i],',');
    writeln(t2, '  if FName = ''',StUpCase(plugstr[i]),'.DLL''   then QueryPluginService:=@',plugstr[i],'.Service else');
    write(t3, ' ''',StUpCase(plugstr[i]),''''); if lc<l then writeln(t3, ',') else writeln(t3);
   end;

 writeln(t2, '   QueryPluginService:=Nil;');
 writeln(t2, ' end;');
 writeln(t3,');');  
 close(t1);
 close(t2);
 close(t3);
end.
