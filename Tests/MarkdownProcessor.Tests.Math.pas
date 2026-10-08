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
unit MarkdownProcessor.Tests.Math;

interface

uses
  DUnitX.TestFramework,
  MarkdownProcessor.Tests.Corpus;

type
  /// <summary>Math corpus (math.json from Markdown4D, MIT): $ / $$ inline, display blocks, math fence.</summary>
  [TestFixture]
  TMathSpecTests = class
  private
    FCorpus: TCorpus;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;

    [Test]
    procedure Math_Corpus_ContainsAllExamples;

    [Test]
    [TestCase('Inline math', 'Inline math')]
    [TestCase('Display math', 'Display math')]
    [TestCase('Math fence', 'Math fence')]
    procedure Math_Section_MatchesSpec(const Section: string);
  end;

implementation

uses
  System.SysUtils,
  MarkdownUtils,
  MarkdownProcessor;

const
  MathCorpusFileName = 'math.json';
  MathExampleCount = 35;
  MathEngine = 'mdGFM + mexMath';

function CreateMathProcessor: TMarkdownProcessor;
begin
  Result := TMarkdownProcessor.CreateDialect(mdGFM);
  Result.AllowUnsafe := True;
  Result.Config.Extensions := Result.Config.Extensions + [mexMath];
end;

procedure TMathSpecTests.SetupFixture;
begin
  FCorpus := TCorpus.Create('Math', MathCorpusFileName, MathEngine, CreateMathProcessor);
end;

procedure TMathSpecTests.TearDownFixture;
begin
  FreeAndNil(FCorpus);
end;

procedure TMathSpecTests.Math_Corpus_ContainsAllExamples;
begin
  Assert.AreEqual(MathExampleCount, FCorpus.Count,
    Format('%s must contain %d examples', [MathCorpusFileName, MathExampleCount]));
end;

procedure TMathSpecTests.Math_Section_MatchesSpec(const Section: string);
begin
  const Failures = FCorpus.CheckSection(Section);
  if Failures <> '' then
    Assert.Fail(Failures);
end;

initialization
  TDUnitX.RegisterTestFixture(TMathSpecTests);

end.
