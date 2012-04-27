unit AMF.Test.Runner;

interface

uses
  SysUtils, Classes, Generics.Collections, DateUtils, Math,
  AMF.Message;

type
  TAMFTestRunner = class
    class function CheckEquals(AMFData: RawByteString; const FixtureFileName: string; LengthCheck: Integer = MaxInt): Boolean;
    class procedure LogTestResult(Results: TStrings; const Description: string; Result: Boolean);
    class procedure RunTests(Results: TStrings); virtual; abstract;
  end;

  TAMF0TestRunner = class(TAMFTestRunner)
    class function TestNulls: Boolean;
    class function TestBooleans: Boolean;
    class function TestNumbers: Boolean;
    class function TestStrings: Boolean;
    class function TestTimes: Boolean;
    class function TestDates: Boolean;
    class function TestArrays: Boolean;
    class function TestHashes: Boolean;

    class procedure RunTests(Results: TStrings); override;
  end;

  TAMF3TestRunner = class(TAMFTestRunner)
    class function TestNulls: Boolean;
    class function TestFalses: Boolean;
    class function TestTrues: Boolean;
    class function TestMaxIntegers: Boolean;
    class function TestZeroes: Boolean;
    class function TestMinIntegers: Boolean;
    class function TestLargeMaxIntegers: Boolean;
    class function TestLargeMinIntegers: Boolean;
    class function TestFloats: Boolean;
    class function TestBigNums: Boolean;
    class function TestSimpleStrings: Boolean;
    class function TestSmallStrings: Boolean;
    class function TestDateTimes: Boolean;
    class function TestHashes: Boolean;

    class procedure RunTests(Results: TStrings); override;
  end;

implementation

const
  FIXTURES = '..\..\fixtures\objects\';

{ TAMFTestRunner }

class function TAMFTestRunner.CheckEquals(AMFData: RawByteString;
  const FixtureFileName: string; LengthCheck: Integer): Boolean;
var
  F: TFileStream;
  Reference: RawByteString;
  A, R: TBytes;
begin
  F := TFileStream.Create(FIXTURES + FixtureFileName, fmOpenRead);
  try
    SetLength(Reference, F.Size);
    F.Read(PAnsiChar(Reference)^, F.Size);
  finally
    F.Free;
  end;

  A := BytesOf(Copy(AMFData, 1, LengthCheck));
  R := BytesOf(Copy(Reference, 1, LengthCheck));

  Result := (Length(A) = Length(R)) and CompareMem(@A[0], @R[0], Length(A));
end;

class procedure TAMFTestRunner.LogTestResult(Results: TStrings;
  const Description: string; Result: Boolean);
begin
  if Result then
    Results.Add(Description + ': OK')
  else
    Results.Add(Description + ': Failed');
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

class function TAMF0TestRunner.TestArrays: Boolean;
begin
  with TAMFStream.Create(v0) do
  begin
    WriteArray(['a', 'b', 'c', 'd']);
    Result := CheckEquals(ToRawString, 'amf0-strict-array.bin');
    Free;
  end;
end;

class function TAMF0TestRunner.TestBooleans: Boolean;
begin
  with TAMFStream.Create(v0) do
  begin
    WriteBoolean(True);
    Result := CheckEquals(ToRawString, 'amf0-boolean.bin');
    Free;
  end;
end;

class function TAMF0TestRunner.TestDates: Boolean;
begin
  with TAMFStream.Create(v0) do
  begin
    WriteDateTime(EncodeDate(2020, 5, 30));
    Result := CheckEquals(ToRawString, 'amf0-date.bin', 9);
    Free;
  end;
end;

class function TAMF0TestRunner.TestHashes: Boolean;
begin
  with TAMFStream.Create(v0) do
  begin
    WriteHash(['foo', 'baz'], ['bar', nil]);
    Result := CheckEquals(ToRawString, 'amf0-untyped-object.bin');
    Free;
  end;
end;

class function TAMF0TestRunner.TestNulls: Boolean;
begin
  with TAMFStream.Create(v0) do
  begin
    WriteNull;
    Result := CheckEquals(ToRawString, 'amf0-null.bin');
    Free;
  end;
end;

class function TAMF0TestRunner.TestNumbers: Boolean;
begin
  with TAMFStream.Create(v0) do
  begin
    WriteDouble(3.5);
    Result := CheckEquals(ToRawString, 'amf0-number.bin');
    Free;
  end;
end;

class function TAMF0TestRunner.TestStrings: Boolean;
begin
  with TAMFStream.Create(v0) do
  begin
    WriteString('this is a テスト');
    Result := CheckEquals(ToRawString, 'amf0-string.bin');
    Free;
  end;
end;

class function TAMF0TestRunner.TestTimes: Boolean;
begin
  with TAMFStream.Create(v0) do
  begin
    WriteDateTime(EncodeDateTime(2003, 2, 13, 5, 0, 0, 0));
    Result := CheckEquals(ToRawString, 'amf0-time.bin', 9);
    Free;
  end;
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
end;

class function TAMF3TestRunner.TestBigNums: Boolean;
begin
  with TAMFStream.Create(v3) do
  begin
    WriteDouble(Power(2, 1000));
    Result := CheckEquals(ToRawString, 'amf3-bigNum.bin');
    Free;
  end;
end;

class function TAMF3TestRunner.TestDateTimes: Boolean;
begin
  with TAMFStream.Create(v3) do
  begin
    WriteDateTime(EncodeDateTime(1970, 1, 1, 0, 0, 0, 0));
    Result := CheckEquals(ToRawString, 'amf3-date.bin');
    Free;
  end;
end;

class function TAMF3TestRunner.TestFalses: Boolean;
begin
  with TAMFStream.Create(v3) do
  begin
    WriteBoolean(False);
    Result := CheckEquals(ToRawString, 'amf3-false.bin');
    Free;
  end;
end;

class function TAMF3TestRunner.TestFloats: Boolean;
begin
  with TAMFStream.Create(v3) do
  begin
    WriteDouble(3.5);
    Result := CheckEquals(ToRawString, 'amf3-float.bin');
    Free;
  end;
end;

class function TAMF3TestRunner.TestHashes: Boolean;
begin
  with TAMFStream.Create(v3) do
  begin
    WriteHash(['answer', 'foo'], [42, 'bar']);
    Result := CheckEquals(ToRawString, 'amf3-hash.bin');
    Free;
  end;
end;

class function TAMF3TestRunner.TestLargeMaxIntegers: Boolean;
begin
  with TAMFStream.Create(v3) do
  begin
    WriteInteger(TAMFStream.MAX_INTEGER + 1);
    Result := CheckEquals(ToRawString, 'amf3-large-max.bin');
    Free;
  end;
end;

class function TAMF3TestRunner.TestLargeMinIntegers: Boolean;
begin
  with TAMFStream.Create(v3) do
  begin
    WriteInteger(TAMFStream.MIN_INTEGER - 1);
    Result := CheckEquals(ToRawString, 'amf3-large-min.bin');
    Free;
  end;
end;

class function TAMF3TestRunner.TestMaxIntegers: Boolean;
begin
  with TAMFStream.Create(v3) do
  begin
    WriteInteger(TAMFStream.MAX_INTEGER);
    Result := CheckEquals(ToRawString, 'amf3-max.bin');
    Free;
  end;
end;

class function TAMF3TestRunner.TestMinIntegers: Boolean;
begin
  with TAMFStream.Create(v3) do
  begin
    WriteInteger(TAMFStream.MIN_INTEGER);
    Result := CheckEquals(ToRawString, 'amf3-min.bin');
    Free;
  end;
end;

class function TAMF3TestRunner.TestNulls: Boolean;
begin
  with TAMFStream.Create(v3) do
  begin
    WriteNull;
    Result := CheckEquals(ToRawString, 'amf3-null.bin');
    Free;
  end;
end;

class function TAMF3TestRunner.TestSimpleStrings: Boolean;
begin
  with TAMFStream.Create(v3) do
  begin
    WriteString('String . String');
    Result := CheckEquals(ToRawString, 'amf3-string.bin');
    Free;
  end;
end;

class function TAMF3TestRunner.TestSmallStrings: Boolean;
begin
  with TAMFStream.Create(v3) do
  begin
    WriteString('foo');
    Result := CheckEquals(ToRawString, 'amf3-symbol.bin');
    Free;
  end;
end;

class function TAMF3TestRunner.TestTrues: Boolean;
begin
  with TAMFStream.Create(v3) do
  begin
    WriteBoolean(True);
    Result := CheckEquals(ToRawString, 'amf3-true.bin');
    Free;
  end;
end;

class function TAMF3TestRunner.TestZeroes: Boolean;
begin
  with TAMFStream.Create(v3) do
  begin
    WriteInteger(0);
    Result := CheckEquals(ToRawString, 'amf3-0.bin');
    Free;
  end;
end;

end.
