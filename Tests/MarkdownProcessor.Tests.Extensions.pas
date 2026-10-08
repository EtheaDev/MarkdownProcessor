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
unit MarkdownProcessor.Tests.Extensions;

{ Legacy (Ethea) extensions as individual flags, phase 7 of
  docs/COMMONMARK_PLAN.md. Corpus: Tests\specs\extensions.json; each section
  runs with its own dialect and flags (see ProcessorForSection). The section
  "Subscript and strikethrough" pins the documented deviation from GFM:
  with both flags, ~x~ is subscript and ~~x~~ strikethrough. }

interface

uses
  DUnitX.TestFramework,
  MarkdownProcessor.Tests.Corpus;

type
  [TestFixture]
  TExtensionsTests = class
  private
    FCorpus: TCorpus;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;

    [Test]
    [TestCase('Subscript', 'Subscript')]
    [TestCase('Superscript', 'Superscript')]
    [TestCase('Insert', 'Insert')]
    [TestCase('Mark', 'Mark')]
    [TestCase('Subscript and strikethrough', 'Subscript and strikethrough')]
    [TestCase('Smart typography', 'Smart typography')]
    [TestCase('Heading attributes', 'Heading attributes')]
    [TestCase('Auto heading ids', 'Auto heading ids')]
    [TestCase('Heading attributes and auto ids', 'Heading attributes and auto ids')]
    [TestCase('Wiki links', 'Wiki links')]
    [TestCase('Disabled', 'Disabled')]
    [TestCase('Mermaid', 'Mermaid')]
    [TestCase('Mermaid off', 'Mermaid off')]
    [TestCase('Math images', 'Math images')]
    [TestCase('GitHub dialect', 'GitHub dialect')]
    procedure Extensions_Section_Matches(const Section: string);

    [Test]
    procedure Extensions_SupportTestFile_RendersAllFeatures;

    [Test]
    procedure Dialect_Default_IsGitHub;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  MarkdownUtils,
  MarkdownProcessor;

type
  // writes the [[...]] wiki links (mexWikiLinks)
  TWikiSpanEmitter = class(TSpanEmitter)
  public
    procedure emitSpan(out_: TStringBuilder; content: String); override;
  end;

procedure TWikiSpanEmitter.emitSpan(out_: TStringBuilder; content: String);
begin
  out_.Append('<a class="wiki">' + content + '</a>');
end;

function ProcessorForSection(const Section: string): TMarkdownProcessor;
var
  Dialect: TMarkdownProcessorDialect;
  Extensions: TMarkdownExtensions;
begin
  Dialect := mdCommonMark;
  Extensions := [];
  if (Section = 'Mermaid') or (Section = 'Math images') or (Section = 'GitHub dialect') then
  begin
    Dialect := mdGitHub;
    Extensions := GitHubExtensions;
  end
  else if Section = 'Mermaid off' then
  begin
    Dialect := mdGFM;
    Extensions := GFMExtensions;
  end
  else
  if Section = 'Subscript' then
    Extensions := [mexSubscript]
  else if Section = 'Superscript' then
    Extensions := [mexSuperscript]
  else if Section = 'Insert' then
    Extensions := [mexInsert]
  else if Section = 'Mark' then
    Extensions := [mexMark]
  else if Section = 'Subscript and strikethrough' then
  begin
    Dialect := mdGFM;
    Extensions := GFMExtensions + [mexSubscript];
  end
  else if Section = 'Smart typography' then
    Extensions := [mexSmartTypography]
  else if Section = 'Heading attributes' then
    Extensions := [mexHeadingAttributes]
  else if Section = 'Auto heading ids' then
    Extensions := [mexAutoHeadingIds]
  else if Section = 'Heading attributes and auto ids' then
    Extensions := [mexHeadingAttributes, mexAutoHeadingIds]
  else if Section = 'Wiki links' then
    Extensions := [mexWikiLinks];
  Result := TMarkdownProcessor.CreateDialect(Dialect);
  Result.AllowUnsafe := True;
  Result.Config.Extensions := Extensions;
  if Section = 'Math images' then
    Result.Config.MathRendering := mmrCodeCogsImage;
end;

procedure TExtensionsTests.SetupFixture;
begin
  FCorpus := TCorpus.Create('Extensions', 'extensions.json', 'per section', ProcessorForSection);
end;

procedure TExtensionsTests.TearDownFixture;
begin
  FreeAndNil(FCorpus);
end;

procedure TExtensionsTests.Extensions_Section_Matches(const Section: string);
begin
  const Failures = FCorpus.CheckSection(Section);
  if Failures <> '' then
    Assert.Fail(Failures);
end;

procedure TExtensionsTests.Extensions_SupportTestFile_RendersAllFeatures;
const
  Expected: array[0..23] of string = (
    '<h1 id="markdown-support-test">Markdown support test</h1>',
    '<h2 id="setext-heading-2">Setext heading 2</h2>',
    'two spaces at the end of a line<br />',
    '<em><strong>Bold italic</strong></em>, <del>Strikethrough</del>',
    'un<em>frigging</em>believable, while snake_case_words',
    '<a href="https://spec.commonmark.org/0.31.2/">CommonMark</a>',
    '<a href="http://www.github.com">www.github.com</a>',
    '<a href="mailto:info@ethea.it">info@ethea.it</a>',
    '<li><input checked="" disabled="" type="checkbox"> Write the new engine</li>',
    '<pre><code class="language-Delphi">',
    '<th align="center">Second Header</th>',
    '<td align="left">pipe | escaped</td>',
    '<td align="right"><a href="http://www.ethea.it">www.ethea.it</a></td>',
    '<div class="markdown-alert markdown-alert-caution">',
    '<span class="math">\(E = mc^2\)</span>',
    'prices like $10 and $20 stay text',
    '<div class="math">\[',
    '<pre class="mermaid">graph LR',
    'H<sub>2</sub>O and superscript: x<sup>2</sup>',
    '<ins>inserted</ins> and highlighted text: <mark>marked</mark>',
    #$2013' en dash, '#$2014' em dash, ellipsis'#$2026', '#$00A9' '#$00AE' '#$2122', '#$201C'double quotes'#$201D', '#$00AB' guillemets '#$00BB,
    '<h3 id="custom-id">Heading with a custom id</h3>',
    'Wiki link: <a class="wiki">Main Page</a>',
    '<p>Inline HTML: <kbd>Ctrl</kbd>+<kbd>C</kbd>');
var
  Processor: TMarkdownProcessor;
  Html: string;
  Fragment: string;
begin
  // the sample file of the repository, with the default dialect and all the
  // legacy extensions (the defaults of the TMarkdownToHTML component)
  Processor := TMarkdownProcessor.CreateDialect;
  try
    Processor.AllowUnsafe := True;
    Processor.Config.Extensions := Processor.Config.Extensions + [mexSubscript,
      mexSuperscript, mexInsert, mexMark, mexSmartTypography, mexHeadingAttributes,
      mexAutoHeadingIds, mexWikiLinks];
    Processor.Config.specialLinkEmitter := TWikiSpanEmitter.Create; // owned by Config
    Html := Processor.Process(TFile.ReadAllText(
      TPath.Combine(TPath.Combine(TTestPaths.RepositoryFolder, 'TestFile'), 'MarkDown Support Test.md'),
      TEncoding.UTF8));
  finally
    Processor.Free;
  end;
  for Fragment in Expected do
    Assert.IsTrue(Pos(Fragment, Html) > 0, 'Missing in the output: ' + Fragment + sLineBreak + Html);
end;

procedure TExtensionsTests.Dialect_Default_IsGitHub;
var
  Processor: TMarkdownProcessor;
begin
  Assert.AreEqual(Ord(mdGitHub), Ord(DefaultMarkdownDialect));
  Processor := TMarkdownProcessor.CreateDialect;
  try
    Assert.AreEqual(Ord(mdGitHub), Ord(Processor.Config.Dialect));
    Assert.IsTrue(Processor.Config.Extensions = GitHubExtensions, 'mdGitHub extensions');
    Assert.AreEqual(Ord(mmrMarkup), Ord(Processor.Config.MathRendering));
    Assert.IsFalse(Processor.AllowUnsafe, 'safe by default');
  finally
    Processor.Free;
  end;
  // the ordinals of the existing dialects do not change
  Assert.AreEqual(0, Ord(mdDaringFireball));
  Assert.AreEqual(1, Ord(mdCommonMark));
  Assert.AreEqual(2, Ord(mdTxtMark));
  Assert.AreEqual(3, Ord(mdGFM));
end;

initialization
  TDUnitX.RegisterTestFixture(TExtensionsTests);

end.
