unit AMF.Message;

interface

uses
  Windows, SysUtils, Classes, TypInfo, Rtti,
  Generics.Collections, Generics.Defaults,
  AMF.Types;

type
  EAMFError = class(Exception) end;
  EAMFNotSupportedError = class(EAMFError) end;

  TAMFBaseStream = class
  protected
    FStream: TMemoryStream;

    procedure PackReversedByteArray(AByteArray: array of Byte);
    procedure PackByte(AByte: Byte);
    procedure PackDouble(ADouble: Double);
  public
    constructor Create; virtual;
    destructor Destroy; override;

    procedure Clear;

    function ToDebugString: string;
    function ToRawString: RawByteString;
  end;

  TAMF0Stream = class(TAMFBaseStream)
  private
    procedure PackWord(AWord: Word);
    procedure PackLongWord(ALongWord: LongWord);
  public
    procedure WriteNull;
    procedure WriteInteger(AnInteger: Integer);
    procedure WriteBoolean(ABoolean: Boolean);
    procedure WriteDouble(ADouble: Double);
    procedure WriteString(AString: string);
    procedure WriteDateTime(ADateTime: TDateTime);
    procedure WriteArray(const AnArray: array of const);
    procedure WriteHash(const AnArrayOfKeys: array of string; const AnArrayOfValues: array of const);
    procedure WriteReference(ARefIndex: Integer);

    procedure StartArray(Elements: Integer);
  end;

  TAMF3Stream = class(TAMFBaseStream)
  private type
    TAMFCache<T> = class
    private
      FIndex: Integer;
      FCache: TDictionary<T, Integer>;
      function GetIndex(const Obj: T): Integer;
    public
      constructor Create;
      destructor Destroy; override;
      procedure AddObject(const Obj: T);
      function HaveObject(const Obj: T): Boolean;
      property Index[const Obj: T]: Integer read GetIndex; default;
    end;

  private
    FTraitsCache: TAMFCache<string>;
    FObjectsCache: TAMFCache<Pointer>;
    FStringCache: TAMFCache<UTF8String>;
    procedure PackInteger(AnInteger: Integer);
    procedure PackUTF8String(AnUTF8String: UTF8String);
  public
    constructor Create; override;
    destructor Destroy; override;

    procedure WriteNull;
    procedure WriteInteger(AnInteger: Integer);
    procedure WriteBoolean(ABoolean: Boolean);
    procedure WriteDouble(ADouble: Double);
    procedure WriteString(AString: string);
    procedure WriteDateTime(ADateTime: TDateTime);
    procedure WriteArray(const AnArray: array of const);
    procedure WriteHash(const AnArrayOfKeys: array of string; const AnArrayOfValues: array of const);
    procedure WriteReference(ARefIndex: Integer);
    procedure WriteValue(AValue: TValue);

    procedure StartArray(Elements: Integer);
  end;

implementation

{ TAMFBaseStream }

constructor TAMFBaseStream.Create;
begin
  inherited Create;
  FStream := TMemoryStream.Create;
end;

destructor TAMFBaseStream.Destroy;
begin
  FStream.Free;
  inherited;
end;

procedure TAMFBaseStream.Clear;
begin
  FStream.Clear;
end;

function TAMFBaseStream.ToRawString: RawByteString;
begin
  SetLength(Result, FStream.Size);
  Move(FStream.Memory^, PAnsiChar(Result)^, FStream.Size);
end;

function TAMFBaseStream.ToDebugString: string;
var
  L: Integer;
  B: Byte;
begin
  Result := Self.ClassName + ' / ';
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

procedure TAMFBaseStream.PackByte(AByte: Byte);
begin
  FStream.Write(AByte, SizeOf(Byte));
end;

procedure TAMFBaseStream.PackReversedByteArray(AByteArray: array of Byte);
var
  I: Integer;
begin
  for I := High(AByteArray) downto Low(AByteArray) do
    PackByte(AByteArray[I]);
end;

procedure TAMFBaseStream.PackDouble(ADouble: Double);
var
  V: array[0..SizeOf(Double) - 1] of Byte;
begin
  PDouble(@V[0])^ := ADouble;
  PackReversedByteArray(V);
end;

{ TAMF0Stream }

procedure TAMF0Stream.PackLongWord(ALongWord: LongWord);
var
  V: array[0..SizeOf(LongWord) - 1] of Byte;
begin
  PLongWord(@V[0])^ := ALongWord;
  PackReversedByteArray(V);
end;

procedure TAMF0Stream.PackWord(AWord: Word);
var
  V: array[0..SizeOf(Word) - 1] of Byte;
begin
  PWord(@V[0])^ := AWord;
  PackReversedByteArray(V);
end;

procedure TAMF0Stream.StartArray(Elements: Integer);
begin
  PackByte(TAMF0.STRICT_ARRAY_MARKER);
  PackLongWord(Elements);
end;

procedure TAMF0Stream.WriteNull;
begin
  PackByte(TAMF0.NULL_MARKER)
end;

procedure TAMF0Stream.WriteReference(ARefIndex: Integer);
begin
  PackByte(TAMF0.REFERENCE_MARKER);
  PackWord(ARefIndex);
end;

procedure TAMF0Stream.WriteString(AString: string);
var
  U: UTF8String;
  L: Cardinal;
begin
  U := UTF8String(AString);
  L := Length(U);
  if L > High(Word) then
  begin
    PackByte(TAMF0.LONG_STRING_MARKER);
    PackLongWord(L);
  end
  else
  begin
    PackByte(TAMF0.STRING_MARKER);
    PackWord(L);
  end;
  FStream.Write(U[1], Length(U));
end;

procedure TAMF0Stream.WriteArray(const AnArray: array of const);
var
  I: Integer;
begin
  StartArray(Length(AnArray));
  for I := 0 to High(AnArray) do
  begin
    with AnArray[I] do
    begin
      case VType of
        vtInteger:       WriteInteger(VInteger);
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

procedure TAMF0Stream.WriteBoolean(ABoolean: Boolean);
begin
  PackByte(TAMF0.BOOLEAN_MARKER);
  PackByte(Byte(ABoolean));
end;

procedure TAMF0Stream.WriteDateTime(ADateTime: TDateTime);
var
  UnixDate: Double;
begin
  PackByte(TAMF0.DATE_MARKER);
  UnixDate := Round((ADateTime - UnixDateDelta) * MSecsPerDay);
  PackDouble(UnixDate);
  PackWord(0); { Douteux }
end;

procedure TAMF0Stream.WriteDouble(ADouble: Double);
begin
  PackByte(TAMF0.NUMBER_MARKER);
  PackDouble(ADouble);
end;

procedure TAMF0Stream.WriteHash(const AnArrayOfKeys: array of string;
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

    PackByte(TAMF0.OBJECT_MARKER);

    Keys := D.Keys.ToArray;
    TArray.Sort<string>(Keys);
    for K in Keys do
    begin
      AnsiKey := RawByteString(K);
      PackWord(Length(AnsiKey));
      FStream.WriteBuffer(AnsiKey[1], Length(AnsiKey));

      with AnArrayOfValues[D[K]] do
      begin
        case VType of
          vtInteger:       WriteInteger(VInteger);
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

    PackWord(0);
    PackByte(TAMF0.OBJECT_END_MARKER);
  finally
    D.Free;
  end;
end;

procedure TAMF0Stream.WriteInteger(AnInteger: Integer);
begin
  PackByte(TAMF0.NUMBER_MARKER);
  PackDouble(AnInteger);
end;

{ TAMF3Stream }

constructor TAMF3Stream.Create;
begin
  inherited;
  FTraitsCache := TAMFCache<string>.Create;
  FObjectsCache := TAMFCache<Pointer>.Create;
  FStringCache := TAMFCache<UTF8String>.Create;
end;

destructor TAMF3Stream.Destroy;
begin
  FStringCache.Free;
  FObjectsCache.Free;
  FTraitsCache.Free;
  inherited;
end;

procedure TAMF3Stream.PackInteger(AnInteger: Integer);
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

procedure TAMF3Stream.PackUTF8String(AnUTF8String: UTF8String);
begin
  if AnUTF8String = '' then
    PackByte(TAMF3.EMPTY_STRING)
  else if FStringCache.HaveObject(AnUTF8String) then
    WriteReference(FStringCache[AnUTF8String])
  else
  begin
    FStringCache.AddObject(AnUTF8String);

    PackInteger((Length(AnUTF8String) shl 1) or 1);
    FStream.Write(AnUTF8String[1], Length(AnUTF8String));
  end;
end;

procedure TAMF3Stream.StartArray(Elements: Integer);
var
  Dummy: Pointer;
begin
  GetMem(Dummy, SizeOf(Dummy));
  FObjectsCache.AddObject(Dummy);
  FreeMem(Dummy);

  PackByte(TAMF3.ARRAY_MARKER);
  PackInteger((Elements shl 1) or $01);
  PackByte(TAMF3.CLOSE_DYNAMIC_ARRAY);
end;

procedure TAMF3Stream.WriteNull;
begin
  PackByte(TAMF3.NULL_MARKER);
end;

procedure TAMF3Stream.WriteReference(ARefIndex: Integer);
begin
  PackInteger(ARefIndex shl 1); { Décale la valeur vers la gauche pour forcer le bit de poids faible à zéro }
end;

procedure TAMF3Stream.WriteString(AString: string);
begin
  PackByte(TAMF3.STRING_MARKER);
  PackUTF8String(UTF8String(AString));
end;

procedure TAMF3Stream.WriteValue(AValue: TValue);
var
  C: TRttiContext;
  T: TRttiType;
  Fields: TArray<TRttiField>;
  F: TRttiField;
  P: Pointer;
begin
  OutputDebugString(PChar(AValue.ToString));

  case AValue.Kind of
    tkUnknown: PackByte(TAMF3.UNDEFINED_MARKER);
    tkInteger: WriteInteger(AValue.AsInteger);
    tkFloat:   WriteDouble(AValue.AsExtended);
    tkInt64:   WriteDouble(AValue.AsInt64);
    tkString,
    tkLString,
    tkWString,
    tkUString,
    tkChar,
    tkWChar:   WriteString(AValue.AsString);
    tkRecord:
    begin
      PackByte(TAMF3.OBJECT_MARKER);

      P := TValueData(AValue).FValueData.GetReferenceToRawData;
      if FObjectsCache.HaveObject(P) then
      begin
        WriteReference(FObjectsCache[P]);
        Exit;
      end;

      FObjectsCache.AddObject(P);

      C := TRttiContext.Create;
      try
        T := C.GetType(AValue.TypeInfo);
        Fields := T.GetFields;
        TArray.Sort<TRttiField>(Fields,
          TComparer<TRttiField>.Construct(
            function(const Left, Right: TRttiField): Integer
            begin
              Result := CompareStr(Left.Name, Right.Name);
            end
          )
        );

        if FTraitsCache.HaveObject('__default__') then
          PackInteger((FTraitsCache['__default__'] shl 2) or $01)  { reference }
        else
        begin
          FTraitsCache.AddObject('__default__');
          { Traits : No object ref, no trait ref + Dynamic + not Externalizable + no members }
          PackInteger($03 or ($02 shl 2) { or ($01 shl 2) or ($00 shl 4 } );
          PackUTF8String('');
        end;

        for F in Fields do
        begin
          PackUTF8String(UTF8String(F.Name));
          WriteValue(F.GetValue(TValueData(AValue).FValueData.GetReferenceToRawData));
        end;

        PackByte(TAMF3.CLOSE_DYNAMIC_OBJECT);
      finally
        C.Free;
      end;
    end
  else
    {
      tkEnumeration: ;
      tkSet: ;
      tkClass: ;
      tkMethod: ;
      tkVariant: ;
      tkArray: ;
      tkRecord: ;
      tkInterface: ;
      tkDynArray: ;
      tkClassRef: ;
      tkPointer: ;
      tkProcedure: ;
    }
    raise EAMFNotSupportedError.Create('Type not supported');
  end;
end;

procedure TAMF3Stream.WriteArray(const AnArray: array of const);
var
  I: Integer;
begin
  StartArray(Length(AnArray));
  for I := 0 to High(AnArray) do
  begin
    with AnArray[I] do
    begin
      case VType of
        vtInteger:       WriteInteger(VInteger);
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

procedure TAMF3Stream.WriteBoolean(ABoolean: Boolean);
begin
  if ABoolean then
    PackByte(TAMF3.TRUE_MARKER)
  else
    PackByte(TAMF3.FALSE_MARKER);
end;

procedure TAMF3Stream.WriteDateTime(ADateTime: TDateTime);
var
  UnixDate: Double;
begin
  PackByte(TAMF3.DATE_MARKER);
  PackByte(TAMF3.NULL_MARKER);
  UnixDate := Round((ADateTime - UnixDateDelta) * MSecsPerDay);
  PackDouble(UnixDate);
end;

procedure TAMF3Stream.WriteDouble(ADouble: Double);
begin
  PackByte(TAMF3.DOUBLE_MARKER);
  PackDouble(ADouble);
end;

procedure TAMF3Stream.WriteHash(const AnArrayOfKeys: array of string;
  const AnArrayOfValues: array of const);
var
  Keys: TArray<string>;
  K: string;
  I: Integer;
  D: TDictionary<string, Integer>;
begin
  D := TDictionary<string, Integer>.Create;
  try
    for I := 0 to High(AnArrayOfKeys) do
      D.Add(AnArrayOfKeys[I], I);

    PackByte(TAMF3.OBJECT_MARKER);

    if FTraitsCache.HaveObject('__default__') then
      PackInteger((FTraitsCache['__default__'] shl 2) or $01)
    else
    begin
      FTraitsCache.AddObject('__default__');
      { Traits : No object ref, no trait ref + Dynamic + not Externalizable + no members }
      PackInteger($03 or ($02 shl 2) { or ($01 shl 2) or ($00 shl 4 } );
      PackUTF8String('');
    end;

    Keys := D.Keys.ToArray;
    TArray.Sort<string>(Keys);
    for K in Keys do
    begin
      PackUTF8String(UTF8String(K));

      with AnArrayOfValues[D[K]] do
      begin
        case VType of
          vtInteger:       WriteInteger(VInteger);
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

    PackByte(TAMF3.CLOSE_DYNAMIC_OBJECT);
  finally
    D.Free;
  end;
end;

procedure TAMF3Stream.WriteInteger(AnInteger: Integer);
begin
  if (AnInteger < TAMF3.MIN_INTEGER) or (AnInteger > TAMF3.MAX_INTEGER) then
  begin
    PackByte(TAMF3.DOUBLE_MARKER);
    PackDouble(AnInteger);
  end
  else
  begin
    PackByte(TAMF3.INTEGER_MARKER);
    PackInteger(AnInteger);
  end;
end;

{ TAMF3Stream.TAMFCache<T> }

constructor TAMF3Stream.TAMFCache<T>.Create;
begin
  inherited Create;
  FCache := TDictionary<T, Integer>.Create;
  FIndex := 0;
end;

destructor TAMF3Stream.TAMFCache<T>.Destroy;
begin
  FCache.Free;
  inherited;
end;

procedure TAMF3Stream.TAMFCache<T>.AddObject(const Obj: T);
begin
  if not FCache.ContainsKey(Obj) then
  begin
    FCache.Add(Obj, FIndex);
    Inc(FIndex);
  end;
end;

function TAMF3Stream.TAMFCache<T>.GetIndex(const Obj: T): Integer;
begin
  Result := FCache[Obj];
end;

function TAMF3Stream.TAMFCache<T>.HaveObject(const Obj: T): Boolean;
begin
  Result := FCache.ContainsKey(Obj);
end;

end.
