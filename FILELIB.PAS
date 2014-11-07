unit FileLib;

{ FileLib v1.5 (c) by sergey korowkin, 1998. }

interface
uses
     Types, Wizard, Video, Log;

type
 PItem = ^TItem;
 TItem = record
  Id: Byte;
  Offset: Longint;
  Size: Longint;
  Name: String[118];
 end;

 PIndex = ^TIndex;
 TIndex = object(TCollection)
  procedure FreeItem(Item: Pointer); virtual;
 end;

 PLibrary = ^TLibrary;
 TLibrary = object(TObject)
 public
  DataLink: PBufStream;
  Index: PIndex;
  Debugging: Boolean;
  Error: Boolean;
  ErrorString: String;

  constructor Init(const DataName: String);
  destructor Done; virtual;

  procedure Debug(const S: String); virtual;
  procedure DoError(const S: String);

  procedure Prepare;

  procedure LoadIndex;
  procedure StoreIndex; virtual;

  procedure AddResource(const Name: String; S: PStream; const Size: Longint);
  procedure AddResourceFromMemory(const Name: String; Data: Pointer; const Size: Longint);
  function  QueryResource(Name: String): PItem;
  procedure KillResource(const Name: String);
  function  GetResourceSize(const Name: String): Longint;
  procedure GetResource(const Name: String; S: PStream);
  procedure GetResourceToMemory(const Name: String; Data: Pointer);

  procedure Pack(Temp: PStream);

  procedure Reset;
 end;

const
 MaxResources   = 4096;
 IndexSize      = MaxResources * SizeOf(TItem);
 ridResource    = 1;

implementation

procedure TIndex.FreeItem(Item: Pointer);
 begin
  if Item <> Nil then
   Dispose(PItem(Item));
 end;

{* TLibrary *}
constructor TLibrary.Init;
 begin
  inherited Init;
  Debugging:=False;
  Error:=False;
  Debug('TLibrary.Init()');
  Debug('Creating indexcollection');
  Index:=New(PIndex, Init);
  Debug('Using ' + DataName + ' as resourcefile');
  DataLink:=New(PBufStream, Init(DataName, stOpen, 2048));
  if DataLink^.Status <> stOk then
   begin
    Debug('Cannot open resourcefile (stOpen) - rc#' + Long2Str(DataLink^.Status));
    Dispose(DataLink, Done);
    DataLink:=New(PBufStream, Init(DataName, stCreate, 2048));
    Debug('Resourcefile created.');
    Prepare;
   end
  else
   LoadIndex;
 end;

destructor TLibrary.Done;
 begin
  StoreIndex;
  Debug('Destroying DataLink');
  Dispose(DataLink, Done);
  Debug('Destroying Index');
  Dispose(Index, Done);
  Debug('Destroying TLibrary');
  inherited Done;
 end;

procedure TLibrary.Debug;
 begin
  if Debugging then
   LogWrite('Main', 'rDebug: ' + S);
 end;

procedure TLibrary.DoError;
 begin
  Error:=True;
  ErrorString:=S;
 end;

procedure TLibrary.Prepare;
 begin
  Debug('Preparing resourcefile [' + Long2Str(IndexSize) + ']');
  DataLink^.Seek(IndexSize);
  Debug('Truncating...');
  DataLink^.Truncate;
 end;

procedure TLibrary.LoadIndex;
 var
  Count, K: Longint;
  I: PItem;
 begin
  Debug('LoadIndex() started.');
  DataLink^.Seek(0);
  DataLink^.Read(Count, SizeOf(Count));
  Debug('Resourcefile contains ' + Long2Str(Count) + ' resources [max ' + Long2Str(MaxResources) + ']');
  if Count > MaxResources then
   begin
    DoError('???: Count:' + HexL(Count) + '; MaxResources:' + HexL(MaxResources) + '; it''s wrong.');
    Exit;
   end;
  Debug('Cleaning index...');
  Index^.FreeAll;
  Debug('Loading index...');
  for K:=1 to Count do
   begin
    New(I);
    DataLink^.Read(I^, SizeOf(I^));
    if I^.Offset > DataLink^.GetSize then
     begin
      DoError('???: ofs ' + HexL(I^.Offset) + ' out of resourcefile');
      Break;
     end;
    Index^.Insert(I);
   end;
 end;

procedure TLibrary.StoreIndex;
 var
  Count, K: Longint;
  I: PItem;
 begin
  Debug('StoreIndex() started.');
  Count:=Index^.Count;
  Debug('Writing indexsize...');
  DataLink^.Seek(0);
  DataLink^.Write(Count, SizeOf(Count));
  Debug('Writing index...');
  for K:=1 to Count do
   begin
    I:=Index^.At(K);
    DataLink^.Write(I^, SizeOf(I^));
   end;
  DataLink^.Flush;
  Debug('Ok.');
 end;

procedure TLibrary.AddResource(const Name: String; S: PStream; const Size: Longint);
 var
  I: PItem;
 begin
  Debug('Adding resource "' + Name + '"');
  if QueryResource(Name) <> Nil then KillResource(Name);
  Debug('Creating structures...');
  New(I);
  FillChar(I^, SizeOf(I^), $FF);
  I^.Id:=ridResource;
  I^.Offset:=DataLink^.GetSize;
  I^.Size:=Size;
  Debug('Resource offset is ' + HexL(I^.Offset) + '; size is ' + HexL(I^.Size));
  I^.Name:=Name;
  Debug('Updating index...');
  Index^.Insert(I);
  Debug('Writing resource to the resourcefile...');
  DataLink^.Seek(I^.Offset);
  DataLink^.CopyFrom(S^, Size);
  StoreIndex;
 end;

procedure TLibrary.AddResourceFromMemory(const Name: String; Data: Pointer; const Size: Longint);
 var
  Stream: TMemoryStream;
 begin
  Debug('Adding resource "' + Name + '" from memory.');
  Stream.Init;
  Debug('Writing data ' + HexL(Longint(Data)) + ' to the memory stream [' + HexL(Size) + ' bytes]');
  Stream.Write(Data^, Size);
  Stream.Seek(0);
  Debug('Calling AddResource...');
  AddResource(Name, @Stream, Size);
  Stream.Done;
 end;

function TLibrary.QueryResource(Name: String): PItem;
 var
  K: Longint;
  I: PItem;
 begin
  Debug('Querying resource "' + Name + '"');
  StUpcaseEx(Name);
  for K:=1 to Index^.Count do
   begin
    I:=Index^.At(K);
    if StUpcase(I^.Name) = Name then
     begin
      QueryResource:=I;
      Debug('Found, ' + HexL(Longint(I)) + '.');
      Exit;
     end;
   end;
  QueryResource:=Nil;
  Debug('Not found.');
 end;

procedure TLibrary.KillResource(const Name: String);
 var
  Resource: PItem;
 begin
  Debug('Killing resource "' + Name + '"');
  Resource:=QueryResource(Name);
  if Resource = Nil then Exit;
  Index^.Free(Resource);
  Debug('Killed.');
  StoreIndex;
 end;

function TLibrary.GetResourceSize(const Name: String): Longint;
 var
  I: PItem;
 begin
  I:=QueryResource(Name);
  if I = Nil then
   GetResourceSize:=-1
  else
   GetResourceSize:=I^.Size;
 end;

procedure TLibrary.GetResource(const Name: String; S: PStream);
 var
  I: PItem;
 begin
  Debug('GetResource "' + Name + '" to the stream "' + HexL(Longint(S)) + '"');
  I:=QueryResource(Name);
  if I = Nil then Exit;
  DataLink^.Seek(I^.Offset);
  S^.CopyFrom(DataLink^, I^.Size);
  Debug('GetResource: ' + Long2Str(I^.Size) + ' bytes ok.');
 end;

procedure TLibrary.GetResourceToMemory(const Name: String; Data: Pointer);
 var
  S: TMemoryStream;
 begin
  Debug('GetResourceToMemory "' + Name + '" to "' + HexL(Longint(Data)) + '"');
  S.Init;
  Debug('Calling GetResource');
  GetResource(Name, @S);
  S.Seek(0);
  Debug('Moving streamdata to destination');
  S.Read(Data^, S.GetSize);
  S.Done;
  Debug('Ok');
 end;

procedure TLibrary.Pack(Temp: PStream);
 var
  K: Longint;
  I: PItem;
 begin
  Debug('Repacking of resourcefile started.');
  Debug('Preparing tempstream...');
  Temp^.Seek(0);
  Temp^.Truncate;
  Debug('Writing resources to the tempstream...');
  for K:=1 to Index^.Count do
   begin
    I:=Index^.At(K);
    DataLink^.Seek(I^.Offset);
    I^.Offset:=IndexSize + Temp^.GetPos;
    Temp^.CopyFrom(DataLink^, I^.Size);
   end;
  Debug('Writing resources back to the mainstream...');
  DataLink^.Seek(IndexSize);
  Temp^.Seek(0);
  DataLink^.CopyFrom(Temp^, Temp^.GetSize);
  DataLink^.Flush;
  DataLink^.Truncate;
  DataLink^.Flush;
  Debug('Repacking done.');
  StoreIndex;
 end;

procedure TLibrary.Reset;
 begin
  Error:=False;
  ErrorString:='';
 end;

end.