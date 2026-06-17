# Markdown Processor and MarkDownToHTML.exe utility[![License](https://img.shields.io/badge/License-Apache%202.0-yellowgreen.svg)](https://opensource.org/licenses/Apache-2.0)

A Markdown Processor Library for Delphi, to process/convert markdown files to HTML.

A Useful utility: **MarkDownToHTML.exe** to transform any markdown file to HTML

**Latest Version 1.4.1 - 17 Jun 2026**

![Support Delphi](/images/SupportingDelphi.jpg)

This library is compatible from Delphi XE3 version to latest.

[www.embarcadero.com](https://www.embarcadero.com/) - [learndelphi.org](https://learndelphi.org/)

---

## Using the MarkDownToHTML.exe utility

With MarkDownToHTML.exe you can transform a markdown file to HTML using different markdown dialects or StyleSheet.

[Download the utility](https://github.com/EtheaDev/MarkdownProcessor/releases/latest/download/MarkDownToHTML.exe).

run **MarkDownToHTML.exe help processfile** for a complete help.

Look into Cmd\MarkdownToHTML\Test\MarkDownToHTML_Test.cmd for examples

---

## Basic Informations for Delphi users

This is a Pascal (Delphi) library that processes markdown to HTML.
At present the following dialects of markdown are supported:

* The Daring Fireball dialect
 (see <https://daringfireball.net/projects/markdown/>)
* Almost complete support for CommonMark dialect
 (translated from <http://commonmark.org/>)
* Enhanced TxtMark dialect
 (translated from <https://github.com/rjeschke/txtmark>)



### Using the Library with Delphi

Declare a variable of the class TMarkdownProcessor:

```Pascal
     var
       md : TMarkdownProcessor;
```

Create a TMarkdownProcessor (MarkdownProcessor.pas) of the dialect you want:

```Pascal
       md := TMarkdownProcessor.createDialect(mdDaringFireball)
```

Decide whether you want to allow active content

```Pascal
       md.AllowUnSafe := true;
```

Note: you should only set this to true if you *need* to - active content can be a significant safety/security issue.

Generate HTML fragments from Markdown content:

```Pascal
       html := md.process(markdown);
```

Note that the HTML returned is an HTML fragment, not a full HTML page.

Do not forget to dispose of the object after the use:

```Pascal
       md.free
```

Large rework was made for adding support for tables, math formulas, etc.

## Delphi projects Examples

This library is used in two projects:

- [MarkdownShellExtensions](https://github.com/EtheaDev/MarkdownShellExtensions)

A collection of tools for markdown files, to edit and view content, with an advanced Editor:

![Markdown Text Editor](./images/MDTextEditorLight.png)

- [MarkdownHelpViewer](https://github.com/EtheaDev/MarkdownHelpViewer)

An integrated help system based on files in Markdown format (and also html), for Delphi applications:

![Markdown HelpViewer](./images/ContentPage.png)

## Release Notes ##

17 Jun 2026: ver. 1.4.1
- fixed tables: inline constructs no longer span cells
- updated Markdown Support Test.md file
- fixed Allow Unsafe mode

11 Jun 2026: ver. 1.4.0
- Added "-unsafe" command line option to MarkDownToHTML.exe (safe mode is the default)
- Fixed safe mode: unsafe HTML elements (script, iframe, object, applet, frame...) are now correctly escaped
- Math formulas: replaced the deprecated Google Chart API with the CodeCogs LaTeX renderer
- Math formulas: added support for centered formula blocks using the $$...$$ syntax
- Improved tables support
- TUtils.codeEncode now encodes spaces as %20
- Aligned with upstream FPC-markdown by Miguel A. Risco-Castillo

21 Aug 2025: ver. 1.3.0
- Added support for Delphi 13
- Added command line utility MarkDownToHTML.exe

08 Apr 2025: ver. 1.2.0
- Fixed const parameters

16 Dec 2024: ver. 1.1.0
- Updated Demo for FireMonkey

22 Oct 2023: ver. 1.0.0
- Project forked from FPC-markdown by Miguel A. Risco-Castillo
- Removed unused Dialect mdAsciiDoc
- changed position of enumerated dialect mdCommonMark for backward compatibility with Delphi-Markdown

## License

Copyright (c) Ethea S.r.l.

Licensed under the Apache License, Version 2.0 (the "License");

you may not use this file except in compliance with the License.

You may obtain a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

## Contributors

**MarkdownProcessor** implementation is a fork of FPC-markdown by **Miguel A. Risco-Castillo**
[FPC-markdown](https://github.com/mriscoc/fpc-markdown)

FPC-markdown implementation is a fork of **Grahame Grieve** pascal port
[Delphi-markdown](https://github.com/grahamegrieve/delphi-markdown)

---

**MarkDownToHTML.exe** is a CLI based on the project:

**Italian Delphi Day 2020: _Una CLI che i tuoi utenti ameranno_**

by _Marco Breveglieri_

[Go to Slides and Demos page...](https://www.breveglieri.it/eventi/2020-06-11-delphiday-creare-client-cli/)

It also uses **CommandLineParser**

[VSoft.CommandLineParser](https://github.com/VSoftTechnologies/VSoft.CommandLineParser)

by _Vincent Parret_, licensed under the Apache License, Version 2.0 (the "License");