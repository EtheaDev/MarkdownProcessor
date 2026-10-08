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
unit MarkdownProcessor.Tests.Legacy;

{ Snapshot tests for the legacy dialects (mdDaringFireball, mdTxtMark).
  docs/COMMONMARK_PLAN.md (decision D1) requires that the new engine leaves them
  untouched: their current output on TestFile\*.md and on the whole CommonMark
  corpus (safe and unsafe) is stored in Tests\snapshots and must not change.

  To (re)record the snapshots set the environment variable MDP_RECORD_SNAPSHOTS=1
  (RunTests.cmd /record does it). Record only from a known good engine. }

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TLegacySnapshotTests = class
  public
    [Test]
    [TestCase('DaringFireball', 'DaringFireball')]
    [TestCase('TxtMark', 'TxtMark')]
    procedure Legacy_TestFile_Unchanged(const DialectName: string);

    [Test]
    [TestCase('DaringFireball', 'DaringFireball')]
    [TestCase('TxtMark', 'TxtMark')]
    procedure Legacy_CommonMarkCorpus_Unchanged(const DialectName: string);
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.JSON,
  System.Generics.Collections,
  MarkdownUtils,
  MarkdownProcessor,
  MarkdownProcessor.Tests.Corpus;

const
  RecordEnvironmentVariable = 'MDP_RECORD_SNAPSHOTS';
  MaxReportedDifferences = 10;
  LegacyRandSeed = 20261004;

type
  TSnapshotEntry = TPair<string, string>; // id, html

  TSnapshot = class
  private
    class function FileNameFor(const DialectName, Source: string): string;
  public
    class function IsRecording: Boolean;
    class procedure Save(const FileName: string; const Entries: TList<TSnapshotEntry>);
    class procedure Load(const FileName: string; const Entries: TDictionary<string, string>);
    class procedure Verify(const DialectName, Source: string; const Actual: TList<TSnapshotEntry>);
  end;

function DialectFromName(const DialectName: string): TMarkdownProcessorDialect;
begin
  if SameText(DialectName, 'DaringFireball') then
    Result := mdDaringFireball
  else if SameText(DialectName, 'TxtMark') then
    Result := mdTxtMark
  else
    raise Exception.CreateFmt('Unknown legacy dialect "%s"', [DialectName]);
end;

function Render(const Dialect: TMarkdownProcessorDialect; const Source: string; const Unsafe: Boolean): string;
begin
  const Processor = TMarkdownProcessor.CreateDialect(Dialect);
  try
    Processor.AllowUnsafe := Unsafe;
    // The legacy engine obfuscates e-mail autolinks choosing decimal or hex
    // entities with random(2) (MarkdownUtils): a fixed seed makes it repeatable.
    RandSeed := LegacyRandSeed;
    try
      Result := NormalizeLineEndings(Processor.Process(Source));
    except
      // An exception is part of the legacy behavior too: it is snapshotted as text.
      on E: Exception do
        Result := Format('<<%s: %s>>', [E.ClassName, E.Message]);
    end;
  finally
    Processor.Free;
  end;
end;

procedure AddRenderings(const Entries: TList<TSnapshotEntry>; const Dialect: TMarkdownProcessorDialect;
  const Id, Source: string);
begin
  Entries.Add(TSnapshotEntry.Create(Id + ' safe', Render(Dialect, Source, False)));
  Entries.Add(TSnapshotEntry.Create(Id + ' unsafe', Render(Dialect, Source, True)));
end;

{ TSnapshot }

class function TSnapshot.FileNameFor(const DialectName, Source: string): string;
begin
  Result := TPath.Combine(TTestPaths.SnapshotsFolder, Format('legacy-%s-%s.json', [DialectName, Source]));
end;

class function TSnapshot.IsRecording: Boolean;
begin
  Result := GetEnvironmentVariable(RecordEnvironmentVariable) = '1';
end;

class procedure TSnapshot.Save(const FileName: string; const Entries: TList<TSnapshotEntry>);
begin
  // One entry per line keeps the files reviewable in a diff.
  const SB = TStringBuilder.Create;
  try
    SB.Append('['#10);
    for var I := 0 to Entries.Count - 1 do
    begin
      const Item = TJSONObject.Create;
      try
        Item.AddPair('id', Entries[I].Key);
        Item.AddPair('html', Entries[I].Value);
        SB.Append(Item.ToJSON);
      finally
        Item.Free;
      end;
      if I < Entries.Count - 1 then
        SB.Append(',');
      SB.Append(#10);
    end;
    SB.Append(']'#10);
    TDirectory.CreateDirectory(TPath.GetDirectoryName(FileName));
    const Utf8NoBom = TUTF8Encoding.Create(False);
    try
      TFile.WriteAllText(FileName, SB.ToString, Utf8NoBom);
    finally
      Utf8NoBom.Free;
    end;
  finally
    SB.Free;
  end;
end;

class procedure TSnapshot.Load(const FileName: string; const Entries: TDictionary<string, string>);
begin
  const Root = TJSONObject.ParseJSONValue(TFile.ReadAllText(FileName, TEncoding.UTF8));
  try
    if not (Root is TJSONArray) then
      raise Exception.CreateFmt('Snapshot "%s" does not contain a JSON array', [FileName]);
    for var Value in TJSONArray(Root) do
    begin
      const Item = Value as TJSONObject;
      Entries.AddOrSetValue(Item.GetValue<string>('id'), Item.GetValue<string>('html'));
    end;
  finally
    Root.Free;
  end;
end;

class procedure TSnapshot.Verify(const DialectName, Source: string; const Actual: TList<TSnapshotEntry>);
begin
  const FileName = FileNameFor(DialectName, Source);
  if IsRecording then
  begin
    Save(FileName, Actual);
    Assert.Pass(Format('Snapshot recorded: %s (%d entries)', [FileName, Actual.Count]));
  end;

  if not TFile.Exists(FileName) then
    Assert.Fail(Format('Snapshot "%s" is missing: record it with RunTests.cmd /record', [FileName]));

  const Expected = TDictionary<string, string>.Create;
  const Differences = TStringList.Create;
  try
    Load(FileName, Expected);
    var FirstDetail := '';
    for var Entry in Actual do
    begin
      var ExpectedHtml: string;
      if not Expected.TryGetValue(Entry.Key, ExpectedHtml) then
      begin
        Differences.Add(Entry.Key + ' (not in snapshot)');
        Continue;
      end;
      if ExpectedHtml = Entry.Value then
        Continue;
      if Differences.Count = 0 then
        FirstDetail := Format('%s'#10'--- Expected HTML:'#10'%s'#10'--- Actual HTML:'#10'%s',
          [Entry.Key, ExpectedHtml, Entry.Value]);
      Differences.Add(Entry.Key);
    end;
    if Expected.Count <> Actual.Count then
      Differences.Add(Format('snapshot has %d entries, run produced %d', [Expected.Count, Actual.Count]));

    if Differences.Count > 0 then
    begin
      var Listed := '';
      for var I := 0 to Differences.Count - 1 do
      begin
        if I = MaxReportedDifferences then
        begin
          Listed := Listed + Format(#10'  ... and %d more', [Differences.Count - I]);
          Break;
        end;
        Listed := Listed + #10'  ' + Differences[I];
      end;
      Assert.Fail(Format('%s output changed against %s (%d differences):%s'#10'First difference:'#10'%s',
        [DialectName, TPath.GetFileName(FileName), Differences.Count, Listed, FirstDetail]));
    end;
  finally
    Differences.Free;
    Expected.Free;
  end;
end;

{ TLegacySnapshotTests }

procedure TLegacySnapshotTests.Legacy_TestFile_Unchanged(const DialectName: string);
begin
  const Dialect = DialectFromName(DialectName);
  const TestFileFolder = TPath.Combine(TTestPaths.RepositoryFolder, 'TestFile');
  var Files: TArray<string> := TDirectory.GetFiles(TestFileFolder, '*.md');
  Assert.IsTrue(Length(Files) > 0, 'No .md file in ' + TestFileFolder);
  TArray.Sort<string>(Files);

  const Entries = TList<TSnapshotEntry>.Create;
  try
    for var FileName in Files do
      AddRenderings(Entries, Dialect, 'TestFile/' + TPath.GetFileName(FileName),
        TFile.ReadAllText(FileName, TEncoding.UTF8));
    TSnapshot.Verify(DialectName, 'TestFile', Entries);
  finally
    Entries.Free;
  end;
end;

procedure TLegacySnapshotTests.Legacy_CommonMarkCorpus_Unchanged(const DialectName: string);
begin
  const Dialect = DialectFromName(DialectName);
  const Examples = TCorpus.LoadExamples(TTestPaths.SpecFile('commonmark-0.31.2.json'));

  const Entries = TList<TSnapshotEntry>.Create;
  try
    for var Example in Examples do
      AddRenderings(Entries, Dialect, '#' + IntToStr(Example.Number), Example.Markdown);
    TSnapshot.Verify(DialectName, 'CommonMark', Entries);
  finally
    Entries.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TLegacySnapshotTests);

end.
