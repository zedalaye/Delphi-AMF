unit AMF.Test.Runner;

interface

uses
  SysUtils, Classes, Rtti, Generics.Collections, DateUtils, Math,
  AMF.Message, AMF.Types;

type
  TAMFTestRunner = class
    class function CheckEquals(AMFData: TAMFBaseStream; const FixtureFileName: string; LengthCheck: Integer = MaxInt): string;
    class procedure LogTestResult(Results: TStrings; const Description: string; const Result: string);
    class procedure RunTests(Results: TStrings); virtual; abstract;
  end;

  TAMF0TestRunner = class(TAMFTestRunner)
    class function TestNulls: string;
    class function TestBooleans: string;
    class function TestNumbers: string;
    class function TestStrings: string;
    class function TestTimes: string;
    class function TestDates: string;
    class function TestArrays: string;
    class function TestHashes: string;

    class procedure RunTests(Results: TStrings); override;
  end;

  TAMF3TestRunner = class(TAMFTestRunner)
    class function TestNulls: string;
    class function TestFalses: string;
    class function TestTrues: string;
    class function TestMaxIntegers: string;
    class function TestZeroes: string;
    class function TestMinIntegers: string;
    class function TestLargeMaxIntegers: string;
    class function TestLargeMinIntegers: string;
    class function TestFloats: string;
    class function TestBigNums: string;
    class function TestSimpleStrings: string;
    class function TestSmallStrings: string;
    class function TestDateTimes: string;
    class function TestHashes: string;
    class function TestEmptyArrays: string;
    class function TestPrimitiveArrays: string;
    class function TestMixedArrays: string;
    class function TestArrayCollections: string;
    class function TestByteArrays: string;

    class procedure RunTests(Results: TStrings); override;
  end;

implementation

const
  FIXTURES = '..\..\fixtures\objects\';

{ TAMFTestRunner }

class function TAMFTestRunner.CheckEquals(AMFData: TAMFBaseStream;
  const FixtureFileName: string; LengthCheck: Integer): string;

  function DumpDebugString(const s: RawByteString): string;
  var
    B: AnsiChar;
    WasChar: Boolean;
  begin
    Result := '';
    WasChar := False;
    for B in s do
      if (Byte(B) < 32) or (Byte(B) >= 128) then
      begin
        Result := Result + ' $' + IntToHex(Byte(B), 2);
        WasChar := False;
      end
      else
      begin
        if not WasChar then
          Result := Result + ' ';
        Result := Result + Char(B);
        WasChar := True;
      end;
  end;

var
  F: TFileStream;
  Mine, Theirs: RawByteString;
  A, R: TBytes;
begin
  Mine := AMFData.ToRawString;

  F := TFileStream.Create(FIXTURES + FixtureFileName, fmOpenRead);
  try
    SetLength(Theirs, F.Size);
    F.Read(PAnsiChar(Theirs)^, F.Size);
  finally
    F.Free;
  end;

  A := BytesOf(Copy(Mine, 1, LengthCheck));
  R := BytesOf(Copy(Theirs, 1, LengthCheck));

  if (Length(A) = Length(R)) and CompareMem(@A[0], @R[0], Length(A)) then
    Result := 'OK'
  else
    Result := 'Failed' + #13#10 +
      '  Mine:  ' + DumpDebugString(Mine) + #13#10 +
      '  Theirs:' + DumpDebugString(Theirs);
end;

class procedure TAMFTestRunner.LogTestResult(Results: TStrings;
  const Description, Result: string);
begin
  Results.Add(Description + ': ' + Result);
end;

{ TAMF0TestRunner }

class procedure TAMF0TestRunner.RunTests(Results: TStrings);
begin
  LogTestResult(Results, 'Nulls',    TestNulls);
  LogTestResult(Results, 'Booleans', TestBooleans);
  LogTestResult(Results, 'Numbers',  TestNumbers);
  LogTestResult(Results, 'Strings',  TestStrings);
  LogTestResult(Results, 'Arrays',   TestArrays);
  LogTestResult(Results, 'Times',    TestTimes);
  LogTestResult(Results, 'Dates',    TestDates);
  LogTestResult(Results, 'Hashes',   TestHashes);
end;

class function TAMF0TestRunner.TestArrays: string;
var
  s: TAMF0Stream;
begin
  s := TAMF0Stream.Create;
  s.WriteArray(['a', 'b', 'c', 'd']);
  Result := CheckEquals(s, 'amf0-strict-array.bin');
  s.Free;
end;

class function TAMF0TestRunner.TestBooleans: string;
var
  s: TAMF0Stream;
begin
  s := TAMF0Stream.Create;
  s.WriteBoolean(True);
  Result := CheckEquals(s, 'amf0-boolean.bin');
  s.Free;
end;

class function TAMF0TestRunner.TestDates: string;
var
  s: TAMF0Stream;
begin
  s := TAMF0Stream.Create;
  s.WriteDateTime(EncodeDate(2020, 5, 30));
  Result := CheckEquals(s, 'amf0-date.bin', 9);
  s.Free;
end;

class function TAMF0TestRunner.TestHashes: string;
var
  s: TAMF0Stream;
begin
  s := TAMF0Stream.Create;
  s.WriteHash(['foo', 'baz'], ['bar', nil]);
  Result := CheckEquals(s, 'amf0-untyped-object.bin');
  s.Free;
end;

class function TAMF0TestRunner.TestNulls: string;
var
  s: TAMF0Stream;
begin
  s := TAMF0Stream.Create;
  s.WriteNull;
  Result := CheckEquals(s, 'amf0-null.bin');
  s.Free;
end;

class function TAMF0TestRunner.TestNumbers: string;
var
  s: TAMF0Stream;
begin
  s := TAMF0Stream.Create;
  s.WriteDouble(3.5);
  Result := CheckEquals(s, 'amf0-number.bin');
  s.Free;
end;

class function TAMF0TestRunner.TestStrings: string;
var
  s: TAMF0Stream;
begin
  s := TAMF0Stream.Create;
  s.WriteString('this is a テスト');
  Result := CheckEquals(s, 'amf0-string.bin');
  s.Free;
end;

class function TAMF0TestRunner.TestTimes: string;
var
  s: TAMF0Stream;
begin
  s := TAMF0Stream.Create;
  s.WriteDateTime(EncodeDateTime(2003, 2, 13, 5, 0, 0, 0));
  Result := CheckEquals(s, 'amf0-time.bin', 9);
  s.Free;
end;

{ TAMF3TestRunner }

class procedure TAMF3TestRunner.RunTests(Results: TStrings);
begin
  LogTestResult(Results, 'Nulls',            TestNulls);
  LogTestResult(Results, 'Falses',           TestFalses);
  LogTestResult(Results, 'Trues',            TestTrues);
  LogTestResult(Results, 'MaxIntegers',      TestMaxIntegers);
  LogTestResult(Results, 'MinIntegers',      TestMinIntegers);
  LogTestResult(Results, 'Zeros',            TestZeroes);
  LogTestResult(Results, 'LargeMaxIntegers', TestLargeMaxIntegers);
  LogTestResult(Results, 'LargeMinIntegers', TestLargeMinIntegers);
  LogTestResult(Results, 'Floats',           TestFloats);
  LogTestResult(Results, 'BigNums',          TestBigNums);
  LogTestResult(Results, 'SimpleStrings',    TestSimpleStrings);
  LogTestResult(Results, 'SmallStrings',     TestSmallStrings);
  LogTestResult(Results, 'DateTimes',        TestDateTimes);
  LogTestResult(Results, 'Hashes',           TestHashes);
  LogTestResult(Results, 'EmptyArrays',      TestEmptyArrays);
  LogTestResult(Results, 'PrimitiveArrays',  TestPrimitiveArrays);
  LogTestResult(Results, 'MixedArrays',      TestMixedArrays);
  LogTestResult(Results, 'ArrayCollections', TestArrayCollections);
  LogTestResult(Results, 'ByteArrays',       TestByteArrays);
end;

class function TAMF3TestRunner.TestArrayCollections: string;
var
  s: TAMF3Stream;
begin
  s := TAMF3Stream.Create;
  s.WriteArray(['foo', 'bar'], True);
  Result := CheckEquals(s, 'amf3-array-collection.bin');
  s.Free;
end;

class function TAMF3TestRunner.TestBigNums: string;
var
  s: TAMF3Stream;
begin
  s := TAMF3Stream.Create;
  s.WriteDouble(Power(2, 1000));
  Result := CheckEquals(s, 'amf3-bigNum.bin');
  s.Free;
end;

class function TAMF3TestRunner.TestByteArrays: string;
var
  s: TAMF3Stream;
begin
  s := TAMF3Stream.Create;
  s.WriteByteArray(UTF8String(#0 + #3 + 'これtest@'));
  Result := CheckEquals(s, 'amf3-byte-array.bin');
  s.Free;
end;

class function TAMF3TestRunner.TestDateTimes: string;
var
  s: TAMF3Stream;
begin
  s := TAMF3Stream.Create;
  s.WriteDateTime(EncodeDateTime(1970, 1, 1, 0, 0, 0, 0));
  Result := CheckEquals(s, 'amf3-date.bin');
  s.Free;
end;

class function TAMF3TestRunner.TestEmptyArrays: string;
var
  s: TAMF3Stream;
begin
  s := TAMF3Stream.Create;
  s.WriteArray([]);
  Result := CheckEquals(s, 'amf3-empty-array.bin');
  s.Free;
end;

class function TAMF3TestRunner.TestPrimitiveArrays: string;
var
  s: TAMF3Stream;
begin
  s := TAMF3Stream.Create;
  s.WriteArray([1, 2, 3, 4, 5]);
  Result := CheckEquals(s, 'amf3-primitive-array.bin');
  s.Free;
end;

class function TAMF3TestRunner.TestFalses: string;
var
  s: TAMF3Stream;
begin
  s := TAMF3Stream.Create;
  s.WriteBoolean(False);
  Result := CheckEquals(s, 'amf3-false.bin');
  s.Free;
end;

class function TAMF3TestRunner.TestFloats: string;
var
  s: TAMF3Stream;
begin
  s := TAMF3Stream.Create;
  s.WriteDouble(3.5);
  Result := CheckEquals(s, 'amf3-float.bin');
  s.Free;
end;

class function TAMF3TestRunner.TestHashes: string;
var
  s: TAMF3Stream;
begin
  s := TAMF3Stream.Create;
  s.WriteHash(['answer', 'foo'], [42, 'bar']);
  Result := CheckEquals(s, 'amf3-hash.bin');
  s.Free;
end;

class function TAMF3TestRunner.TestLargeMaxIntegers: string;
var
  s: TAMF3Stream;
begin
  s := TAMF3Stream.Create;
  s.WriteInteger(TAMF3.MAX_INTEGER + 1);
  Result := CheckEquals(s, 'amf3-large-max.bin');
  s.Free;
end;

class function TAMF3TestRunner.TestLargeMinIntegers: string;
var
  s: TAMF3Stream;
begin
  s := TAMF3Stream.Create;
  s.WriteInteger(TAMF3.MIN_INTEGER - 1);
  Result := CheckEquals(s, 'amf3-large-min.bin');
  s.Free;
end;

class function TAMF3TestRunner.TestMaxIntegers: string;
var
  s: TAMF3Stream;
begin
  s := TAMF3Stream.Create;
  s.WriteInteger(TAMF3.MAX_INTEGER);
  Result := CheckEquals(s, 'amf3-max.bin');
  s.Free;
end;

class function TAMF3TestRunner.TestMinIntegers: string;
var
  s: TAMF3Stream;
begin
  s := TAMF3Stream.Create;
  s.WriteInteger(TAMF3.MIN_INTEGER);
  Result := CheckEquals(s, 'amf3-min.bin');
  s.Free;
end;

class function TAMF3TestRunner.TestMixedArrays: string;
type
  TFoo1 = record foo_one: string end;
  TFoo2 = record foo_two: string end;
  TFoo3 = record foo_three: Integer end;
var
  s: TAMF3Stream;
  foo1: TFoo1;
  foo2: TFoo2;
  foo3: TFoo3;
  v1, v2, v3: TValue;
begin
  foo1.foo_one   := 'bar_one';
  foo2.foo_two   := '';
  foo3.foo_three := 42;

  v1 := TValue.From<TFoo1>(foo1);
  v2 := TValue.From<TFoo2>(foo2);
  v3 := TValue.From<TFoo3>(foo3);

  s := TAMF3Stream.Create;
  s.StartArray(13);
    s.WriteValue(v1);
    s.WriteValue(v2);
    s.WriteValue(v3);
    s.WriteHash([], []);
    s.StartArray(3);
      s.WriteValue(v1);
      s.WriteValue(v2);
      s.WriteValue(v3);
    s.WriteArray([]);
    s.WriteValue(42);
    s.WriteValue('');
    s.WriteArray([]);
    s.WriteValue('');
    s.WriteHash([], []);
    s.WriteValue('bar_one');
    s.WriteValue(v3);

  Result := CheckEquals(s, 'amf3-mixed-array.bin');
  s.Free;
end;

class function TAMF3TestRunner.TestNulls: string;
var
  s: TAMF3Stream;
begin
  s := TAMF3Stream.Create;
  s.WriteNull;
  Result := CheckEquals(s, 'amf3-null.bin');
  s.Free;
end;

class function TAMF3TestRunner.TestSimpleStrings: string;
var
  s: TAMF3Stream;
begin
  s := TAMF3Stream.Create;
  s.WriteString('String . String');
  Result := CheckEquals(s, 'amf3-string.bin');
  s.Free;
end;

class function TAMF3TestRunner.TestSmallStrings: string;
var
  s: TAMF3Stream;
begin
  s := TAMF3Stream.Create;
  s.WriteString('foo');
  Result := CheckEquals(s, 'amf3-symbol.bin');
  s.Free;
end;

class function TAMF3TestRunner.TestTrues: string;
var
  s: TAMF3Stream;
begin
  s := TAMF3Stream.Create;
  s.WriteBoolean(True);
  Result := CheckEquals(s, 'amf3-true.bin');
  s.Free;
end;

class function TAMF3TestRunner.TestZeroes: string;
var
  s: TAMF3Stream;
begin
  s := TAMF3Stream.Create;
  s.WriteInteger(0);
  Result := CheckEquals(s, 'amf3-0.bin');
  s.Free;
end;

end.
