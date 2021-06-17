program SAP;

uses
  Forms,
  untMain in 'untMain.pas' {frmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'San Andreas Party';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
