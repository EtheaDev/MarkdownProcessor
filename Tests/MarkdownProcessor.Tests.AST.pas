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
unit MarkdownProcessor.Tests.AST;

{ The read-only syntax tree (IMarkdownNode): structure, node properties,
  source line ranges, lifetime, and Render(Parse(s)) = Process(s). }

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TASTTests = class
  public
    [Test]
    procedure Parse_Document_HasBlockStructureAndLines;
    [Test]
    procedure Parse_Inlines_HaveKindsAndProperties;
    [Test]
    procedure Parse_GfmNodes_TableTaskAlertMath;
    [Test]
    procedure Parse_ChildReference_KeepsTreeAlive;
    [Test]
    procedure Render_OfParse_EqualsProcess;
    [Test]
    procedure Parse_LegacyDialect_RaisesNotSupported;
  end;

implementation

uses
  System.SysUtils,
  MarkdownUtils,
  MarkdownAST,
  MarkdownProcessor,
  MarkdownProcessor.Tests.Corpus;

function ParseWith(const Source: string; const Dialect: TMarkdownProcessorDialect;
  const Extensions: TMarkdownExtensions = []): IMarkdownNode;
var
  Processor: TMarkdownProcessor;
begin
  Processor := TMarkdownProcessor.CreateDialect(Dialect);
  try
    Processor.Config.Extensions := Processor.Config.Extensions + Extensions;
    Result := Processor.Parse(Source);
  finally
    Processor.Free;
  end;
end;

procedure TASTTests.Parse_Document_HasBlockStructureAndLines;
var
  Doc, Heading, Para, List: IMarkdownNode;
begin
  Doc := ParseWith('# Title'#10#10'para'#10'line 2'#10#10'- a'#10'- b'#10, mdCommonMark);
  Assert.AreEqual(Ord(nkDocument), Ord(Doc.Kind));
  Assert.AreEqual(3, Doc.ChildCount);

  Heading := Doc.Children[0];
  Assert.AreEqual(Ord(nkHeading), Ord(Heading.Kind));
  Assert.AreEqual(1, Heading.Level);
  Assert.AreEqual(1, Heading.StartLine);
  Assert.AreEqual(1, Heading.EndLine);

  Para := Doc.Children[1];
  Assert.AreEqual(Ord(nkParagraph), Ord(Para.Kind));
  Assert.AreEqual(3, Para.StartLine);
  Assert.AreEqual(4, Para.EndLine);

  List := Doc.Children[2];
  Assert.AreEqual(Ord(nkList), Ord(List.Kind));
  Assert.AreEqual(Ord(mltBullet), Ord(List.ListType));
  Assert.IsTrue(List.ListTight);
  Assert.AreEqual(2, List.ChildCount);
  Assert.AreEqual(6, List.Children[0].StartLine);
  Assert.AreEqual(7, List.Children[1].StartLine);
  Assert.IsTrue(List.Parent = Doc, 'Parent of a top-level block is the document');
  Assert.IsTrue(List.Previous = Para);
  Assert.IsNull(List.Next);
end;

procedure TASTTests.Parse_Inlines_HaveKindsAndProperties;
var
  Para, Link, Code: IMarkdownNode;
begin
  Para := ParseWith('Go to [the *site*](https://example.com "Home") or run `cmd`.', mdCommonMark).FirstChild;
  Assert.AreEqual(Ord(nkParagraph), Ord(Para.Kind));
  Assert.AreEqual('Go to ', Para.FirstChild.Literal);
  Link := Para.Children[1];
  Assert.AreEqual(Ord(nkLink), Ord(Link.Kind));
  Assert.AreEqual('https://example.com', Link.Destination);
  Assert.AreEqual('Home', Link.Title);
  Assert.IsFalse(Link.IsAutolink);
  Assert.AreEqual(Ord(nkEmphasis), Ord(Link.LastChild.Kind));
  Code := Para.Children[3];
  Assert.AreEqual(Ord(nkCode), Ord(Code.Kind));
  Assert.AreEqual('cmd', Code.Literal);
end;

procedure TASTTests.Parse_GfmNodes_TableTaskAlertMath;
var
  Doc, Table, Item, Alert, Formula, Fence: IMarkdownNode;
begin
  Doc := ParseWith('| a | b |'#10'|:-|-:|'#10'| 1 | 2 |'#10#10 +
    '- [x] done'#10#10 +
    '> [!WARNING]'#10'> careful'#10#10 +
    '$x^2$'#10#10 +
    '```cpp'#10'int x;'#10'```', mdGFM, [mexAlerts, mexMath]);
  Table := Doc.Children[0];
  Assert.AreEqual(Ord(nkTable), Ord(Table.Kind));
  Assert.AreEqual(Ord(nkTableHead), Ord(Table.FirstChild.Kind));
  Assert.AreEqual(Ord(mtaLeft), Ord(Table.FirstChild.FirstChild.Children[0].Align));
  Assert.AreEqual(Ord(mtaRight), Ord(Table.FirstChild.FirstChild.Children[1].Align));
  Assert.AreEqual(3, Table.LastChild.FirstChild.StartLine, 'Body row line');

  Item := Doc.Children[1].FirstChild;
  Assert.AreEqual(Ord(nkTaskMarker), Ord(Item.FirstChild.FirstChild.Kind));
  Assert.IsTrue(Item.FirstChild.FirstChild.Checked);

  Alert := Doc.Children[2];
  Assert.AreEqual(Ord(nkAlert), Ord(Alert.Kind));
  Assert.AreEqual('WARNING', Alert.AlertType);

  Formula := Doc.Children[3].FirstChild;
  Assert.AreEqual(Ord(nkMathInline), Ord(Formula.Kind));
  Assert.AreEqual('x^2', Formula.Literal);
  Assert.IsFalse(Formula.IsDisplay);

  Fence := Doc.Children[4];
  Assert.AreEqual(Ord(nkCodeBlock), Ord(Fence.Kind));
  Assert.IsTrue(Fence.IsFenced);
  Assert.AreEqual('cpp', Fence.Info);
  Assert.AreEqual('int x;'#10, Fence.Literal);
end;

procedure TASTTests.Parse_ChildReference_KeepsTreeAlive;
var
  Text: IMarkdownNode;
begin
  // only a grandchild is kept: the document must stay alive with it
  Text := ParseWith('alive', mdCommonMark).FirstChild.FirstChild;
  Assert.AreEqual('alive', Text.Literal);
  Assert.AreEqual(Ord(nkParagraph), Ord(Text.Parent.Kind));
  Assert.AreEqual(Ord(nkDocument), Ord(Text.Parent.Parent.Kind));
end;

procedure TASTTests.Render_OfParse_EqualsProcess;
const
  Source = '# T'#10#10'*a* [b](/c)'#10#10'| x |'#10'|---|'#10'| ~~y~~ |'#10;
var
  Processor: TMarkdownProcessor;
  Doc: IMarkdownNode;
begin
  Processor := TMarkdownProcessor.CreateDialect(mdGFM);
  try
    Doc := Processor.Parse(Source);
    Assert.AreEqual(Processor.Process(Source), Processor.Render(Doc));
  finally
    Processor.Free;
  end;
end;

procedure TASTTests.Parse_LegacyDialect_RaisesNotSupported;
begin
  Assert.WillRaise(
    procedure
    begin
      ParseWith('x', mdDaringFireball);
    end, ENotSupportedException);
end;

initialization
  TDUnitX.RegisterTestFixture(TASTTests);

end.
