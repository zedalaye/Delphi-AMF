unit AMF.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TForm2 = class(TForm)
    btTest: TButton;
    mDump: TMemo;
    procedure btTestClick(Sender: TObject);
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;

var
  Form2: TForm2;

implementation

uses
  AMF.Message, AMF.Test.Runner;

{$R *.dfm}

procedure TForm2.btTestClick(Sender: TObject);
const
  INTEGERS : array[0..12] of Integer = (
    0,
    $00000080 - 1, $00000080, $00000080 + 1,
    $00004000 - 1, $00004000, $00004000 + 1,
    $00200000 - 1, $00200000, $00200000 + 1,
    $40000000 - 1, $40000000, $40000000 + 1
  );
var
  S: TAMFStream;
  I: Integer;
begin
  S := TAMFStream.Create(v3);
  try
    for I in INTEGERS do
    begin
      S.Clear;
      S.WriteInteger(I);
      mDump.Lines.Add(Format('%d = %s', [I, S.ToDebugString]));
    end;
  finally
    S.Free;
  end;

  mDump.Lines.Add('Running AMF0 Serializer Test Suite');
  TAMF0TestRunner.RunTests(mDump.Lines);

  mDump.Lines.Add('');
  mDump.Lines.Add('Running AMF3 Serializer Test Suite');
  TAMF3TestRunner.RunTests(mDump.Lines);
end;

end.
