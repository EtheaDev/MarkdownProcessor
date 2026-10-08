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
unit MarkdownProcessor.Tests.GFM;

interface

uses
  DUnitX.TestFramework,
  MarkdownProcessor.Tests.Corpus;

type
  /// <summary>GFM 0.29 extensions: one test case per extension section.</summary>
  [TestFixture]
  TGfmSpecTests = class
  private
    FCorpus: TCorpus;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;

    [Test]
    procedure Gfm_Corpus_ContainsAllExamples;

    [Test]
    [TestCase('Tables (extension)', 'Tables (extension)')]
    [TestCase('Task list items (extension)', 'Task list items (extension)')]
    [TestCase('Strikethrough (extension)', 'Strikethrough (extension)')]
    [TestCase('Autolinks (extension)', 'Autolinks (extension)')]
    [TestCase('Disallowed Raw HTML (extension)', 'Disallowed Raw HTML (extension)')]
    procedure Gfm_Section_MatchesSpec(const Section: string);
  end;

implementation

uses
  System.SysUtils,
  MarkdownUtils,
  MarkdownProcessor;

const
  GfmCorpusFileName = 'gfm-0.29.json';
  GfmExampleCount = 24;
  GfmEngine = 'mdGFM';

function CreateGfmProcessor: TMarkdownProcessor;
begin
  Result := TMarkdownProcessor.CreateDialect(mdGFM);
  Result.AllowUnsafe := True;
end;

procedure TGfmSpecTests.SetupFixture;
begin
  FCorpus := TCorpus.Create('GFM 0.29', GfmCorpusFileName, GfmEngine, CreateGfmProcessor);
end;

procedure TGfmSpecTests.TearDownFixture;
begin
  FreeAndNil(FCorpus);
end;

procedure TGfmSpecTests.Gfm_Corpus_ContainsAllExamples;
begin
  Assert.AreEqual(GfmExampleCount, FCorpus.Count,
    Format('%s must contain %d examples', [GfmCorpusFileName, GfmExampleCount]));
end;

procedure TGfmSpecTests.Gfm_Section_MatchesSpec(const Section: string);
begin
  const Failures = FCorpus.CheckSection(Section);
  if Failures <> '' then
    Assert.Fail(Failures);
end;

initialization
  TDUnitX.RegisterTestFixture(TGfmSpecTests);

end.
