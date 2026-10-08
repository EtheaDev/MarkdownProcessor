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
{  The corpus loader follows the model of Markdown4D (MIT, (c) 2026 GDK        }
{  Software): see LICENSE-Markdown4D.txt.                                      }
{                                                                              }
{******************************************************************************}
unit MarkdownProcessor.Tests.Corpus;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  MarkdownProcessor;

type
  ECorpusError = class(Exception);

  TCorpusExample = record
    Number: Integer;
    Markdown: string;
    ExpectedHtml: string;
    Section: string;
  end;

  /// <summary>Creates the processor an example is run through. The caller frees it.</summary>
  TProcessorFactory = reference to function: TMarkdownProcessor;
  /// <summary>Creates the processor for the examples of a section (corpora whose
  /// sections need different dialects or extensions).</summary>
  TSectionProcessorFactory = reference to function(const Section: string): TMarkdownProcessor;

  /// <summary>Locates the folders of the test project, searching upward from the executable.</summary>
  TTestPaths = class
  public
    class function TestsFolder: string;
    class function RepositoryFolder: string;
    class function SpecFile(const FileName: string): string;
    class function SnapshotsFolder: string;
    class function ResultsFolder: string;
  end;

  /// <summary>A JSON corpus of Markdown/HTML examples (CommonMark spec.json shape).</summary>
  TCorpus = class
  private
    FName: string;
    FEngine: string;
    FFactory: TProcessorFactory;
    FSectionFactory: TSectionProcessorFactory;
    FExamples: TArray<TCorpusExample>;
    function RunExample(const Example: TCorpusExample; out Detail: string): Boolean;
  public
    /// <param name="AName">Name shown in failures and in the dashboard.</param>
    /// <param name="AFileName">File name inside Tests\specs.</param>
    /// <param name="AEngine">Description of the engine under test (dashboard).</param>
    /// <param name="AFactory">Creates the processor every example runs through.</param>
    constructor Create(const AName, AFileName, AEngine: string; const AFactory: TProcessorFactory); overload;
    constructor Create(const AName, AFileName, AEngine: string; const AFactory: TSectionProcessorFactory); overload;
    class function LoadExamples(const FilePath: string): TArray<TCorpusExample>;
    function Count: Integer;
    function Sections: TArray<string>;
    /// <summary>Runs every example of a section. Returns '' when all pass,
    /// otherwise a report with all failing numbers and the first failure in full.
    /// Each result is recorded in TConformanceLog.</summary>
    function CheckSection(const Section: string): string;
    property Name: string read FName;
    property Examples: TArray<TCorpusExample> read FExamples;
  end;

  /// <summary>Collects per-example results of the corpus runs and writes CONFORMANCE.md.</summary>
  TConformanceLog = class
  private
    type
      TSectionResult = class
        Name: string;
        Total: Integer;
        Run: Integer;
        Passed: Integer;
        Failing: TList<Integer>;
        constructor Create(const AName: string);
        destructor Destroy; override;
      end;
      TCorpusResult = class
        Name: string;
        Engine: string;
        Sections: TObjectList<TSectionResult>;
        constructor Create(const AName, AEngine: string);
        destructor Destroy; override;
        function Find(const ASection: string): TSectionResult;
      end;
    class var
      FCorpora: TObjectList<TCorpusResult>;
    class function FindCorpus(const AName: string): TCorpusResult;
    class function FormatRate(const Passed, Total: Integer): string;
    class function FormatNumbers(const Numbers: TList<Integer>): string;
  public
    class constructor Create;
    class destructor Destroy;
    class procedure RegisterCorpus(const Corpus: TCorpus; const Engine: string);
    class procedure RecordResult(const CorpusName, Section: string; const Number: Integer; const Passed: Boolean);
    class function HasResults: Boolean;
    class function BuildMarkdown: string;
    class procedure WriteDashboard(const FileName: string);
  end;

/// <summary>CRLF and lone CR become LF: the only normalization the strict comparison applies.</summary>
function NormalizeLineEndings(const Value: string): string;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.JSON;

const
  SpecsFolderName = 'specs';
  SnapshotsFolderName = 'snapshots';
  ResultsFolderName = 'results';
  MarkerFile = 'MarkdownProcessor.Tests.dpr';

function NormalizeLineEndings(const Value: string): string;
begin
  Result := StringReplace(Value, #13#10, #10, [rfReplaceAll]);
  Result := StringReplace(Result, #13, #10, [rfReplaceAll]);
end;

{ TTestPaths }

class function TTestPaths.TestsFolder: string;
begin
  var Directory := TPath.GetDirectoryName(TPath.GetFullPath(ParamStr(0)));
  while Directory <> '' do
  begin
    if TFile.Exists(TPath.Combine(Directory, MarkerFile)) then
      Exit(Directory);
    const Nested = TPath.Combine(Directory, 'Tests');
    if TFile.Exists(TPath.Combine(Nested, MarkerFile)) then
      Exit(Nested);
    const Parent = TPath.GetDirectoryName(Directory);
    if (Parent = Directory) then
      Break;
    Directory := Parent;
  end;
  raise ECorpusError.CreateFmt('Tests folder (containing %s) not found searching upward from "%s"',
    [MarkerFile, ParamStr(0)]);
end;

class function TTestPaths.RepositoryFolder: string;
begin
  Result := TPath.GetDirectoryName(TestsFolder);
end;

class function TTestPaths.SpecFile(const FileName: string): string;
begin
  Result := TPath.Combine(TPath.Combine(TestsFolder, SpecsFolderName), FileName);
  if not TFile.Exists(Result) then
    raise ECorpusError.CreateFmt('Spec file "%s" not found', [Result]);
end;

class function TTestPaths.SnapshotsFolder: string;
begin
  Result := TPath.Combine(TestsFolder, SnapshotsFolderName);
end;

class function TTestPaths.ResultsFolder: string;
begin
  Result := TPath.Combine(TestsFolder, ResultsFolderName);
end;

{ TCorpus }

constructor TCorpus.Create(const AName, AFileName, AEngine: string; const AFactory: TProcessorFactory);
begin
  inherited Create;
  FName := AName;
  FEngine := AEngine;
  FFactory := AFactory;
  FExamples := LoadExamples(TTestPaths.SpecFile(AFileName));
  TConformanceLog.RegisterCorpus(Self, AEngine);
end;

constructor TCorpus.Create(const AName, AFileName, AEngine: string; const AFactory: TSectionProcessorFactory);
begin
  Create(AName, AFileName, AEngine, TProcessorFactory(nil));
  FSectionFactory := AFactory;
end;

class function TCorpus.LoadExamples(const FilePath: string): TArray<TCorpusExample>;
begin
  const Root = TJSONObject.ParseJSONValue(TFile.ReadAllText(FilePath, TEncoding.UTF8));
  try
    if not (Root is TJSONArray) then
      raise ECorpusError.CreateFmt('Spec file "%s" does not contain a JSON array', [FilePath]);
    const Items = TJSONArray(Root);
    SetLength(Result, Items.Count);
    for var I := 0 to Items.Count - 1 do
    begin
      const Item = Items.Items[I] as TJSONObject;
      Result[I].Number := Item.GetValue<Integer>('example');
      Result[I].Markdown := Item.GetValue<string>('markdown');
      Result[I].ExpectedHtml := Item.GetValue<string>('html');
      Result[I].Section := Item.GetValue<string>('section');
    end;
  finally
    Root.Free;
  end;
end;

function TCorpus.Count: Integer;
begin
  Result := Length(FExamples);
end;

function TCorpus.Sections: TArray<string>;
begin
  const List = TList<string>.Create;
  try
    for var Example in FExamples do
      if not List.Contains(Example.Section) then
        List.Add(Example.Section);
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

function TCorpus.RunExample(const Example: TCorpusExample; out Detail: string): Boolean;
var
  Processor: TMarkdownProcessor;
  Actual: string;
begin
  Detail := '';
  const Expected = NormalizeLineEndings(Example.ExpectedHtml);
  const Header = Format('Example %d (%s)'#10'--- Markdown:'#10'%s'#10'--- Expected HTML:'#10'%s',
    [Example.Number, Example.Section, Example.Markdown, Expected]);
  try
    if Assigned(FSectionFactory) then
      Processor := FSectionFactory(Example.Section)
    else
      Processor := FFactory();
    try
      Actual := NormalizeLineEndings(Processor.Process(Example.Markdown));
    finally
      Processor.Free;
    end;
    Result := (Actual = Expected);
    if not Result then
      Detail := Header + #10'--- Actual HTML:'#10 + Actual;
  except
    on E: Exception do
    begin
      Result := False;
      Detail := Header + #10'--- Raised ' + E.ClassName + ': ' + E.Message;
    end;
  end;
end;

function TCorpus.CheckSection(const Section: string): string;
begin
  var Total := 0;
  var FirstDetail := '';
  const Failing = TList<Integer>.Create;
  try
    for var Example in FExamples do
    begin
      if Example.Section <> Section then
        Continue;
      Inc(Total);
      var Detail: string;
      const Passed = RunExample(Example, Detail);
      TConformanceLog.RecordResult(FName, Section, Example.Number, Passed);
      if not Passed then
      begin
        if Failing.Count = 0 then
          FirstDetail := Detail;
        Failing.Add(Example.Number);
      end;
    end;
    if Total = 0 then
      Exit(Format('%s: section "%s" contains no examples', [FName, Section]));
    if Failing.Count = 0 then
      Exit('');
    Result := Format('%s, section "%s": %d of %d examples failed: %s'#10'First failure:'#10'%s',
      [FName, Section, Failing.Count, Total, TConformanceLog.FormatNumbers(Failing), FirstDetail]);
  finally
    Failing.Free;
  end;
end;

{ TConformanceLog.TSectionResult }

constructor TConformanceLog.TSectionResult.Create(const AName: string);
begin
  inherited Create;
  Name := AName;
  Failing := TList<Integer>.Create;
end;

destructor TConformanceLog.TSectionResult.Destroy;
begin
  Failing.Free;
  inherited;
end;

{ TConformanceLog.TCorpusResult }

constructor TConformanceLog.TCorpusResult.Create(const AName, AEngine: string);
begin
  inherited Create;
  Name := AName;
  Engine := AEngine;
  Sections := TObjectList<TSectionResult>.Create;
end;

destructor TConformanceLog.TCorpusResult.Destroy;
begin
  Sections.Free;
  inherited;
end;

function TConformanceLog.TCorpusResult.Find(const ASection: string): TSectionResult;
begin
  for var Item in Sections do
    if Item.Name = ASection then
      Exit(Item);
  Result := nil;
end;

{ TConformanceLog }

class constructor TConformanceLog.Create;
begin
  FCorpora := TObjectList<TCorpusResult>.Create;
end;

class destructor TConformanceLog.Destroy;
begin
  FCorpora.Free;
end;

class function TConformanceLog.FindCorpus(const AName: string): TCorpusResult;
begin
  for var Item in FCorpora do
    if Item.Name = AName then
      Exit(Item);
  Result := nil;
end;

class procedure TConformanceLog.RegisterCorpus(const Corpus: TCorpus; const Engine: string);
begin
  if FindCorpus(Corpus.Name) <> nil then
    Exit;
  const Item = TCorpusResult.Create(Corpus.Name, Engine);
  FCorpora.Add(Item);
  for var Example in Corpus.Examples do
  begin
    var Section := Item.Find(Example.Section);
    if Section = nil then
    begin
      Section := TSectionResult.Create(Example.Section);
      Item.Sections.Add(Section);
    end;
    Inc(Section.Total);
  end;
end;

class procedure TConformanceLog.RecordResult(const CorpusName, Section: string; const Number: Integer;
  const Passed: Boolean);
begin
  const Corpus = FindCorpus(CorpusName);
  if Corpus = nil then
    Exit;
  const Item = Corpus.Find(Section);
  if Item = nil then
    Exit;
  Inc(Item.Run);
  if Passed then
    Inc(Item.Passed)
  else
    Item.Failing.Add(Number);
end;

class function TConformanceLog.HasResults: Boolean;
begin
  for var Corpus in FCorpora do
    for var Section in Corpus.Sections do
      if Section.Run > 0 then
        Exit(True);
  Result := False;
end;

class function TConformanceLog.FormatRate(const Passed, Total: Integer): string;
begin
  if Total = 0 then
    Exit('-');
  Result := FormatFloat('0.0', 100 * Passed / Total, TFormatSettings.Invariant) + '%';
end;

class function TConformanceLog.FormatNumbers(const Numbers: TList<Integer>): string;
begin
  // Consecutive numbers are collapsed into ranges: 1, 3-7, 9
  Result := '';
  var I := 0;
  while I < Numbers.Count do
  begin
    var J := I;
    while (J + 1 < Numbers.Count) and (Numbers[J + 1] = Numbers[J] + 1) do
      Inc(J);
    if Result <> '' then
      Result := Result + ', ';
    if J > I then
      Result := Result + Format('%d-%d', [Numbers[I], Numbers[J]])
    else
      Result := Result + IntToStr(Numbers[I]);
    I := J + 1;
  end;
end;

class function TConformanceLog.BuildMarkdown: string;
begin
  const SB = TStringBuilder.Create;
  try
    SB.Append('# Conformance'#10#10);
    SB.Append('Generated by `Tests/RunTests.cmd` from the DUnitX run: do not edit by hand.'#10);
    SB.Append('Comparison is strict: the only normalization is CRLF -> LF.'#10#10);
    SB.Append('| Corpus | Engine | Examples | Passed | Pass rate |'#10);
    SB.Append('|---|---|---:|---:|---:|'#10);
    var GrandTotal := 0;
    var GrandPassed := 0;
    for var Corpus in FCorpora do
    begin
      var Total := 0;
      var Passed := 0;
      var NotRun := 0;
      for var Section in Corpus.Sections do
      begin
        Inc(Total, Section.Total);
        Inc(Passed, Section.Passed);
        Inc(NotRun, Section.Total - Section.Run);
      end;
      Inc(GrandTotal, Total);
      Inc(GrandPassed, Passed);
      SB.AppendFormat('| %s | %s | %d | %d | %s |', [Corpus.Name, Corpus.Engine, Total, Passed,
        FormatRate(Passed, Total)]);
      if NotRun > 0 then
        SB.AppendFormat(' (%d not run)', [NotRun]);
      SB.Append(#10);
    end;
    SB.AppendFormat('| **Total** | | **%d** | **%d** | **%s** |'#10, [GrandTotal, GrandPassed,
      FormatRate(GrandPassed, GrandTotal)]);

    for var Corpus in FCorpora do
    begin
      SB.AppendFormat(#10'## %s (%s)'#10#10, [Corpus.Name, Corpus.Engine]);
      SB.Append('| Section | Examples | Passed | Pass rate | Failing examples |'#10);
      SB.Append('|---|---:|---:|---:|---|'#10);
      for var Section in Corpus.Sections do
      begin
        var Failing: string;
        if Section.Run < Section.Total then
          Failing := 'not run'
        else
          Failing := FormatNumbers(Section.Failing);
        SB.AppendFormat('| %s | %d | %d | %s | %s |'#10, [Section.Name, Section.Total, Section.Passed,
          FormatRate(Section.Passed, Section.Total), Failing]);
      end;
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

class procedure TConformanceLog.WriteDashboard(const FileName: string);
begin
  TDirectory.CreateDirectory(TPath.GetDirectoryName(FileName));
  const Utf8NoBom = TUTF8Encoding.Create(False);
  try
    TFile.WriteAllText(FileName, BuildMarkdown, Utf8NoBom);
  finally
    Utf8NoBom.Free;
  end;
end;

end.
