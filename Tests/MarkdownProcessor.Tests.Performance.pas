{******************************************************************************}
{                                                                              }
{       MarkDown Processor - Test suite                                        }
{                                                                              }
{       Copyright (c) 2026 (Ethea S.r.l.)                                      }
{       Author: Carlo Barazzetta                                               }
{                                                                              }
{       https://github.com/EtheaDev/MarkdownProcessor                          }
{                                                                              }
{******************************************************************************}
{                                                                              }
{  Licensed under the Apache License, Version 2.0 (the "License");             }
{  you may not use this file except in compliance with the License.            }
{  You may obtain a copy of the License at                                     }
{                                                                              }
{      http://www.apache.org/licenses/LICENSE-2.0                              }
{                                                                              }
{  Unless required by applicable law or agreed to in writing, software         }
{  distributed under the License is distributed on an "AS IS" BASIS,           }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    }
{  See the License for the specific language governing permissions and         }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}
unit MarkdownProcessor.Tests.Performance;

{ Pathological inputs (the cases of cmark's test/pathological_tests.py, plus
  the extensions of this library) must be processed in roughly linear time:
  each one has to finish within a time budget, on a Debug build. The engine
  runs with every extension enabled. }

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPerformanceTests = class
  public
    [Test]
    [TestCase('nested strong emph', 'nested strong emph')]
    [TestCase('many emph closers with no openers', 'many emph closers with no openers')]
    [TestCase('many emph openers with no closers', 'many emph openers with no closers')]
    [TestCase('many link closers with no openers', 'many link closers with no openers')]
    [TestCase('many link openers with no closers', 'many link openers with no closers')]
    [TestCase('mismatched openers and closers', 'mismatched openers and closers')]
    [TestCase('openers and closers multiple of 3', 'openers and closers multiple of 3')]
    [TestCase('link openers and emph closers', 'link openers and emph closers')]
    [TestCase('pattern [ (]( repeated', 'pattern [ (]( repeated')]
    [TestCase('nested brackets', 'nested brackets')]
    [TestCase('nested block quotes', 'nested block quotes')]
    [TestCase('deeply nested lists', 'deeply nested lists')]
    [TestCase('U+0000 in input', 'U+0000 in input')]
    [TestCase('backticks', 'backticks')]
    [TestCase('unclosed links A', 'unclosed links A')]
    [TestCase('unclosed links B', 'unclosed links B')]
    [TestCase('unclosed html comments', 'unclosed html comments')]
    [TestCase('unclosed processing instructions', 'unclosed processing instructions')]
    [TestCase('unclosed CDATA', 'unclosed CDATA')]
    [TestCase('unclosed declarations', 'unclosed declarations')]
    [TestCase('many references', 'many references')]
    [TestCase('reference with long label', 'reference with long label')]
    [TestCase('tables with many rows', 'tables with many rows')]
    [TestCase('tildes', 'tildes')]
    [TestCase('dollars', 'dollars')]
    [TestCase('spaced dollars', 'spaced dollars')]
    [TestCase('double dollars', 'double dollars')]
    [TestCase('backtick math', 'backtick math')]
    [TestCase('wiki link openers', 'wiki link openers')]
    [TestCase('e-mail at signs', 'e-mail at signs')]
    [TestCase('www autolinks', 'www autolinks')]
    [TestCase('long paragraph', 'long paragraph')]
    procedure Performance_Pathological_WithinBudget(const CaseName: string);
  end;

implementation

uses
  System.SysUtils,
  System.Diagnostics,
  MarkdownUtils,
  MarkdownProcessor;

const
  BudgetMilliseconds = 3000;

function Rep(const S: string; Count: Integer): string;
var
  SB: TStringBuilder;
  I: Integer;
begin
  SB := TStringBuilder.Create(Length(S) * Count);
  try
    for I := 1 to Count do
      SB.Append(S);
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function BuildInput(const CaseName: string): string;
var
  SB: TStringBuilder;
  I: Integer;
begin
  if CaseName = 'nested strong emph' then
    Result := Rep('*a **a ', 30000) + 'b' + Rep(' a** a*', 30000)
  else if CaseName = 'many emph closers with no openers' then
    Result := Rep('a_ ', 30000)
  else if CaseName = 'many emph openers with no closers' then
    Result := Rep('_a ', 30000)
  else if CaseName = 'many link closers with no openers' then
    Result := Rep('a]', 30000)
  else if CaseName = 'many link openers with no closers' then
    Result := Rep('[a', 30000)
  else if CaseName = 'mismatched openers and closers' then
    Result := Rep('*a_ ', 30000)
  else if CaseName = 'openers and closers multiple of 3' then
    Result := 'a**b' + Rep('c* ', 30000)
  else if CaseName = 'link openers and emph closers' then
    Result := Rep('[ a_', 30000)
  else if CaseName = 'pattern [ (]( repeated' then
    Result := Rep('[ (](', 30000)
  else if CaseName = 'nested brackets' then
    Result := Rep('[', 30000) + 'a' + Rep(']', 30000)
  else if CaseName = 'nested block quotes' then
    Result := Rep('> ', 30000) + 'a'
  else if CaseName = 'deeply nested lists' then
  begin
    SB := TStringBuilder.Create;
    try
      for I := 0 to 999 do
        SB.Append(Rep('  ', I)).Append('* a'#10);
      Result := SB.ToString;
    finally
      SB.Free;
    end;
  end
  else if CaseName = 'U+0000 in input' then
    Result := Rep('abc'#0'de'#0, 30000)
  else if CaseName = 'backticks' then
  begin
    SB := TStringBuilder.Create;
    try
      for I := 1 to 3000 do
        SB.Append('e').Append(Rep('`', I));
      Result := SB.ToString;
    finally
      SB.Free;
    end;
  end
  else if CaseName = 'unclosed links A' then
    Result := Rep('[a](<b', 30000)
  else if CaseName = 'unclosed links B' then
    Result := Rep('[a](b', 30000)
  // the "x" keeps them inline (at the start of a line they open an HTML block)
  else if CaseName = 'unclosed html comments' then
    Result := 'x ' + Rep('<!-- ', 30000)
  else if CaseName = 'unclosed processing instructions' then
    Result := 'x ' + Rep('<? ', 30000)
  else if CaseName = 'unclosed CDATA' then
    Result := 'x ' + Rep('<![CDATA[ ', 30000)
  else if CaseName = 'unclosed declarations' then
    Result := 'x ' + Rep('<!A ', 30000)
  else if CaseName = 'many references' then
  begin
    SB := TStringBuilder.Create;
    try
      for I := 1 to 30000 do
        SB.Append('[').Append(I).Append(']: /url').Append(#10);
      for I := 1 to 30000 do
        SB.Append('[').Append(I).Append('] ');
      Result := SB.ToString;
    finally
      SB.Free;
    end;
  end
  else if CaseName = 'reference with long label' then
    Result := '[' + Rep('a', 50000) + ']' + Rep(' [x]', 10000)
  else if CaseName = 'tables with many rows' then
    Result := '| a | b |'#10'|---|---|'#10 + Rep('| *x* | `y` |'#10, 30000)
  else if CaseName = 'tildes' then
    Result := Rep('~a ~~b ', 30000)
  else if CaseName = 'dollars' then
    Result := Rep('$a', 30000)
  else if CaseName = 'spaced dollars' then
    Result := Rep(' $a', 30000)
  else if CaseName = 'double dollars' then
    Result := Rep(' $$a', 30000)
  else if CaseName = 'backtick math' then
    Result := Rep(' $`a', 30000)
  else if CaseName = 'wiki link openers' then
    Result := Rep('[[a', 30000)
  else if CaseName = 'e-mail at signs' then
    Result := Rep('a@b', 30000)
  else if CaseName = 'www autolinks' then
    Result := Rep('www.a.com ', 30000)
  else if CaseName = 'long paragraph' then
    Result := Rep('word *em* **strong** `code` [link](/u) <b>x</b> ', 20000)
  else
    raise Exception.CreateFmt('Unknown case "%s"', [CaseName]);
end;

procedure TPerformanceTests.Performance_Pathological_WithinBudget(const CaseName: string);
var
  Input: string;
  Processor: TMarkdownProcessor;
  Watch: TStopwatch;
  Html: string;
begin
  Input := BuildInput(CaseName);
  Processor := TMarkdownProcessor.CreateDialect(mdGFM);
  try
    Processor.AllowUnsafe := True;
    Processor.Config.Extensions := [Low(TMarkdownExtension)..High(TMarkdownExtension)];
    Watch := TStopwatch.StartNew;
    Html := Processor.Process(Input);
    Watch.Stop;
  finally
    Processor.Free;
  end;
  Assert.IsTrue(Html <> '', 'No output');
  Assert.IsTrue(Watch.ElapsedMilliseconds <= BudgetMilliseconds,
    Format('%s: %d ms for %d characters (budget %d ms)',
      [CaseName, Watch.ElapsedMilliseconds, Length(Input), BudgetMilliseconds]));
  TDUnitX.CurrentRunner.Log(TLogLevel.Information, Format('%s: %d ms', [CaseName, Watch.ElapsedMilliseconds]));
end;

initialization
  TDUnitX.RegisterTestFixture(TPerformanceTests);

end.
