unit AMF.Message;

interface

uses
  SysUtils, Classes, TypInfo, Rtti, Generics.Collections;

type
  EAMFError = class(Exception) end;
  EAMFNotSupportedError = class(EAMFError) end;

  TAMFHashNode = record
    Key: string;
    Value: string;
    IsNull: Boolean;
  end;

  TAMFStream = class
  public type
    AMFVersion = (v0, v3);
  private const
    { AMF0 Type Markers }
    AMF0_NUMBER_MARKER       = $00;
    AMF0_BOOLEAN_MARKER      = $01;
    AMF0_STRING_MARKER       = $02;
    AMF0_OBJECT_MARKER       = $03;
    AMF0_MOVIE_CLIP_MARKER   = $04;
    AMF0_NULL_MARKER         = $05;
    AMF0_UNDEFINED_MARKER    = $06;
    AMF0_REFERENCE_MARKER    = $07;
    AMF0_HASH_MARKER         = $08;
    AMF0_OBJECT_END_MARKER   = $09;
    AMF0_STRICT_ARRAY_MARKER = $0A;
    AMF0_DATE_MARKER         = $0B;
    AMF0_LONG_STRING_MARKER  = $0C;
    AMF0_UNSUPPORTED_MARKER  = $0D;
    AMF0_RECORDSET_MARKER    = $0E;
    AMF0_XML_MARKER          = $0F;
    AMF0_TYPED_OBJECT_MARKER = $10;
    AMF0_AMF3_MARKER         = $11;

    { AMF3 Type Markers }
    AMF3_UNDEFINED_MARKER  = $00;
    AMF3_NULL_MARKER       = $01;
    AMF3_FALSE_MARKER      = $02;
    AMF3_TRUE_MARKER       = $03;
    AMF3_INTEGER_MARKER    = $04;
    AMF3_DOUBLE_MARKER     = $05;
    AMF3_STRING_MARKER     = $06;
    AMF3_XML_DOC_MARKER    = $07;
    AMF3_DATE_MARKER       = $08;
    AMF3_ARRAY_MARKER      = $09;
    AMF3_OBJECT_MARKER     = $0A;
    AMF3_XML_MARKER        = $0B;
    AMF3_BYTE_ARRAY_MARKER = $0C;
    AMF3_DICT_MARKER       = $11;

    { Other AMF3 Markers }
    AMF3_EMPTY_STRING         = $01;
    AMF3_CLOSE_DYNAMIC_OBJECT = $01;
    AMF3_CLOSE_DYNAMIC_ARRAY  = $01;
  public const
    { Other Constants }
    MAX_INTEGER = 268435455;
    MIN_INTEGER = -268435456;
  private var
    FVersion: AMFVersion;
    FStream: TMemoryStream;

    procedure PackReversedByteArray(AByteArray: array of Byte);
    procedure PackByte(AByte: Byte);
    procedure PackWord(AWord: Word);
    procedure PackLongWord(ALongWord: LongWord);
    procedure PackInteger(AnInteger: Integer);
    procedure PackDouble(ADouble: Double);
    procedure PackAMF3UTF8String(AnUTF8String: UTF8String);
  public
    constructor Create(Version: AMFVersion);
    destructor Destroy; override;

    function ToDebugString: string;
    function ToRawString: RawByteString;

    procedure Clear;

    procedure WriteNull;
    procedure WriteInteger(AnInteger: Integer);
    procedure WriteBoolean(ABoolean: Boolean);
    procedure WriteDouble(ADouble: Double);
    procedure WriteString(AString: string);
    procedure WriteDateTime(ADateTime: TDateTime);
    procedure WriteArray(const AnArray: array of const);
    procedure WriteHash(const AnArrayOfKeys: array of string; const AnArrayOfValues: array of const);
  end;

implementation

{ TAMFStream }

constructor TAMFStream.Create(Version: AMFVersion);
begin
  inherited Create;
  FVersion := Version;
  FStream := TMemoryStream.Create;
end;

destructor TAMFStream.Destroy;
begin
  FStream.Free;
  inherited;
end;

procedure TAMFStream.PackByte(AByte: Byte);
begin
  FStream.Write(AByte, SizeOf(Byte));
end;

procedure TAMFStream.PackDouble(ADouble: Double);
var
  V: array[0..SizeOf(Double) - 1] of Byte;
begin
  PDouble(@V[0])^ := ADouble;
  PackReversedByteArray(V);
end;

procedure TAMFStream.PackInteger(AnInteger: Integer);
var
  X: Integer;
begin
  X := AnInteger and $1fffffff;

  if X < $80 then
    PackByte(Byte(X))
  else if X < $4000 then
  begin
    PackByte((Byte(X shr 7) and $7f) or $80);
    PackByte(Byte(X and $7f));
  end
  else if X < $200000 then
  begin
    PackByte((Byte(X shr 14) and $7f) or $80);
    PackByte((Byte(X shr  7) and $7f) or $80);
    PackByte( Byte(X         and $7f));
  end
  else
  begin
    PackByte((Byte(X shr 22) and $7f) or $80);
    PackByte((Byte(X shr 15) and $7f) or $80);
    PackByte((Byte(X shr  8) and $7f) or $80);
    PackByte( Byte(X         and $ff));
  end;
end;

procedure TAMFStream.PackLongWord(ALongWord: LongWord);
var
  V: array[0..SizeOf(LongWord) - 1] of Byte;
begin
  PLongWord(@V[0])^ := ALongWord;
  PackReversedByteArray(V);
end;

procedure TAMFStream.PackReversedByteArray(AByteArray: array of Byte);
var
  I: Integer;
begin
  for I := High(AByteArray) downto Low(AByteArray) do
    PackByte(AByteArray[I]);
end;

procedure TAMFStream.PackWord(AWord: Word);
var
  V: array[0..SizeOf(Word) - 1] of Byte;
begin
  PWord(@V[0])^ := AWord;
  PackReversedByteArray(V);
end;

procedure TAMFStream.PackAMF3UTF8String(AnUTF8String: UTF8String);
begin
  if AnUTF8String = '' then
    PackByte(AMF3_EMPTY_STRING)
  else
  begin
    PackInteger((Length(AnUTF8String) shl 1) or 1);
    FStream.Write(AnUTF8String[1], Length(AnUTF8String));
  end;
end;

function TAMFStream.ToDebugString: string;
const
  VERSION_STRING: array[AMFVersion] of string = ('0', '3');
var
  L: Integer;
  B: Byte;
begin
  Result := 'AMF v' + VERSION_STRING[FVersion] + ' / ';
  FStream.Position := 0;
  L := FStream.Size;
  while L > 0 do
  begin
    FStream.Read(B, SizeOf(B));
    Result := Result + IntToHex(B, 2) + ' ';
    Dec(L);
  end;
  Result := Trim(Result);
end;

function TAMFStream.ToRawString: RawByteString;
begin
  SetLength(Result, FStream.Size);
  Move(FStream.Memory^, PAnsiChar(Result)^, FStream.Size);
end;

procedure TAMFStream.Clear;
begin
  FStream.Clear;
end;

procedure TAMFStream.WriteNull;
begin
  if FVersion = v0 then
    PackByte(AMF0_NULL_MARKER)
  else
    PackByte(AMF3_NULL_MARKER);
end;

procedure TAMFStream.WriteString(AString: string);
var
  U: UTF8String;
  L: Cardinal;
begin
  U := UTF8String(AString);
  L := Length(U);
  if FVersion = v0 then
  begin
    if L > High(Word) then
    begin
      PackByte(AMF0_LONG_STRING_MARKER);
      PackLongWord(L);
    end
    else
    begin
      PackByte(AMF0_STRING_MARKER);
      PackWord(L);
    end;
    FStream.Write(U[1], Length(U));
  end
  else
  begin
    PackByte(AMF3_STRING_MARKER);
    PackAMF3UTF8String(U);
  end;
end;

procedure TAMFStream.WriteArray(const AnArray: array of const);
var
  I: Integer;
begin
  if FVersion = v0 then
  begin
    PackByte(AMF0_STRICT_ARRAY_MARKER);
    PackLongWord(Length(AnArray));

    for I := 0 to High(AnArray) do
    begin
      with AnArray[I] do
      begin
        case VType of
          vtInteger:       WriteDouble(VInteger);
          vtBoolean:       WriteBoolean(VBoolean);
          vtChar:          WriteString(string(VChar));
          vtExtended:      WriteDouble(VExtended^);
          vtString:        WriteString(string(VString^));
          vtPChar:         WriteString(string(VPChar));
          vtWideChar:      WriteString(VWideChar);
          vtPWideChar:     WriteString(VPWideChar);
          vtAnsiString:    WriteString(string(VAnsiString));
          vtCurrency:      WriteDouble(VCurrency^);
          vtWideString:    WriteString(string(VWideString^));
          vtInt64:         WriteDouble(VInt64^);
          vtUnicodeString: WriteString(PChar(VUnicodeString));
        else
          raise EAMFNotSupportedError.Create('Type not supported');
        end;
      end;
    end;
  end;
end;

procedure TAMFStream.WriteBoolean(ABoolean: Boolean);
begin
  if FVersion = v0 then
  begin
    PackByte(AMF0_BOOLEAN_MARKER);
    PackByte(Byte(ABoolean));
  end
  else if ABoolean then
    PackByte(AMF3_TRUE_MARKER)
  else
    PackByte(AMF3_FALSE_MARKER);
end;

procedure TAMFStream.WriteDateTime(ADateTime: TDateTime);
var
  UnixDate: Double;
begin
  if FVersion = v0 then
    PackByte(AMF0_DATE_MARKER)
  else
  begin
    PackByte(AMF3_DATE_MARKER);
    PackByte(AMF3_NULL_MARKER);
  end;

  UnixDate := Round((ADateTime - UnixDateDelta) * MSecsPerDay);
  PackDouble(UnixDate);

  { Douteux... }
  if FVersion = v0 then
    PackWord(0);
end;

procedure TAMFStream.WriteDouble(ADouble: Double);
begin
  if FVersion = v0 then
    PackByte(AMF0_NUMBER_MARKER)
  else
    PackByte(AMF3_DOUBLE_MARKER);
  PackDouble(ADouble);
end;

procedure TAMFStream.WriteHash(const AnArrayOfKeys: array of string;
  const AnArrayOfValues: array of const);
var
  Keys: TArray<string>;
  K: string;
  AnsiKey: RawByteString;
  I: Integer;
  D: TDictionary<string, Integer>;
begin
  D := TDictionary<string, Integer>.Create;
  try
    for I := 0 to High(AnArrayOfKeys) do
      D.Add(AnArrayOfKeys[I], I);

    if FVersion = v0 then
      PackByte(AMF0_OBJECT_MARKER)
    else
    begin
      PackByte(AMF3_OBJECT_MARKER);
      PackInteger($03 or ($02 shl 2));
    end;

    Keys := D.Keys.ToArray;
    TArray.Sort<string>(Keys);
    for K in Keys do
    begin
      if FVersion = v0 then
      begin
        AnsiKey := RawByteString(K);
        PackWord(Length(AnsiKey));
        FStream.WriteBuffer(AnsiKey[1], Length(AnsiKey))
      end
      else
        PackAMF3UTF8String(UTF8String(K));

      with AnArrayOfValues[D[K]] do
      begin
        case VType of
          vtInteger:       WriteDouble(VInteger);
          vtBoolean:       WriteBoolean(VBoolean);
          vtChar:          WriteString(string(VChar));
          vtExtended:      WriteDouble(VExtended^);
          vtString:        WriteString(string(VString^));
          vtPChar:         WriteString(string(VPChar));
          vtWideChar:      WriteString(VWideChar);
          vtPWideChar:     WriteString(VPWideChar);
          vtAnsiString:    WriteString(string(VAnsiString));
          vtCurrency:      WriteDouble(VCurrency^);
          vtWideString:    WriteString(string(VWideString^));
          vtInt64:         WriteDouble(VInt64^);
          vtUnicodeString: WriteString(PChar(VUnicodeString));
          vtPointer:
          begin
            if VPointer = nil then
              WriteNull
            else
              raise EAMFNotSupportedError.Create('Type not supported');
          end
        else
          raise EAMFNotSupportedError.Create('Type not supported');
        end;
      end;
    end;

    if FVersion = v0 then
    begin
      PackWord(0);
      PackByte(AMF0_OBJECT_END_MARKER);
    end
    else
      PackByte(AMF3_CLOSE_DYNAMIC_OBJECT);
  finally
    D.Free;
  end;
end;

procedure TAMFStream.WriteInteger(AnInteger: Integer);
begin
  if FVersion = v0 then
  begin
    PackByte(AMF0_NUMBER_MARKER);
    PackDouble(AnInteger);
  end
  else if (AnInteger < MIN_INTEGER) or (AnInteger > MAX_INTEGER) then
  begin
    PackByte(AMF3_DOUBLE_MARKER);
    PackDouble(AnInteger);
  end
  else
  begin
    PackByte(AMF3_INTEGER_MARKER);
    PackInteger(AnInteger);
  end;
end;

end.
