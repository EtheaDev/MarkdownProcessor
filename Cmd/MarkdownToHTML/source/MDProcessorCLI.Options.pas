{******************************************************************************}
{                                                                              }
{   MarkDown To HTML Processor Command Line                                    }
{                                                                              }
{   Copyright (c) 2025 (Ethea S.r.l.)                                          }
{   Author: Carlo Barazzetta                                                   }
{                                                                              }
{   https://github.com/EtheaDev/MarkdownProcessor                              }
{                                                                              }
{   Based on: Delphi Day 2020: Una CLI che i tuoi utenti ameranno              }
{             by Marco Breveglieri                                             }
{   https://www.breveglieri.it/eventi/2020-06-11-delphiday-creare-client-cli/  }
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
unit MDProcessorCLI.Options;

interface

uses
  System.SysUtils;

const
  EXITCODE_OK = 0;
  EXITCODE_UNDEFINED_ERROR = -1;
  EXITCODE_PARSE_ERROR = 1;

type
  TDialectOption = (CommonMark, DaringFireball, TxtMark, GFM, GitHub);
  TFolderName = string;

const
  ADialects : Array[TDialectOption] of string =
    ('CommonMark', 'DaringFireball', 'TxtMark', 'GFM', 'GitHub');

type
  TOptionsForHelp = class
  public
    class var CommandName: string;
  end;

  TOptionsForInput = class
  public
  class var
    InputFileName: TFileName;
  end;

  TOptionsForOutput = class
  public
  class var
    OutputFileName: TFileName;
    StyleSheetFileName: TFileName;
  end;

  TOptionsForInputFolder = class
  public
  class var
    InputFolderName: TFolderName;
  end;

  TOptionsForOutputFolder = class
  public
  class var
    OutputFolderName: TFolderName;
    StyleSheetFileName: TFileName;
  end;

  TOptionsForProcessFile = class
  public
  const PROCESSFILE_COMMAND = 'processfile';
  class var
    ProcessorDialect: TDialectOption;
    Encoding: TEncoding;
    UnsafeMode: Boolean;
  class constructor Create;
  class procedure Execute;
  end;

  TOptionsForProcessFolder = class
  public
  const PROCESSFOLDER_COMMAND = 'processfolder';
  class var
    ProcessorDialect: TDialectOption;
    Encoding: TEncoding;
  class constructor Create;
  class procedure Execute;
  end;

implementation

uses
  System.Classes,
  MarkdownProcessor,
  MarkdownUtils,
  MDProcessorCLI.ResourceStrings,
  MDProcessorCLI.Console;

{ TOptionsForProcessFile }

class constructor TOptionsForProcessFile.Create;
begin
  //Default Dialect to Use
  ProcessorDialect := GitHub;
  Encoding := TEncoding.UTF8;
  //Default to safe mode (active content like <script>, <iframe>... is neutralized)
  UnsafeMode := False;
end;

class procedure TOptionsForProcessFile.Execute;
var
  LProcessor: TMarkdownProcessor;
  LStyleContent, LHTMLContent: string;
  LStringStream: TStringStream;

begin
  TConsole.LogInfoSuccess(StrStartCommand, PROCESSFILE_COMMAND, True);

  case ProcessorDialect of
    DaringFireball: LProcessor := TMarkdownProcessor.CreateDialect(mdDaringFireball);
    TxtMark: LProcessor := TMarkdownProcessor.CreateDialect(mdTxtMark);
    GFM: LProcessor := TMarkdownProcessor.CreateDialect(mdGFM);
    CommonMark: LProcessor := TMarkdownProcessor.CreateDialect(mdCommonMark);
  else //GitHub (default)
    LProcessor := TMarkdownProcessor.CreateDialect(mdGitHub);
  end;
  //The output is a standalone page without scripts: math as images (as the
  //previous versions did), mermaid diagrams as their source
  LProcessor.Config.MathRendering := mmrCodeCogsImage;
  TConsole.LogInfoSuccess(StrDialectUsed, ADialects[ProcessorDialect]);

  //Apply safe/unsafe mode: when UnsafeMode is True active content (scripts,
  //iframes, etc.) coming from the markdown is emitted as-is instead of being
  //omitted (CommonMark, GFM) or escaped (DaringFireball, TxtMark).
  LProcessor.AllowUnsafe := UnsafeMode;
  if UnsafeMode then
    TConsole.LogInfoSuccess(StrUnsafeMode, StrUnsafeModeOn)
  else
    TConsole.LogInfoSuccess(StrUnsafeMode, StrUnsafeModeOff);

  try
    //Check Input File
    TConsole.LogInfoSuccess(StrOptInputfile, TOptionsForInput.InputFileName);
    if not FileExists(TOptionsForInput.InputFileName) then
      raise Exception.CreateFmt(StrErrFileNotFount, [TOptionsForInput.InputFileName]);

    //Check StyleSheet Input File
    if (TOptionsForOutput.StyleSheetFileName <> '') then
    begin
      if SameText(TOptionsForOutput.StyleSheetFileName, 'none') then
      begin
        TConsole.LogInfoSuccess(StrOptStylefile, StrNoStyle);
        LStyleContent := '';
      end
      else
      begin
        TConsole.LogInfoSuccess(StrOptStylefile, TOptionsForOutput.StyleSheetFileName);

        if not FileExists(TOptionsForOutput.StyleSheetFileName) then
          raise Exception.CreateFmt(StrErrFileNotFount, [TOptionsForOutput.StyleSheetFileName])
        else
        begin
          LStringStream := TStringStream.Create('', Encoding);
          try
            LStringStream.LoadFromFile(TOptionsForOutput.StyleSheetFileName);
            LStyleContent := LStringStream.DataString;
          finally
            LStringStream.Free;
          end;
        end;
      end;
    end
    else
    begin
      TConsole.LogInfoSuccess(StrOptStylefile, StrDefault);
      LStyleContent := MarkdownDefaultCSS;
    end;

    //Initialize Output FileName
    if TOptionsForOutput.OutputFileName = '' then
      TOptionsForOutput.OutputFileName := ChangeFileExt(TOptionsForInput.InputFileName, '.html');

    //Tranformation
    TConsole.LogInfoSuccess(StrStartTransformation, '');
    LHTMLContent := LStyleContent+LProcessor.ProcessFile(TOptionsForInput.InputFileName, Encoding);
    LStringStream := TStringStream.Create(LHTMLContent, Encoding);
    try
      TConsole.LogInfoSuccess(StrSavingOutput, TOptionsForOutput.OutputFileName);
      LStringStream.SaveToFile(TOptionsForOutput.OutputFileName);
    finally
      LStringStream.Free;
    end;
  finally
    LProcessor.Free;
  end;
  TConsole.LogInfoSuccess(StrDoneCommand, PROCESSFILE_COMMAND, True);
end;

{ TOptionsForProcessFolder }

class constructor TOptionsForProcessFolder.Create;
begin
  //Default Dialect to Use
  ProcessorDialect := GitHub;
  Encoding := TEncoding.UTF8;
end;

class procedure TOptionsForProcessFolder.Execute;
begin
  TConsole.LogInfoSuccess(StrStartCommand, PROCESSFOLDER_COMMAND, True);

  //TODO

  TConsole.LogInfoSuccess(StrDoneCommand, PROCESSFOLDER_COMMAND, True);
end;

end.
