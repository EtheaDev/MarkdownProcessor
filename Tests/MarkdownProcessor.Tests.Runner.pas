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
{  The runner follows the model of Markdown4D (MIT, (c) 2026 GDK Software):    }
{  see LICENSE-Markdown4D.txt.                                                 }
{                                                                              }
{******************************************************************************}
unit MarkdownProcessor.Tests.Runner;

interface

type
  TMarkdownTestRunner = class
  public
    /// <summary>Runs all registered fixtures with console + NUnit XML loggers and
    /// writes the conformance dashboard. Sets ExitCode to 1 on failures.</summary>
    class procedure Run;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  DUnitX.TestFramework,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  MarkdownProcessor.Tests.Corpus;

const
{$IFDEF WIN64}
  PlatformName = 'Win64';
{$ELSE}
  PlatformName = 'Win32';
{$ENDIF}

class procedure TMarkdownTestRunner.Run;
begin
  try
    TDUnitX.CheckCommandLine;

    var ResultsFile := TDUnitX.Options.XMLOutputFile;
    if ResultsFile = '' then
      ResultsFile := TPath.Combine(TTestPaths.ResultsFolder, Format('dunitx-results-%s.xml', [PlatformName]));
    TDirectory.CreateDirectory(TPath.GetDirectoryName(TPath.GetFullPath(ResultsFile)));

    const Runner = TDUnitX.CreateRunner;
    Runner.UseRTTI := True;
    Runner.FailsOnNoAsserts := False;
    Runner.AddLogger(TDUnitXConsoleLogger.Create(True));
    Runner.AddLogger(TDUnitXXMLNUnitFileLogger.Create(ResultsFile));

    const RunResults = Runner.Execute;

    if TConformanceLog.HasResults then
    begin
      const Dashboard = TPath.Combine(TTestPaths.ResultsFolder, Format('conformance-%s.md', [PlatformName]));
      TConformanceLog.WriteDashboard(Dashboard);
      System.Writeln('Conformance dashboard: ' + Dashboard);
    end;

    if (RunResults.FailureCount + RunResults.ErrorCount) > 0 then
      ExitCode := 1
    else
      ExitCode := 0;
  except
    on E: Exception do
    begin
      System.Writeln(Format('%s: %s', [E.ClassName, E.Message]));
      ExitCode := 2;
    end;
  end;
end;

end.
