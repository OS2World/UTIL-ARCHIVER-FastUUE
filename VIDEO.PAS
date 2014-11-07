unit Video;

{$UNDEF USECRT}

{$IFDEF DPMI}
 {$DEFINE USECRT}
{$ENDIF}

{$IFDEF SOLID}
 {$DEFINE USECRT}
{$ENDIF}

interface

procedure vInit(AService: Pointer); {$IFNDEF SOLID}export;{$ENDIF}
procedure vDone; {$IFNDEF SOLID}export;{$ENDIF}

procedure vPrint(const S: String); {$IFNDEF SOLID}export;{$ENDIF}
procedure vPrintLn(const S: String); {$IFNDEF SOLID}export;{$ENDIF}
procedure vClrScr; {$IFNDEF SOLID}export;{$ENDIF}
procedure vClrEol; {$IFNDEF SOLID}export;{$ENDIF}
function  vGetAttr: Byte; {$IFNDEF SOLID}export;{$ENDIF}
procedure vSetAttr(Color: Byte); {$IFNDEF SOLID}export;{$ENDIF}
function  kKeypressed: Boolean; {$IFNDEF SOLID}export;{$ENDIF}
function  kReadkey: Char; {$IFNDEF SOLID}export;{$ENDIF}
procedure vGotoY(Y: Byte); {$IFNDEF SOLID}export;{$ENDIF}

implementation
{$IFDEF USECRT}
{$IFDEF VIRTUALPASCAL}
uses Crt;
{$ELSE}
uses Crt_p2;
{$ENDIF}

procedure vInit(AService: Pointer);
 begin
 end;

procedure vPrint(const S: String);
 begin
  InOutRes:=0;
  Write(S);
 end;

procedure vPrintLn(const S: String);
 begin
  vPrint(S);
  vPrint(#13#10);
 end;

procedure vClrScr;
 begin
  ClrScr;
 end;

procedure vClrEol;
 begin
  ClrEol;
 end;

function vGetAttr: Byte;
 begin
  vGetAttr:=TextAttr;
 end;

procedure vSetAttr(Color: Byte);
 begin
  TextAttr:=Color;
 end;

procedure vDone;
 begin
 end;

function kKeypressed: Boolean;
 begin
  kKeypressed:=Keypressed;
 end;

function kReadkey: Char;
 begin
  kReadkey:=Readkey;
 end;

procedure vGotoY(Y: Byte);
 begin
  GotoXY(1, Y);
 end; 
{$ELSE}
{$I SECRET.INC}
const
 Service: TVideoService = Nil;

procedure vInit(AService: Pointer);
 begin
  @Service:=AService;
 end;

procedure vPrint(const S: String);
 begin
  Service(1, 0, S);
 end;

procedure vPrintLn(const S: String);
 begin
  Service(1, 0, S);
  Service(2, 0, '');
 end;

procedure vClrScr;
 begin
  Service(3, 0, '');
 end;

procedure vClrEol;
 begin
  Service(4, 0, '');
 end;

function vGetAttr: Byte;
 begin
  vGetAttr:=Service(5, 0, '');
 end;

procedure vSetAttr(Color: Byte);
 begin
  Service(6, Color, '');
 end;

procedure vDone;
 begin
 end;

function kKeypressed: Boolean;
 begin
  kKeypressed:=Boolean(Service(7, 0, ''));
 end;

function kReadkey: Char;
 begin
  kReadkey:=Char(Service(8, 0, ''));
 end;

procedure vGotoY(Y: Byte);
 begin
  Service(9, Y, '');
 end; 
{$ENDIF}


end.
