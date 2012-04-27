program AMF;

uses
  Vcl.Forms,
  AMF.Main in 'AMF.Main.pas' {Form2},
  AMF.Test.Runner in 'AMF.Test.Runner.pas',
  AMF.Message in 'AMF.Message.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
