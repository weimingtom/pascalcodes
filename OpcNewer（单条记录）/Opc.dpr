program Opc;

uses
  Forms,
  MainLib in 'MainLib.pas' {MainForm},
  OPC_AE in 'opc\OPC_AE.pas',
  OPCCOMN in 'opc\OPCCOMN.pas',
  OPCDA in 'opc\OPCDA.pas',
  OPCerror in 'opc\OPCerror.pas',
  OPCHDA in 'opc\OPCHDA.pas',
  OPCSEC in 'opc\OPCSEC.pas',
  OPCtypes in 'opc\OPCtypes.pas',
  OPCutils in 'opc\OPCutils.pas',
  BaseTypes in 'BaseTypes.pas',
  Common in 'tool\Common.pas',
  Ini in 'tool\Ini.pas',
  LogsUnit in 'tool\LogsUnit.pas',
  superobject in 'tool\superobject.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
