unit uueOver;

{$IFDEF VIRTUALPASCAL}
 {$DEFINE USEUNITS}
{$ENDIF}
{$IFDEF SOLID}
 {$DEFINE USEUNITS}
{$ENDIF}

interface
uses
{$IFDEF USEUNITS}
     Misc, Language, Semaphor, Plugins, Config, Video, Division, Resource,
{$ELSE}
     Decl,
{$ENDIF}
     Types, Wizard;

const
 uueVersion                     = $00020001;
 uueResourceVersion             = $4E455269;

var
 uueTempFilename, uueTempFilenameBackup: String;
 uueDecoding, uueScanning: Boolean;
 uueHeaders: PStrings;
 uueHeadersCount: Longint;
 uueTable: array[Char] of Boolean;

type
 PFile = ^TFile;
 TFile = object(TObject)
  Filename, VirginFilename, Area: String;
  Count, Total, Date, Max: Longint;
  Bad: Boolean;
  constructor Init(const AFilename, AArea: String; ACount, ATotal, ADate, AMax: Longint);
 end;

 PSection = ^TSection;
 TSection = object(TObject)
  Version: Longint;
  Current: Longint;
  Total: Longint;
  Filename: String;
  iFrom: String;
  iTo: String;
  iFromAddress: String;
  iToAddress: String;
  iArea: String;
  iSubj: String;
  iDate: Longint;
  Data: PStrings;
  Inf: PStrings;
  Error: Boolean;
  constructor Init;
  procedure Store(Key: String);
  procedure Load(Key: String);
  destructor Done; virtual;
 end;

function IsUUE(const S: String): Boolean;
function QueryName(const Current, Total: Longint; const Filename, Area: String): String;
function ParseName(const Source: String; var Current, Total: Longint; var Filename, Area: String): Boolean;
function QueryTimeDifference(const F: PFile): Longint;

implementation

{ TFile }

constructor TFile.Init(const AFilename, AArea: String; ACount, ATotal, ADate, AMax: Longint);
 begin
  inherited Init;
  Filename:=AFilename;
  VirginFilename:=AFilename;
  Area:=AArea;
  Count:=ACount;
  Total:=ATotal;
  Date:=ADate;
  Max:=AMax;
  Bad:=False;
 end;

{ TSection }

constructor TSection.Init;
 begin
  inherited Init;
  Data:=New(PStrings, Init);
  Inf:=New(PStrings, Init);
 end;

procedure TSection.Load;
 var
  Stream: PMemoryStream;
  K, L, M: Longint;
  S: String;
 begin
  Error:=False;
  Data^.FreeAll;
  Inf^.FreeAll;

  cmCreateMemoryStream(Stream);
  rGetStream(Key, Stream);

  repeat
   cmStreamSeek(Stream, 0);
   cmStreamRead(Stream, K, SizeOf(K));
   cmStreamRead(Stream, Version, SizeOf(Version));
   cmStreamRead(Stream, Current, SizeOf(Current));

   Filename:=cmStreamReadStr(Stream);
   iFrom:=cmStreamReadStr(Stream);
   iTo:=cmStreamReadStr(Stream);
   iFromAddress:=cmStreamReadStr(Stream);
   iToAddress:=cmStreamReadStr(Stream);
   iArea:=cmStreamReadStr(Stream);
   iSubj:=cmStreamReadStr(Stream);

   if cmStreamGetStatus(Stream) <> stOk then
    begin
     Error:=True;
     Break;
    end;

   cmStreamRead(Stream, iDate, SizeOf(iDate));
   cmStreamRead(Stream, K, SizeOf(K));

   for L:=1 to K do
    begin
     S:=cmStreamReadStr(Stream);

     if cmStreamGetStatus(Stream) <> stOk then
      begin
       Error:=True;
       Break;
      end;

     Data^.Insert(NewStr(S));
    end;

   cmStreamRead(Stream, K, SizeOf(K));

   for L:=1 to K do
    begin
     S:=cmStreamReadStr(Stream);

     if cmStreamGetStatus(Stream)<>stOk then
      begin
       Error:=True;
       Break;
      end;

     Inf^.Insert(NewStr(S));
    end;

   cmStreamRead(Stream, Total, SizeOf(Total));
  until True;

  cmDisposeObject(Stream);
 end;

procedure TSection.Store;
 var
  Stream: PMemoryStream;
  K, L, M: Longint;
  S: String;
 begin
  cmCreateMemoryStream(Stream);

  K:=666;

  cmStreamWrite(Stream, K, SizeOf(K));
  cmStreamWrite(Stream, Version, SizeOf(Version));
  cmStreamWrite(Stream, Current, SizeOf(Current));

  cmStreamWriteStr(Stream, Filename);
  cmStreamWriteStr(Stream, iFrom);
  cmStreamWriteStr(Stream, iTo);
  cmStreamWriteStr(Stream, iFromAddress);
  cmStreamWriteStr(Stream, iToAddress);
  cmStreamWriteStr(Stream, iArea);
  cmStreamWriteStr(Stream, iSubj);

  K:=Data^.Count;

  cmStreamWrite(Stream, iDate, SizeOf(iDate));
  cmStreamWrite(Stream, K, SizeOf(K));

  for L:=1 to K do
   cmStreamWriteStr(Stream, GetPString(Data^.At(L)));

  K:=Inf^.Count;

  cmStreamWrite(Stream, K, SizeOf(K));

  for L:=1 to K do
   cmStreamWriteStr(Stream, GetPString(Inf^.At(L)));

  cmStreamWrite(Stream, Total, SizeOf(Total));
  cmStreamSeek(Stream, 0);

  rPutStream(Key, Stream, cmStreamGetSize(Stream));

  cmDisposeObject(Stream);
 end;

destructor TSection.Done;
 begin
  Dispose(Data, Done);
  Dispose(Inf, Done);
  inherited Done;
 end;

{ IsUUE }

function IsUUE(const S: String): Boolean;
 var
  K: Byte;
 begin
  for K:=1 to Length(S) do
   if not (S[K] in [#$20..#$60]) then
    begin
     IsUUE:=False;
     Exit;
    end;

  if ((Copy(S, 1, 3) = '---') and (S[0] = #3)) or (Copy(S, 1, 4) = '--- ') then
   IsUUE:=False
  else
   IsUUE:=True;
 end;

{ QueryName }

function QueryName(const Current, Total: Longint; const Filename, Area: String): String;
 begin
  QueryName:='uue'#255 + Area + #255 + Long2Str(Current) + #255 + Long2Str(Total) + #255 + Filename;
 end;

{ ParseName }

function ParseName(const Source: String; var Current, Total: Longint; var Filename, Area: String): Boolean;
 begin
  if Copy(Source, 1, 4) <> 'uue'#255 then
   begin
    ParseName:=False;
    Exit;
   end;

  Area:=ExtractWord(2, Source, [#255]);
  Str2Longint(ExtractWord(3, Source, [#255]), Current);
  Str2Longint(ExtractWord(4, Source, [#255]), Total);
  FileName:=GetAllAfterChar(Source, 4, #255);

  ParseName:=True;
 end;

{ QueryTimeDifference }

function QueryTimeDifference(const F: PFile): Longint;
 var
  K: Longint;
 begin
  K:=TimeFix - F^.Date;
  if K < 0 then
   QueryTimeDifference:=0
  else
   begin
    K:=K div Longint(86400);
    QueryTimeDifference:=K;
   end;
 end;

end.