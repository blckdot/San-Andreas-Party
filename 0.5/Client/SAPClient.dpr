program SAPClient;

uses
  Forms,
  Unit1 in 'Unit1.pas' {frmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'San Andreas Party';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
