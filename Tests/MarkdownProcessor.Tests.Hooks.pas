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
unit MarkdownProcessor.Tests.Hooks;

{ The hooks kept from the old engine (backward compatible signatures):
  TConfiguration.codeBlockEmitter receives every code block (mermaid and chart
  included) with the whole info string as meta; specialLinkEmitter receives
  the rendered content of [[...]] when mexWikiLinks is on. }

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  THooksTests = class
  public
    [Test]
    procedure CodeBlockEmitter_FencedBlock_ReceivesLinesAndInfo;
    [Test]
    procedure CodeBlockEmitter_IndentedBlock_ReceivesLines;
    [Test]
    procedure CodeBlockEmitter_Mermaid_ReceivesTheBlock;
    [Test]
    procedure CodeBlockEmitter_Unassigned_StandardOutput;
    [Test]
    procedure SpecialLinkEmitter_WikiLink_ReceivesRenderedContent;
    [Test]
    procedure SpecialLinkEmitter_ExtensionOff_NotCalled;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  MarkdownUtils,
  MarkdownProcessor,
  MarkdownProcessor.Tests.Corpus;

type
  TRecordingBlockEmitter = class(TBlockEmitter)
  public
    Calls: Integer;
    LastLines: string;
    LastMeta: string;
    procedure emitBlock(out_: TStringBuilder; lines: TStringList; meta: String); override;
  end;

  TRecordingSpanEmitter = class(TSpanEmitter)
  public
    Calls: Integer;
    LastContent: string;
    procedure emitSpan(out_: TStringBuilder; content: String); override;
  end;

procedure TRecordingBlockEmitter.emitBlock(out_: TStringBuilder; lines: TStringList; meta: String);
begin
  Inc(Calls);
  LastLines := string.Join('|', lines.ToStringArray);
  LastMeta := meta;
  out_.Append('<custom meta="' + meta + '">' + IntToStr(lines.Count) + '</custom>');
end;

procedure TRecordingSpanEmitter.emitSpan(out_: TStringBuilder; content: String);
begin
  Inc(Calls);
  LastContent := content;
  out_.Append('<a class="wiki">' + content + '</a>');
end;

function Render(const Source: string; const Dialect: TMarkdownProcessorDialect;
  const Extensions: TMarkdownExtensions; BlockEmitter: TBlockEmitter; SpanEmitter: TSpanEmitter): string;
var
  Processor: TMarkdownProcessor;
begin
  Processor := TMarkdownProcessor.CreateDialect(Dialect);
  try
    Processor.Config.Extensions := Processor.Config.Extensions + Extensions;
    // the configuration owns the emitters: they are detached before it is freed
    Processor.Config.codeBlockEmitter := BlockEmitter;
    Processor.Config.specialLinkEmitter := SpanEmitter;
    try
      Result := NormalizeLineEndings(Processor.Process(Source));
    finally
      Processor.Config.codeBlockEmitter := nil;
      Processor.Config.specialLinkEmitter := nil;
    end;
  finally
    Processor.Free;
  end;
end;

procedure THooksTests.CodeBlockEmitter_FencedBlock_ReceivesLinesAndInfo;
var
  Emitter: TRecordingBlockEmitter;
  Html: string;
begin
  Emitter := TRecordingBlockEmitter.Create;
  try
    Html := Render('before'#10#10'```delphi title="x"'#10'a'#10#10'b'#10'```'#10'after', mdCommonMark, [], Emitter, nil);
    Assert.AreEqual(1, Emitter.Calls);
    Assert.AreEqual('delphi title="x"', Emitter.LastMeta);
    Assert.AreEqual('a||b', Emitter.LastLines);
    Assert.AreEqual('<p>before</p>'#10'<custom meta="delphi title="x"">3</custom>'#10'<p>after</p>'#10, Html);
  finally
    Emitter.Free;
  end;
end;

procedure THooksTests.CodeBlockEmitter_IndentedBlock_ReceivesLines;
var
  Emitter: TRecordingBlockEmitter;
begin
  Emitter := TRecordingBlockEmitter.Create;
  try
    Render('    x := 1;'#10'    y := 2;', mdGFM, [], Emitter, nil);
    Assert.AreEqual(1, Emitter.Calls);
    Assert.AreEqual('', Emitter.LastMeta);
    Assert.AreEqual('x := 1;|y := 2;', Emitter.LastLines);
  finally
    Emitter.Free;
  end;
end;

procedure THooksTests.CodeBlockEmitter_Mermaid_ReceivesTheBlock;
var
  Emitter: TRecordingBlockEmitter;
begin
  Emitter := TRecordingBlockEmitter.Create;
  try
    Render('```mermaid'#10'graph TD'#10'  A --> B'#10'```', mdGFM, [mexMath], Emitter, nil);
    Assert.AreEqual(1, Emitter.Calls);
    Assert.AreEqual('mermaid', Emitter.LastMeta);
    Assert.AreEqual('graph TD|  A --> B', Emitter.LastLines);
  finally
    Emitter.Free;
  end;
end;

procedure THooksTests.CodeBlockEmitter_Unassigned_StandardOutput;
begin
  Assert.AreEqual('<pre><code class="language-mermaid">graph TD'#10'</code></pre>'#10,
    Render('```mermaid'#10'graph TD'#10'```', mdGFM, [], nil, nil));
end;

procedure THooksTests.SpecialLinkEmitter_WikiLink_ReceivesRenderedContent;
var
  Emitter: TRecordingSpanEmitter;
  Html: string;
begin
  Emitter := TRecordingSpanEmitter.Create;
  try
    Html := Render('See [[Main *Page*]].', mdGFM, [mexWikiLinks], nil, Emitter);
    Assert.AreEqual(1, Emitter.Calls);
    Assert.AreEqual('Main <em>Page</em>', Emitter.LastContent);
    Assert.AreEqual('<p>See <a class="wiki">Main <em>Page</em></a>.</p>'#10, Html);
  finally
    Emitter.Free;
  end;
end;

procedure THooksTests.SpecialLinkEmitter_ExtensionOff_NotCalled;
var
  Emitter: TRecordingSpanEmitter;
  Html: string;
begin
  Emitter := TRecordingSpanEmitter.Create;
  try
    Html := Render('See [[Main]].', mdGFM, [], nil, Emitter);
    Assert.AreEqual(0, Emitter.Calls);
    Assert.AreEqual('<p>See [[Main]].</p>'#10, Html);
  finally
    Emitter.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(THooksTests);

end.
