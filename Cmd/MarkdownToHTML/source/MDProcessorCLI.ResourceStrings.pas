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
unit MDProcessorCLI.ResourceStrings;

interface

resourcestring

  // Errors
  StrErrFileNotFount = 'Error: File "%s" not found!';
  StrErrParseCommand = 'Error in params of command "%s":%s%s';
  StrErrCommandUnknown = 'Unknown or unvailable Command: "%s"';

  //Messages
  StrCommand = 'Command';
  StrStartCommand = 'Starting Command';
  StrDoneCommand = 'Command Done';
  StrDialectUsed = 'Dialect used';
  StrOptional = '(Optional)';
  StrRequired = '(Required)';
  StrDefault = '(default)';
  StrNoStyle = '(Do not use any StyleSheet)';
  StrUnsafeMode = 'Unsafe mode';
  StrUnsafeModeOn = 'ON (active content is NOT escaped - use only with trusted sources)';
  StrUnsafeModeOff = 'OFF (active content like <script>, <iframe>... is escaped)';

  // General Options
  StrCmdTransformDialect = 'The dialect used for transformation: CommonMark (default), DaringFireball, TxtMark';
  StrCmdUnsafeMode = 'Allow unsafe/active HTML content (<script>, <iframe>, <object>...) in the output instead of escaping it. Off by default; enable only for trusted input.';

  // Command: transform
  StrCmdTransformDescription = 'Convert a Markdown file to HTML';
  StrCmdTransformInfo = 'Process and transform a markdown file into an HTML file using a '+
    'specific dialect and a specific stylesheet for formatting the HTML.';

  // Command: transform / options
  StrOptInputfile = 'Markdown input file to be processed';
  StrOptOutputfile = 'HTML output file to generate';
  StrOptStylefile = 'Stylesheet file applied to HTML output';
  StrStartTransformation = 'Start transformation...';
  StrSavingOutput = 'Saving output file...';
  StrOptInputfolder = 'Input folder contains Markdown files to be processed';
  StrOptOutputfolder = 'Output folder contains HTML files to generate';


  StrCmdHelpDescription = 'Show Help of a command';
  StrCmdHelpInfo = 'View informations about how the commands work '+
    'and the options you can specify.';
  StrCmdHelpCommandInfo = 'Command for which to call up the guide';

implementation

end.
