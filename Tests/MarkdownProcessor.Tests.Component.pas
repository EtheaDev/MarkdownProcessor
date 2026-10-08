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
unit MarkdownProcessor.Tests.Component;

{ TMarkdownToHTML (MarkdownProcessorComponents): defaults, automatic
  conversion, options, files, streaming as in a DFM, emitters. }

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TMarkdownToHTMLTests = class
  public
    [Test]
    procedure Defaults_AreTheLibraryDefaults;
    [Test]
    procedure MarkdownContent_IsConverted;
    [Test]
    procedure Options_ConvertAgain;
    [Test]
    procedure ProcessorDialect_ResetsExtensions;
    [Test]
    procedure HtmlContent_AssignedDirectly_IsKept;
    [Test]
    procedure Files_LoadUtf8AndAnsi_ExportUtf8;
    [Test]
    procedure Streaming_StoresOnlyNonDefaults;
    [Test]
    procedure Emitters_AreNotFreed;
    [Test]
    procedure TransformContent_WithDialect;
    [Test]
    procedure BeginUpdate_ConvertsOnceAtEndUpdate;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  MarkdownUtils,
  MarkdownProcessor,
  MarkdownProcessorComponents,
  MarkdownProcessor.Tests.Corpus;

type
  TCountingBlockEmitter = class(TBlockEmitter)
  public
    Calls: Integer;
    procedure emitBlock(out_: TStringBuilder; lines: TStringList; meta: String); override;
  end;

type
  TChangeCounter = class
  public
    Count: Integer;
    procedure Changed(Sender: TObject);
  end;

procedure TChangeCounter.Changed(Sender: TObject);
begin
  Inc(Count);
end;

procedure TCountingBlockEmitter.emitBlock(out_: TStringBuilder; lines: TStringList; meta: String);
begin
  Inc(Calls);
  out_.Append('<pre class="custom">').Append(meta).Append('</pre>');
end;

function Fragment(const Component: TMarkdownToHTML): string;
begin
  // HtmlContent without the stylesheet, LF line endings
  Result := NormalizeLineEndings(Component.HtmlContent.Text);
  Result := Copy(Result, Length(NormalizeLineEndings(Component.CssStyle.Text)) + 1, MaxInt);
end;

procedure TMarkdownToHTMLTests.Defaults_AreTheLibraryDefaults;
var
  C: TMarkdownToHTML;
begin
  C := TMarkdownToHTML.Create(nil);
  try
    Assert.AreEqual(Ord(DefaultMarkdownDialect), Ord(C.ProcessorDialect));
    Assert.IsTrue(C.Extensions = GitHubExtensions + LegacyExtensions, 'Extensions of mdGitHub + legacy');
    Assert.IsTrue(C.Extensions = TMarkdownToHTML.DefaultExtensions(mdGitHub));
    Assert.IsFalse(C.AllowUnsafe);
    Assert.AreEqual(Ord(mmrMarkup), Ord(C.MathRendering));
    Assert.AreEqual(NormalizeLineEndings(MarkdownDefaultCSS), NormalizeLineEndings(C.CssStyle.Text));
    Assert.AreEqual('', C.HtmlContent.Text);
  finally
    C.Free;
  end;
end;

procedure TMarkdownToHTMLTests.MarkdownContent_IsConverted;
var
  C: TMarkdownToHTML;
  Counter: TChangeCounter;
begin
  C := TMarkdownToHTML.Create(nil);
  Counter := TChangeCounter.Create;
  try
    C.CssStyle.Clear;
    C.OnChange := Counter.Changed;
    C.MarkdownContent.Text := '# Title';
    Assert.AreEqual('<h1 id="title">Title</h1>'#10, NormalizeLineEndings(C.HtmlContent.Text));
    Assert.AreEqual(1, Counter.Count, 'one OnChange per conversion');
    C.MarkdownContent.Clear;
    Assert.AreEqual('', C.HtmlContent.Text, 'no Markdown, no HTML');
    Assert.AreEqual(2, Counter.Count);
  finally
    Counter.Free;
    C.Free;
  end;
end;

procedure TMarkdownToHTMLTests.Options_ConvertAgain;
var
  C: TMarkdownToHTML;
begin
  C := TMarkdownToHTML.Create(nil);
  try
    C.MarkdownContent.Text := '<b>x</b> $y$';
    Assert.AreEqual('<p><!-- raw HTML omitted -->x<!-- raw HTML omitted --> <span class="math">\(y\)</span></p>'#10, Fragment(C));
    C.AllowUnsafe := True;
    Assert.AreEqual('<p><b>x</b> <span class="math">\(y\)</span></p>'#10, Fragment(C));
    C.MathRendering := mmrCodeCogsImage;
    Assert.AreEqual('<p><b>x</b> <img class="math" src="https://latex.codecogs.com/png.image?y" alt="y" /></p>'#10, Fragment(C));
    C.Extensions := C.Extensions - [mexMath];
    Assert.AreEqual('<p><b>x</b> $y$</p>'#10, Fragment(C));
    C.CssStyle.Text := '<style>p{}</style>';
    Assert.IsTrue(C.HtmlContent.Text.StartsWith('<style>p{}</style>'), 'new stylesheet');
  finally
    C.Free;
  end;
end;

procedure TMarkdownToHTMLTests.ProcessorDialect_ResetsExtensions;
var
  C: TMarkdownToHTML;
begin
  C := TMarkdownToHTML.Create(nil);
  try
    C.MarkdownContent.Text := '~~x~~';
    C.ProcessorDialect := mdCommonMark;
    Assert.IsTrue(C.Extensions = LegacyExtensions, 'mdCommonMark: only the legacy extensions');
    Assert.AreEqual('<p>~~x~~</p>'#10, Fragment(C));
    C.ProcessorDialect := mdGFM;
    Assert.IsTrue(C.Extensions = GFMExtensions + LegacyExtensions);
    Assert.AreEqual('<p><del>x</del></p>'#10, Fragment(C));
    // the legacy dialects ignore the extensions
    C.ProcessorDialect := mdDaringFireball;
    Assert.IsTrue(C.Extensions = []);
  finally
    C.Free;
  end;
end;

procedure TMarkdownToHTMLTests.HtmlContent_AssignedDirectly_IsKept;
var
  C: TMarkdownToHTML;
begin
  C := TMarkdownToHTML.Create(nil);
  try
    C.LoadFromString('<p>ready</p>', True);
    Assert.AreEqual('', C.MarkdownContent.Text);
    Assert.AreEqual('<p>ready</p>', C.HtmlContent.Text.Trim);
    C.AllowUnsafe := True; // no Markdown: the HTML is not rebuilt
    Assert.AreEqual('<p>ready</p>', C.HtmlContent.Text.Trim);
  finally
    C.Free;
  end;
end;

procedure TMarkdownToHTMLTests.Files_LoadUtf8AndAnsi_ExportUtf8;
var
  C: TMarkdownToHTML;
  Folder, Utf8File, AnsiFile, HtmlFile: string;
  Ansi: TEncoding;
begin
  Folder := TPath.Combine(TPath.GetTempPath, 'MarkdownToHTMLTests');
  TDirectory.CreateDirectory(Folder);
  Utf8File := TPath.Combine(Folder, 'utf8.md');
  AnsiFile := TPath.Combine(Folder, 'ansi.md');
  HtmlFile := TPath.Combine(Folder, 'out.html');
  C := TMarkdownToHTML.Create(nil);
  try
    C.CssStyle.Clear;
    // UTF-8 without BOM
    TFile.WriteAllBytes(Utf8File, TEncoding.UTF8.GetBytes('Citt'#$00E0' '#$20AC));
    C.FileName := Utf8File;
    Assert.AreEqual('<p>Citt'#$00E0' '#$20AC'</p>'#10, NormalizeLineEndings(C.HtmlContent.Text));
    // ANSI (Windows-1252)
    Ansi := TEncoding.GetEncoding(1252);
    try
      TFile.WriteAllBytes(AnsiFile, Ansi.GetBytes('Citt'#$00E0));
    finally
      Ansi.Free;
    end;
    C.LoadFromFile(AnsiFile);
    Assert.AreEqual('<p>Citt'#$00E0'</p>'#10, NormalizeLineEndings(C.HtmlContent.Text));
    // export
    C.ExportToFileHTML(HtmlFile);
    Assert.AreEqual('<p>Citt'#$00E0'</p>', TryLoadTextFile(HtmlFile).Trim);
  finally
    C.Free;
    TDirectory.Delete(Folder, True);
  end;
end;

procedure TMarkdownToHTMLTests.Streaming_StoresOnlyNonDefaults;
var
  Source, Target: TMarkdownToHTML;
  Stream: TMemoryStream;
  Text: TStringStream;
begin
  Source := TMarkdownToHTML.Create(nil);
  Target := TMarkdownToHTML.Create(nil);
  Stream := TMemoryStream.Create;
  Text := TStringStream.Create('', TEncoding.UTF8);
  try
    Source.ProcessorDialect := mdGFM;
    Source.Extensions := Source.Extensions - [mexMark];
    Source.MarkdownContent.Text := '==a== ~~b~~';
    Stream.WriteComponent(Source);
    // what is stored, as text (like a DFM)
    Stream.Position := 0;
    ObjectBinaryToText(Stream, Text);
    Assert.Contains(Text.DataString, 'ProcessorDialect = mdGFM');
    Assert.Contains(Text.DataString, 'Extensions = [', 'extensions different from the defaults');
    Assert.DoesNotContain(Text.DataString, 'mexMark');
    Assert.DoesNotContain(Text.DataString, 'CssStyle', 'default stylesheet not stored');
    Assert.DoesNotContain(Text.DataString, 'HtmlContent', 'HTML rebuilt from the Markdown');
    // read back: the HTML is rebuilt in Loaded
    Stream.Position := 0;
    Stream.ReadComponent(Target);
    Assert.IsTrue(Target.Extensions = GFMExtensions + LegacyExtensions - [mexMark]);
    Assert.AreEqual(Source.HtmlContent.Text, Target.HtmlContent.Text);
    Assert.Contains(Target.HtmlContent.Text, '<p>==a== <del>b</del></p>');
  finally
    Text.Free;
    Stream.Free;
    Target.Free;
    Source.Free;
  end;
end;

procedure TMarkdownToHTMLTests.Emitters_AreNotFreed;
var
  C: TMarkdownToHTML;
  Emitter: TCountingBlockEmitter;
begin
  Emitter := TCountingBlockEmitter.Create;
  try
    C := TMarkdownToHTML.Create(nil);
    try
      C.CodeBlockEmitter := Emitter;
      C.MarkdownContent.Text := '```mermaid'#10'graph TD'#10'```';
      C.AllowUnsafe := True; // a second conversion with the same emitter
      Assert.AreEqual(2, Emitter.Calls);
      Assert.Contains(C.HtmlContent.Text, '<pre class="custom">mermaid</pre>');
    finally
      C.Free;
    end;
    Assert.AreEqual(2, Emitter.Calls, 'still usable after the component is freed');
  finally
    Emitter.Free;
  end;
end;

procedure TMarkdownToHTMLTests.TransformContent_WithDialect;
var
  C: TMarkdownToHTML;
begin
  C := TMarkdownToHTML.Create(nil);
  try
    Assert.AreEqual('<p>~~x~~</p>'#10, NormalizeLineEndings(C.TransformContent('~~x~~', mdCommonMark)));
    Assert.AreEqual('CSS<p><del>x</del></p>'#10, NormalizeLineEndings(C.TransformContent('~~x~~', mdGFM, 'CSS')));
  finally
    C.Free;
  end;
end;

procedure TMarkdownToHTMLTests.BeginUpdate_ConvertsOnceAtEndUpdate;
var
  C: TMarkdownToHTML;
  Counter: TChangeCounter;
begin
  C := TMarkdownToHTML.Create(nil);
  Counter := TChangeCounter.Create;
  try
    C.CssStyle.Clear;
    C.OnChange := Counter.Changed;
    C.BeginUpdate;
    C.MarkdownContent.Text := '==x==';
    C.ProcessorDialect := mdGFM;
    C.Extensions := C.Extensions - [mexMark];
    C.AllowUnsafe := True;
    Assert.AreEqual(0, Counter.Count, 'no conversion while updating');
    Assert.AreEqual('', C.HtmlContent.Text);
    C.EndUpdate;
    Assert.AreEqual(1, Counter.Count, 'one conversion at EndUpdate');
    Assert.AreEqual('<p>==x==</p>'#10, Fragment(C));
    // an empty Markdown clears the HTML
    C.LoadFromString('');
    Assert.AreEqual('', C.HtmlContent.Text);
    Assert.AreEqual(2, Counter.Count);
  finally
    Counter.Free;
    C.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TMarkdownToHTMLTests);

end.
