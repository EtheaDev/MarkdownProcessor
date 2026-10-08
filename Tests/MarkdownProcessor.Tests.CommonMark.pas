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
unit MarkdownProcessor.Tests.CommonMark;

interface

uses
  DUnitX.TestFramework,
  MarkdownProcessor.Tests.Corpus;

type
  /// <summary>CommonMark 0.31.2: one test case per section of the specification.</summary>
  [TestFixture]
  TCommonMarkSpecTests = class
  private
    FCorpus: TCorpus;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;

    [Test]
    procedure CommonMark_Corpus_ContainsAllExamples;

    [Test]
    [TestCase('Tabs', 'Tabs')]
    [TestCase('Backslash escapes', 'Backslash escapes')]
    [TestCase('Entity and numeric character references', 'Entity and numeric character references')]
    [TestCase('Precedence', 'Precedence')]
    [TestCase('Thematic breaks', 'Thematic breaks')]
    [TestCase('ATX headings', 'ATX headings')]
    [TestCase('Setext headings', 'Setext headings')]
    [TestCase('Indented code blocks', 'Indented code blocks')]
    [TestCase('Fenced code blocks', 'Fenced code blocks')]
    [TestCase('HTML blocks', 'HTML blocks')]
    [TestCase('Link reference definitions', 'Link reference definitions')]
    [TestCase('Paragraphs', 'Paragraphs')]
    [TestCase('Blank lines', 'Blank lines')]
    [TestCase('Block quotes', 'Block quotes')]
    [TestCase('List items', 'List items')]
    [TestCase('Lists', 'Lists')]
    [TestCase('Inlines', 'Inlines')]
    [TestCase('Code spans', 'Code spans')]
    [TestCase('Emphasis and strong emphasis', 'Emphasis and strong emphasis')]
    [TestCase('Links', 'Links')]
    [TestCase('Images', 'Images')]
    [TestCase('Autolinks', 'Autolinks')]
    [TestCase('Raw HTML', 'Raw HTML')]
    [TestCase('Hard line breaks', 'Hard line breaks')]
    [TestCase('Soft line breaks', 'Soft line breaks')]
    [TestCase('Textual content', 'Textual content')]
    procedure CommonMark_Section_MatchesSpec(const Section: string);
  end;

implementation

uses
  System.SysUtils,
  MarkdownUtils,
  MarkdownProcessor;

const
  CommonMarkCorpusFileName = 'commonmark-0.31.2.json';
  CommonMarkExampleCount = 652;

function CreateCommonMarkProcessor: TMarkdownProcessor;
begin
  // The corpus describes what the specification prescribes, including raw HTML,
  // so it runs with AllowUnsafe. Safe mode has its own suite.
  Result := TMarkdownProcessor.CreateDialect(mdCommonMark);
  Result.AllowUnsafe := True;
end;

procedure TCommonMarkSpecTests.SetupFixture;
begin
  FCorpus := TCorpus.Create('CommonMark 0.31.2', CommonMarkCorpusFileName, 'mdCommonMark',
    CreateCommonMarkProcessor);
end;

procedure TCommonMarkSpecTests.TearDownFixture;
begin
  FreeAndNil(FCorpus);
end;

procedure TCommonMarkSpecTests.CommonMark_Corpus_ContainsAllExamples;
begin
  Assert.AreEqual(CommonMarkExampleCount, FCorpus.Count,
    Format('%s must contain %d examples', [CommonMarkCorpusFileName, CommonMarkExampleCount]));
  Assert.AreEqual(26, Integer(Length(FCorpus.Sections)), 'CommonMark 0.31.2 has 26 sections with examples');
end;

procedure TCommonMarkSpecTests.CommonMark_Section_MatchesSpec(const Section: string);
begin
  const Failures = FCorpus.CheckSection(Section);
  if Failures <> '' then
    Assert.Fail(Failures);
end;

initialization
  TDUnitX.RegisterTestFixture(TCommonMarkSpecTests);

end.
