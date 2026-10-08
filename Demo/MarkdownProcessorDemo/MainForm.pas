{******************************************************************************}
{                                                                              }
{       MarkDown Processor                                                     }
{       Demo of the TMarkdownToHTML component                                  }
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
unit MainForm;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  MarkdownUtils,
  MarkdownProcessorComponents;

type
  TMainForm = class(TForm)
    SourcePanel: TPanel;
    SourceToolPanel: TPanel;
    SourceLabel: TLabel;
    LoadFileButton: TButton;
    MarkdownSourceMemo: TMemo;
    Splitter: TSplitter;
    DestPanel: TPanel;
    DestToolPanel: TPanel;
    DestLabel: TLabel;
    ProcessButton: TButton;
    OpenInBrowserButton: TButton;
    OptionsPanel: TPanel;
    DialectLabel: TLabel;
    LegacyLabel: TLabel;
    DialectComboBox: TComboBox;
    SubscriptCheckBox: TCheckBox;
    SuperscriptCheckBox: TCheckBox;
    InsertCheckBox: TCheckBox;
    MarkCheckBox: TCheckBox;
    SmartTypographyCheckBox: TCheckBox;
    HeadingAttributesCheckBox: TCheckBox;
    AutoHeadingIdsCheckBox: TCheckBox;
    WikiLinksCheckBox: TCheckBox;
    HTMLDestMemo: TMemo;
    NotePanel: TPanel;
    NoteLinkLabel: TLinkLabel;
    MarkdownToHTML: TMarkdownToHTML;
    FileOpenDialog: TFileOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure DialectComboBoxChange(Sender: TObject);
    procedure LegacyExtensionCheckBoxClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure LoadFileButtonClick(Sender: TObject);
    procedure ProcessButtonClick(Sender: TObject);
    procedure OpenInBrowserButtonClick(Sender: TObject);
    procedure NoteLinkLabelLinkClick(Sender: TObject; const Link: string;
      LinkType: TSysLinkType);
  private
    // folder of the Markdown source: base of its relative links and images
    FSourceFolder: string;
    // writes the [[...]] wiki links (the component does not own it)
    FWikiLinkEmitter: TSpanEmitter;
    FUpdatingOptions: Boolean;
    procedure UpdateOptionControls;
    procedure RefreshHTML;
    function BuildHTMLPage: string;
  end;

var
  MainFormInstance: TMainForm;

implementation

{$R *.dfm}

uses
  Winapi.ShellAPI;

const
  TestFileName = 'TestFile\MarkDown Support Test.md';
  // KaTeX typesets \( \) and \[ \] (math of the GitHub dialect), mermaid.js the
  // <pre class="mermaid"> diagrams: both are loaded by the page, not by the processor
  PageScripts =
    '<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.css">'+sLineBreak+
    '<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.js"></script>'+sLineBreak+
    '<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/contrib/auto-render.min.js"'+
    ' onload="renderMathInElement(document.body);"></script>'+sLineBreak+
    '<script type="module">'+
    'import mermaid from ''https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs'';'+
    'mermaid.initialize({ startOnLoad: true });'+
    '</script>'+sLineBreak;

// The folder of TestFile\MarkDown Support Test.md (the content of the memo at
// design time), searched upward from the executable
function FindTestFileFolder: string;
var
  LFolder, LParent: string;
begin
  Result := '';
  LFolder := ExtractFileDir(ParamStr(0));
  while LFolder <> '' do
  begin
    if FileExists(IncludeTrailingPathDelimiter(LFolder) + TestFileName) then
      Exit(ExtractFilePath(IncludeTrailingPathDelimiter(LFolder) + TestFileName));
    LParent := ExtractFileDir(LFolder);
    if LParent = LFolder then
      Break;
    LFolder := LParent;
  end;
end;

type
  // [[Page name]] -> <a href="Page%20name.md">Page name</a>
  TWikiLinkEmitter = class(TSpanEmitter)
  public
    procedure emitSpan(out_: TStringBuilder; content: String); override;
  end;

procedure TWikiLinkEmitter.emitSpan(out_: TStringBuilder; content: String);
begin
  out_.Append('<a href="' + StringReplace(content, ' ', '%20', [rfReplaceAll]) +
    '.md">' + content + '</a>');
end;

const
  // the items of DialectComboBox
  ComboDialects: array[0..4] of TMarkdownProcessorDialect = (
    mdGitHub, mdGFM, mdCommonMark, mdDaringFireball, mdTxtMark);
  ComboDialectNames: array[0..4] of string = (
    'GitHub (default)', 'GFM', 'CommonMark', 'DaringFireball (legacy)', 'TxtMark (legacy)');

function FileNameToURL(const AFolder: string): string;
begin
  Result := 'file:///' + StringReplace(IncludeTrailingPathDelimiter(AFolder), '\', '/', [rfReplaceAll]);
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  Caption := Application.Title + ' - Copyright © 2026 - Ethea S.r.l.';
  ProcessButton.Font.Style := ProcessButton.Font.Style + [fsBold];
  FSourceFolder := FindTestFileFolder;
  FWikiLinkEmitter := TWikiLinkEmitter.Create;
  MarkdownToHTML.SpecialLinkEmitter := FWikiLinkEmitter;
  for I := Low(ComboDialects) to High(ComboDialects) do
    DialectComboBox.Items.Add(ComboDialectNames[I]);
  UpdateOptionControls;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  MarkdownToHTML.SpecialLinkEmitter := nil;
  FWikiLinkEmitter.Free;
end;

procedure TMainForm.UpdateOptionControls;
var
  I: Integer;
  LCheckBox: TCheckBox;
  LNewEngine: Boolean;
begin
  // the controls show the options of the component
  FUpdatingOptions := True;
  try
    for I := Low(ComboDialects) to High(ComboDialects) do
      if ComboDialects[I] = MarkdownToHTML.ProcessorDialect then
        DialectComboBox.ItemIndex := I;
    // the legacy dialects (DaringFireball, TxtMark) ignore the extensions
    LNewEngine := MarkdownToHTML.ProcessorDialect in [mdCommonMark, mdGFM, mdGitHub];
    for I := 0 to OptionsPanel.ControlCount - 1 do
      if OptionsPanel.Controls[I] is TCheckBox then
      begin
        LCheckBox := TCheckBox(OptionsPanel.Controls[I]);
        LCheckBox.Checked := TMarkdownExtension(LCheckBox.Tag) in MarkdownToHTML.Extensions;
        LCheckBox.Enabled := LNewEngine;
      end;
  finally
    FUpdatingOptions := False;
  end;
end;

procedure TMainForm.RefreshHTML;
begin
  // the component has already converted again its MarkdownContent
  if HTMLDestMemo.Lines.Text <> '' then
    ProcessButtonClick(nil);
end;

procedure TMainForm.DialectComboBoxChange(Sender: TObject);
begin
  if FUpdatingOptions or (DialectComboBox.ItemIndex < 0) then
    Exit;
  // a new dialect resets the extensions to its defaults (legacy ones included)
  MarkdownToHTML.ProcessorDialect := ComboDialects[DialectComboBox.ItemIndex];
  UpdateOptionControls;
  RefreshHTML;
end;

procedure TMainForm.LegacyExtensionCheckBoxClick(Sender: TObject);
var
  LExtension: TMarkdownExtension;
begin
  if FUpdatingOptions then
    Exit;
  LExtension := TMarkdownExtension((Sender as TCheckBox).Tag);
  if (Sender as TCheckBox).Checked then
    MarkdownToHTML.Extensions := MarkdownToHTML.Extensions + [LExtension]
  else
    MarkdownToHTML.Extensions := MarkdownToHTML.Extensions - [LExtension];
  RefreshHTML;
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  // the Markdown source (aligned to the left) takes half of the width
  SourcePanel.Width := (ClientWidth - Splitter.Width) div 2;
end;

procedure TMainForm.LoadFileButtonClick(Sender: TObject);
begin
  if FileOpenDialog.Execute then
  begin
    MarkdownSourceMemo.Lines.Text := TryLoadTextFile(FileOpenDialog.FileName);
    FSourceFolder := ExtractFilePath(FileOpenDialog.FileName);
    HTMLDestMemo.Clear;
  end;
end;

procedure TMainForm.ProcessButtonClick(Sender: TObject);
begin
  // the component converts its MarkdownContent with its options
  // (ProcessorDialect, Extensions, AllowUnsafe, MathRendering, CssStyle)
  MarkdownToHTML.MarkdownContent.Text := MarkdownSourceMemo.Lines.Text;
  HTMLDestMemo.Lines.Text := MarkdownToHTML.HtmlContent.Text;
end;

function TMainForm.BuildHTMLPage: string;
var
  LBase: string;
begin
  if FSourceFolder <> '' then
    LBase := '<base href="' + FileNameToURL(FSourceFolder) + '">' + sLineBreak
  else
    LBase := '';
  Result :=
    '<!DOCTYPE html>' + sLineBreak +
    '<html>' + sLineBreak +
    '<head>' + sLineBreak +
    '<meta charset="utf-8">' + sLineBreak +
    '<title>Markdown Processor Demo</title>' + sLineBreak +
    LBase +
    PageScripts +
    '</head>' + sLineBreak +
    '<body>' + sLineBreak +
    // HtmlContent: the stylesheet (CssStyle) followed by the HTML fragment
    HTMLDestMemo.Lines.Text +
    '</body>' + sLineBreak +
    '</html>' + sLineBreak;
end;

procedure TMainForm.OpenInBrowserButtonClick(Sender: TObject);
var
  LFileName: string;
begin
  if HTMLDestMemo.Lines.Text = '' then
    ProcessButtonClick(Sender);
  LFileName := IncludeTrailingPathDelimiter(GetEnvironmentVariable('TEMP')) +
    'MarkdownProcessorDemo.html';
  SaveUTF8File(LFileName, BuildHTMLPage);
  ShellExecute(Handle, 'open', PChar(LFileName), nil, nil, SW_SHOWNORMAL);
end;

procedure TMainForm.NoteLinkLabelLinkClick(Sender: TObject; const Link: string;
  LinkType: TSysLinkType);
begin
  ShellExecute(Handle, 'open', PChar(Link), nil, nil, SW_SHOWNORMAL);
end;

end.
