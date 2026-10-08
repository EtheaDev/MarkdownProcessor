program MarkdownProcessorDemo;

{ Demo of TMarkdownToHTML: converts a Markdown text into HTML and shows the
  result in the browser. }

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {MainForm},
  MarkdownProcessorComponents in '..\..\source\MarkdownProcessorComponents.pas';

{$R *.res}

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Markdown Processor Demo - TMarkdownToHTML Component';
  Application.CreateForm(TMainForm, MainFormInstance);
  Application.Run;
end.
