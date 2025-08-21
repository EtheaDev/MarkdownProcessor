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
unit MDProcessorCLI.Bootstrap;

interface

procedure BootstrapCli;

implementation

uses
  System.SysUtils,
  VSoft.CommandLine.Options,
  MDProcessorCLI.Commands,
  MDProcessorCLI.Options,
  MDProcessorCLI.ResourceStrings,
  MarkdownUtils;

procedure BootstrapCli;
var
  LCommand: TCommandDefinition;
  LOption: IOptionDefinition;
begin

  //
  // PREFERENCES
  //

  // Preferences
  TOptionsRegistry.DescriptionTab := 30;
  TOptionsRegistry.NameValueSeparator := ':';

  //
  // GLOBAL OPTIONS
  //

  // Global Option: "dialect"
  LOption := TOptionsRegistry.RegisterOption<TDialectOption>('dialect', 'd',
    StrCmdTransformDialect,
    procedure (const AValue: TDialectOption)
    begin
      TOptionsForProcessFile.ProcessorDialect := AValue;
    end);
  LOption.Required := False;

  // Global Option: "style"
  LOption := TOptionsRegistry.RegisterOption<TFileName>('style', 's',
    Format('%s (%s)', [StrOptStylefile, StrOptional]),
    procedure (const AValue: TFileName)
    begin
      TOptionsForOutput.StyleSheetFileName := AValue;
    end);
  LOption.Required := False;

  //
  // OPERATION: Help
  //

  // Command: "help"
  LCommand := TOptionsRegistry.RegisterCommand('help', '?',
    StrCmdHelpDescription, StrCmdHelpInfo, 'help <command>');

  // Option: "command"
  LOption := LCommand.RegisterUnNamedOption<string>(
    StrCmdHelpCommandInfo, 'command',
    procedure (const AValue: string)
    begin
      if Length(AValue) > 0 then
        TOptionsForHelp.CommandName := AValue
      else
        TOptionsForHelp.CommandName := 'help';
    end);
  LOption.Required := False;

  //
  // OPERATION: processfile
  //

  // Command: "processfile"
  LCommand := TOptionsRegistry.RegisterCommand(TOptionsForProcessFile.PROCESSFILE_COMMAND, 't',
    StrCmdTransformDescription, StrCmdTransformInfo,
    TOptionsForProcessFile.PROCESSFILE_COMMAND+' -in:<InputFileName> <options>');

  LCommand.Examples.Add(TOptionsForProcessFile.PROCESSFILE_COMMAND+' -in:InputFile.md -dialect:mdDaringFireball');
  LCommand.Examples.Add(TOptionsForProcessFile.PROCESSFILE_COMMAND+' -in:InputFile.md -out:c:\temp\OutputFile.html');
  LCommand.Examples.Add(TOptionsForProcessFile.PROCESSFILE_COMMAND+' -in:InputFile.md -out:c:\temp\OutputFile.html -style: StyleSheet.css');

  // processfile Option: "in"
  LOption := LCommand.RegisterOption<TFileName>('in', 'i',
    Format('%s (%s)', [StrOptInputfile, StrRequired]),
    procedure(const AValue: TFileName)
    begin
      TOptionsForInput.InputFileName := AValue;
    end);
  LOption.Required := True;

  // processfile Option: "out"
  LOption := LCommand.RegisterOption<TFileName>('out', 'o',
    Format('%s (%s)', [StrOptOutputfile, StrOptional]),
    procedure(const AValue: TFileName)
    begin
      TOptionsForOutput.OutputfileName := AValue;
    end);
  LOption.Required := False;

  // Handler
  TCommandBroker.RegisterCommand(TOptionsForProcessFile.PROCESSFILE_COMMAND,
    procedure ()
    begin
      TOptionsForProcessFile.Execute;
    end);

end;

end.
