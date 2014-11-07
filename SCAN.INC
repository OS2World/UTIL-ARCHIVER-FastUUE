{$IFDEF SCAN_CODE}
 {$UNDEF SCAN_DECL}
{$ENDIF}
{$IFDEF SCAN_DECL}
 {$UNDEF SCAN_CODE}
{$ENDIF}
{$IFNDEF SCAN_CODE}
{$IFNDEF SCAN_DECL}
 {$DEFINE SCAN_CODE}
 {$DEFINE SCAN_DECL}
{$ENDIF}
{$ENDIF}

{$IFDEF SCAN_DECL}
const
 snsPktStart            = $00001000;
 snsPktEnd              = $00001001;
 snsPktHeader           = $00001002;
 snsMessage             = $00001003;
 snsWarnStop            = $00001004;
 snsScanStart           = $00001005;
 snsScanEnd             = $00001006;

 snsPutMessage          = $00001101;
 snsDupeMessage         = $00001102;
 snsKillMessage         = $00001103;
 snsCopyMessage         = $00001104;

 snsAreYouScanner       = $00001666;
 snrIamScanner          = $00002700;

type
 TPKTHeader    = record
  OrigNode     : system.word;
  DestNode     : system.word;
  Year         : system.word;
  Month        : system.word;
  Day          : system.word;
  Hour         : system.word;
  Minute       : system.word;
  Second       : system.word;
  Rate         : system.word;
  Version      : system.word;
  OrigNet      : system.word;
  DestNet      : system.word;
  PCodeLo      : system.byte;
  PRevMajor    : system.byte;
  Password     : array[1..8] of system.char;
  QMOrigZone   : system.word;
  QMDestZone   : system.word;
  AuxNet       : system.word;
  CWValidate   : system.word;
  PCodeHi      : system.byte;
  PRevMinor    : system.byte;
  CWCapWord    : system.word;
  OrigZone     : system.word;
  DestZone     : system.word;
  OrigPoint    : system.word;
  DestPoint    : system.word;
  LongData     : system.longint;
 end;

 TPktMessage = record
  origNode     : system.word;
  destNode     : system.word;
  origNet      : system.word;
  destNet      : system.word;
  Attribute    : system.word;
  cost         : system.word;
 end;

type
 PBuffer = ^TBuffer;
 TBuffer = array[1..65521] of byte;

 PMessage = ^TMessage;
 TMessage = object(TObject)
  iFrom: String;
  iTo: String;
  iSubj: String;
  iDate: String;
  iArea: String;
  iFromAddress: TAddress;
  iToAddress: TAddress;
  iSize: Longint;
  iAttributes: Longint;
  Data: PStrings;
  Kill: Boolean;
  Group: PStrings;
  constructor Init;
  destructor Done; virtual;
 end;
{$ENDIF}

{$IFDEF SCAN_CODE}
constructor TMessage.Init;
 begin
  inherited Init;
  cmCreateStrings(Data);
 end;

destructor TMessage.Done;
 begin
  cmDisposeObject(Data);
  inherited Done;
 end;

function scanAddMessage(const iFrom, iTo, iSubj, iArea: String; const iFromAddress, iToAddress: TAddress;
 Data: PStrings): Longint;
 begin
  sSetSemaphore('Scanner.Add.iFrom', iFrom);
  sSetSemaphore('Scanner.Add.iTo', iTo);
  sSetSemaphore('Scanner.Add.iSubj', iSubj);
  sSetSemaphore('Scanner.Add.iArea', iArea);
  sSetSemaphore('Scanner.Add.iFromAddress', Address2Str(iFromAddress));
  sSetSemaphore('Scanner.Add.iToAddress', Address2Str(iToAddress));
  scanAddMessage:=srvExecute('SCANNER', snsPutMessage, Data);
 end;

procedure scanDupeMessage(Source: PMessage; var Destination: PMessage);
 begin
  srvExecute('SCANNER', snsDupeMessage, Source);
  Destination:=sGetPtrSemaphore('Scanner.Dupe');
 end;

procedure scanKillMessage(Message: PMessage);
 begin
  srvExecute('SCANNER', snsKillMessage, Message);
 end;

procedure scanCopyMessage(Source, Destination: PMessage);
 begin
  sSetSemaphore('Scanner.Copy.Source', HexPtr(Source));
  sSetSemaphore('Scanner.Copy.Destination', HexPtr(Destination));
  srvExecute('SCANNER', snsCopyMessage, nil);
 end;
{$ENDIF}

{$UNDEF SCAN_CODE}
{$UNDEF SCAN_DECL}

