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
unit MarkdownProcessor.Tests.Safety;

{ Safe mode (AllowUnsafe = False, the default) of the new engine, decision D8
  of docs/COMMONMARK_PLAN.md: raw HTML is omitted and javascript:, vbscript:,
  file: and data: destinations are emptied (data:image/png|gif|jpeg|webp are
  allowed). Corpus: Tests\specs\safety.json. }

interface

uses
  DUnitX.TestFramework,
  MarkdownProcessor.Tests.Corpus;

type
  [TestFixture]
  TSafetyTests = class
  private
    FCorpus: TCorpus;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;

    [Test]
    procedure Safety_DefaultIsSafe;

    [Test]
    [TestCase('Raw HTML', 'Raw HTML')]
    [TestCase('Dangerous URLs', 'Dangerous URLs')]
    [TestCase('Allowed URLs', 'Allowed URLs')]
    procedure Safety_Section_Matches(const Section: string);
  end;

implementation

uses
  System.SysUtils,
  MarkdownUtils,
  MarkdownProcessor;

function CreateSafeProcessor: TMarkdownProcessor;
begin
  Result := TMarkdownProcessor.CreateDialect(mdCommonMark);
  Result.AllowUnsafe := False;
end;

procedure TSafetyTests.SetupFixture;
begin
  FCorpus := TCorpus.Create('Safety', 'safety.json', 'mdCommonMark (safe)', CreateSafeProcessor);
end;

procedure TSafetyTests.TearDownFixture;
begin
  FreeAndNil(FCorpus);
end;

procedure TSafetyTests.Safety_DefaultIsSafe;
var
  Processor: TMarkdownProcessor;
begin
  Processor := TMarkdownProcessor.CreateDialect(mdCommonMark);
  try
    Assert.IsFalse(Processor.AllowUnsafe, 'A new processor must be in safe mode');
    Assert.AreEqual('<!-- raw HTML omitted -->'#10, Processor.Process('<script>alert(1)</script>'));
  finally
    Processor.Free;
  end;
end;

procedure TSafetyTests.Safety_Section_Matches(const Section: string);
begin
  const Failures = FCorpus.CheckSection(Section);
  if Failures <> '' then
    Assert.Fail(Failures);
end;

initialization
  TDUnitX.RegisterTestFixture(TSafetyTests);

end.
