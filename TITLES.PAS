{&Delphi+}
unit Titles;

{
 (q) by sergey korowkin, 2000.
 (q) by Tatyana Medvedeva (DOS part), 2000.
 (q) by john gladkih (OS/2 part), 1999.
}

interface

procedure SetSessionTitle(const Title: String);
function GetSessionTitle: String;

implementation

{$IFDEF OS2}
uses Strings,
     Os2Def,
     Os2Base,
     Os2PmApi;

procedure SetSessionTitle(const Title: String);
 var
  tib: PTib;
  pib: PPib;
  hnd: HSwitch;
  tsk: SwCntrl;
 begin
  DosGetInfoBlocks(tib, pib);

  hnd:=WinQuerySwitchHandle(NullHandle, pib^.pib_ulpid);

  if (hnd <> NullHandle) and (WinQuerySwitchEntry(hnd, @tsk) = 0) then
   begin
    StrPCopy(tsk.szSwTitle, Title);

    WinChangeSwitchEntry(hnd, @tsk);
   end;
 end;

function GetSessionTitle: String;
 var
  tib: PTib;
  pib: PPib;
  hnd: HSwitch;
  tsk: SwCntrl;
 begin
  DosGetInfoBlocks(tib, pib);

  hnd:=WinQuerySwitchHandle(NullHandle, pib^.pib_ulpid);

  if (hnd <> NullHandle) and (WinQuerySwitchEntry(hnd, @tsk) = 0) then
   Result:=StrPas(tsk.szSwTitle)
  else
   Result:='';
 end;
{$ENDIF}

{$IFDEF WIN32}
uses Windows,
     Strings;

var
 Buf: Array[0..256] Of Char;

procedure SetSessionTitle(const Title: String);
 begin
  StrPCopy(Buf, Title);

  SetConsoleTitle(Buf);
 end;

function GetSessionTitle: String;
 begin
  GetConsoleTitle(Buf, SizeOf(Buf));

  Result:=StrPas(Buf);
 end;
{$ENDIF}

{$IFNDEF OS2}
{$IFNDEF WIN32}
uses NTVDM,
     Strings;

const
 clptitleSET       = $0010;
 clptitleGET       = $0011;

procedure SetSessionTitle(const Title: String);
 var
  RC, Handle, Sz: Word;
  P: PChar;
 begin
  if vddSupported then
   begin
    vddLoad('ntvdmclp.dll', 'ntvdmclpRegister', 'ntvdmclpDispatch', RC, Handle);

    if Handle <> 0 then
     begin
      Sz:=Length(Title) + 1;

      GetMem(P, Sz);

      StrPCopy(P, Title);

      asm
       push ds

       mov ax, Handle
       mov bx, Sz
       mov cx, $10

       lds dx, P

       db $c4, $c4, $58, $02

       pop ds
      end;

      FreeMem(P, Sz);

      vddUnload(Handle);
     end;
   end;
 end;

function GetSessionTitle: String;
 var
  RC, Handle: Word;
  P: PChar;
 const
  Psize = 256;
 begin
  if vddSupported then
   begin
    vddLoad('ntvdmclp.dll', 'ntvdmclpRegister', 'ntvdmclpDispatch', RC, Handle);

    if Handle <> 0 then
     begin
      GetMem(P, Psize);

      asm
       push ds

       mov bx, Psize
       mov ax, Handle
       mov cx, clptitleGET

       lds dx, P

       db $c4, $c4, $58, $02

       pop ds
      end;

      GetSessionTitle:=StrPas(P);

      FreeMem(P, Psize);

      vddUnload(Handle);
     end;
   end;
 end;
{$ENDIF}
{$ENDIF}

end.