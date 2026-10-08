program MarkdownProcessor.Tests;

{ DUnitX conformance and regression suite of MarkdownProcessor.
  Requires Delphi 13 (the library itself stays compatible with Delphi XE3).
  Build and run both platforms with RunTests.cmd; see docs\COMMONMARK_PLAN.md. }

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  MarkdownProcessor.Tests.Corpus in 'MarkdownProcessor.Tests.Corpus.pas',
  MarkdownProcessor.Tests.Runner in 'MarkdownProcessor.Tests.Runner.pas',
  MarkdownProcessor.Tests.CommonMark in 'MarkdownProcessor.Tests.CommonMark.pas',
  MarkdownProcessor.Tests.GFM in 'MarkdownProcessor.Tests.GFM.pas',
  MarkdownProcessor.Tests.Math in 'MarkdownProcessor.Tests.Math.pas',
  MarkdownProcessor.Tests.Legacy in 'MarkdownProcessor.Tests.Legacy.pas',
  MarkdownProcessor.Tests.Safety in 'MarkdownProcessor.Tests.Safety.pas',
  MarkdownProcessor in '..\source\MarkdownProcessor.pas',
  MarkdownUtils in '..\source\MarkdownUtils.pas',
  MarkdownDaringFireball in '..\source\MarkdownDaringFireball.pas',
  MarkdownCommonMark in '..\source\MarkdownCommonMark.pas',
  MarkdownTxtMark in '..\source\MarkdownTxtMark.pas',
  MarkdownTables in '..\source\MarkdownTables.pas',
  MarkdownMathCode in '..\source\MarkdownMathCode.pas',
  MarkdownAST in '..\source\MarkdownAST.pas',
  MarkdownTextUtils in '..\source\MarkdownTextUtils.pas',
  MarkdownEntities in '..\source\MarkdownEntities.pas',
  MarkdownLinkRefs in '..\source\MarkdownLinkRefs.pas',
  MarkdownBlockParser in '..\source\MarkdownBlockParser.pas',
  MarkdownHtmlRenderer in '..\source\MarkdownHtmlRenderer.pas',
  MarkdownInlineParser in '..\source\MarkdownInlineParser.pas',
  MarkdownGFM in '..\source\MarkdownGFM.pas',
  MarkdownMath in '..\source\MarkdownMath.pas',
  MarkdownAlerts in '..\source\MarkdownAlerts.pas',
  MarkdownProcessor.Tests.Alerts in 'MarkdownProcessor.Tests.Alerts.pas',
  MarkdownLegacyExt in '..\source\MarkdownLegacyExt.pas',
  MarkdownProcessor.Tests.Extensions in 'MarkdownProcessor.Tests.Extensions.pas',
  MarkdownProcessor.Tests.Performance in 'MarkdownProcessor.Tests.Performance.pas',
  MarkdownProcessor.Tests.Hooks in 'MarkdownProcessor.Tests.Hooks.pas',
  MarkdownProcessor.Tests.AST in 'MarkdownProcessor.Tests.AST.pas',
  MarkdownProcessorComponents in '..\source\MarkdownProcessorComponents.pas',
  MarkdownProcessor.Tests.Component in 'MarkdownProcessor.Tests.Component.pas';

begin
  TMarkdownTestRunner.Run;
end.
