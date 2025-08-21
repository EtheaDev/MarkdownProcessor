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
program MarkDownToHTML;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  Winapi.Windows,
  VSoft.CommandLine.Options,
  MDProcessorCLI.Console in '..\source\MDProcessorCLI.Console.pas',
  MDProcessorCLI.Bootstrap in '..\source\MDProcessorCLI.Bootstrap.pas',
  MDProcessorCLI.Commands in '..\source\MDProcessorCLI.Commands.pas',
  MDProcessorCLI.Options in '..\source\MDProcessorCLI.Options.pas',
  MDProcessorCLI.ResourceStrings in '..\source\MDProcessorCLI.ResourceStrings.pas';

var
  ParseResult: ICommandLineParseResult;

  procedure Pause;
  {$IFDEF DEBUG}
  var
    LKey: string;
  {$ENDIF}
  begin
    {$IFDEF DEBUG}
    Writeln(Format('ExitCode: %d - Press Return to exit', [ExitCode]));
    ReadLn(LKey);
    {$ENDIF}
  end;

begin

  try
    // Set Console Window Title
    TConsole.SetTitle('MardownToHTML: MarkDown File Processor Utility');
    TConsole.Log(TConsole.GetTitle+sLineBreak, TConsoleLevel.Success);

    // Initialize preferences, commands and CLI Options)
    BootstrapCli;

    // Execute Parsing of Arguments
    ParseResult := TOptionsRegistry.Parse;

    // In case of Errors: exit showing a Error Message and syntax expected
    if ParseResult.HasErrors then
    begin
      ExitCode := EXITCODE_PARSE_ERROR;
      if ParseResult.Command <> EmptyStr then
      TConsole.Log(Format(StrErrParseCommand, 
        [ParseResult.Command, sLineBreak, ParseResult.ErrorText]),
        TConsoleLevel.Error);
      TOptionsRegistry.PrintUsage(ParseResult.Command,
        procedure(const AUsage: string)
        begin
          TConsole.Log(AUsage, TConsoleLevel.Info);
        end);
      Pause;
      Exit;
    end;

    if (ParseResult.Command <> EmptyStr) then
      TConsole.Log(Format('%s: %s', [StrCommand, ParseResult.Command]),
        TConsoleLevel.Warning);

    // If the command is not present or is "help", show the help guide
    if (ParseResult.Command = EmptyStr) or (ParseResult.Command = 'help') then
    begin
      if not TOptionsRegistry.PrintUsage(TOptionsForHelp.CommandName,
        procedure(const AUsage: string)
        begin
          TConsole.Log(AUsage, TConsoleLevel.Info);
        end) then
      begin
        //help command don't exists: print help
        ExitCode := EXITCODE_PARSE_ERROR;
        TOptionsRegistry.PrintUsage('',
        procedure(const AUsage: string)
        begin
          TConsole.Log(AUsage, TConsoleLevel.Info);
        end);
      end;
      Pause;
      Exit;
    end;

    // Execute the command
    TCommandBroker.ExecuteCommand(ParseResult.Command);
    Pause;

    ExitCode := EXITCODE_OK;
  except
    // Exception handler, printed in the Console Log
    on E: Exception do
    begin
      TConsole.Log(Format('%s', [E.Message]),
        TConsoleLevel.Error);
      ExitCode := EXITCODE_UNDEFINED_ERROR;
      Pause;
    end;

  end;

end.
