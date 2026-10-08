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
unit MarkdownProcessor.Tests.Alerts;

{ GitHub alerts (mexAlerts). Corpus: Tests\specs\alerts.json, run on mdGFM with
  mexAlerts enabled. }

interface

uses
  DUnitX.TestFramework,
  MarkdownProcessor.Tests.Corpus;

type
  [TestFixture]
  TAlertsTests = class
  private
    FCorpus: TCorpus;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;

    [Test]
    [TestCase('Alert types', 'Alert types')]
    [TestCase('Alert content', 'Alert content')]
    [TestCase('Not an alert', 'Not an alert')]
    procedure Alerts_Section_Matches(const Section: string);

    [Test]
    procedure Alerts_OffByDefault_KeepsBlockQuote;
  end;

implementation

uses
  System.SysUtils,
  MarkdownUtils,
  MarkdownProcessor;

function CreateAlertsProcessor: TMarkdownProcessor;
begin
  Result := TMarkdownProcessor.CreateDialect(mdGFM);
  Result.AllowUnsafe := True;
  Result.Config.Extensions := Result.Config.Extensions + [mexAlerts];
end;

procedure TAlertsTests.SetupFixture;
begin
  FCorpus := TCorpus.Create('Alerts', 'alerts.json', 'mdGFM + mexAlerts', CreateAlertsProcessor);
end;

procedure TAlertsTests.TearDownFixture;
begin
  FreeAndNil(FCorpus);
end;

procedure TAlertsTests.Alerts_Section_Matches(const Section: string);
begin
  const Failures = FCorpus.CheckSection(Section);
  if Failures <> '' then
    Assert.Fail(Failures);
end;

procedure TAlertsTests.Alerts_OffByDefault_KeepsBlockQuote;
begin
  for var Dialect in [mdCommonMark, mdGFM] do
  begin
    const Processor = TMarkdownProcessor.CreateDialect(Dialect);
    try
      Assert.AreEqual('<blockquote>'#10'<p>[!NOTE]'#10'Body</p>'#10'</blockquote>'#10,
        NormalizeLineEndings(Processor.Process('> [!NOTE]'#10'> Body')));
    finally
      Processor.Free;
    end;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TAlertsTests);

end.
