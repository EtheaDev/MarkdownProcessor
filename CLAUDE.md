# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Delphi (Object Pascal) library that converts Markdown to HTML, plus `MarkDownToHTML.exe`, a console utility built on top of it. The library is a fork chain: FPC-markdown (Risco-Castillo) ← Delphi-markdown (Grieve). Compatible from Delphi XE3 to the latest version. Version control here is **SVN** (`.svn/`), not git.

## Layout

- `source/` — the library itself, no project file: consumers add this folder to their search path and `uses` the units directly.
- `Tests/` — DUnitX conformance/regression suite (Delphi 13 only); `Tests/specs` corpora, `Tests/snapshots` legacy snapshots.
- `docs/` — `COMMONMARK_PLAN.md` (design and phase log of the new engine), `MIGRATION.md` (breaking changes for consumers), third-party license notes.
- `tools/GenerateEntities.py` — regenerates `source/MarkdownEntities.pas` from the WHATWG entity table.
- `Packages/` — Delphi packages, one folder per IDE version (DXE6…D13): `MarkdownProcessor` (runtime, `rtl` only, all the units of `source/`), `dclMarkdownProcessor` (design-time, requires it; nothing to register) and `MarkdownProcessor.groupproj`. DCUs go to `Lib\<version>\` (ignored). When a unit is added to `source/`, add it to every `MarkdownProcessor.dpk`/`.dproj`. Build scripts: `Packages\BuildAllPackages<Version>.ps1` (e.g. `BuildAllPackagesD13.ps1`, default Rebuild Release Win32+Win64; design-time Win64 only on D12+), built on `BuildAllPackages.ps1` and `BuildPackages.ps1` (one project); BDS root `C:\BDS\Studio`.
- `Cmd/MarkdownToHTML/` — the CLI console app (`.dpr`/`.dproj` in `Project/`, units in `source/`); the EXEs are built into `Cmd/Win32/` and `Cmd/Win64/` (ignored by SVN).
- `Setup/` — Inno Setup installer (`Setup.iss`, built by `BuildSetup.bat`) on the `InnoSetupScripts` external: installs the library, builds/installs the packages in the selected RAD Studio versions, and optionally `MarkDownToHTML.exe` (task: 64-bit or 32-bit, from `Cmd/Win64|Win32`, so build the CLI first).
- `Cmd/VSoft.CommandLineParser/Src/` — vendored VSoft.CommandLineParser dependency (the CLI's only third-party dep).
- `TestFile/` — sample `MarkDown Support Test.md` (every feature of mdGitHub + the legacy extensions; its output is pinned by the `legacy-*-TestFile.json` snapshots and checked by `Extensions_SupportTestFile_RendersAllFeatures`: after editing it run `Tests\RunTests.cmd /record`) and reference CSS used by the test script.
- `Demo/MarkdownProcessorDemo/` — VCL demo of `TMarkdownToHTML` (dialect combo, legacy-extension checkboxes, open in browser with KaTeX/mermaid); the memo embeds the TestFile at design time (installed by the Setup).

## Build & test (CLI)

The library has no standalone build — it is compiled as part of any project that includes it. To build the CLI:

```cmd
cd Cmd\MarkdownToHTML\Project
BuildMarkDownToHTML.cmd
```

That script sources `rsvars.bat` from `C:\BDS\Studio\37.0\bin` (RAD Studio install path — adjust per machine) then runs `msbuild MarkDownToHTML.dproj` for both `Win64` and `Win32` in `release` config. It also code-signs the EXEs via an Ethea-internal cert script; that step will fail outside Ethea's build machine — drop it for local builds.

To build a single platform manually:

```cmd
call "C:\BDS\Studio\37.0\bin\rsvars.bat"
msbuild.exe "MarkDownToHTML.dproj" /target:Build /p:Platform=Win64 /p:config=release
```

The DUnitX suite (Delphi 13, Win32 + Win64) is in `Tests/`: run `Tests\RunTests.cmd` (builds both platforms, runs them, regenerates `Tests\CONFORMANCE.md`, exits 0 only when everything passes; `/record` re-records the legacy snapshots of DaringFireball/TxtMark in `Tests\snapshots`, which must never change — record only on purpose). Corpora in `Tests\specs`: CommonMark 0.31.2 (652), GFM 0.29 (24), math (35, from Markdown4D), alerts, extensions, safety. Comparison is strict (only CRLF→LF). There is also a performance fixture with pathological inputs and a time budget: keep the engine linear.

The CLI also has smoke runs in `Cmd\MarkdownToHTML\Test\MarkDownToHTML_Test.cmd`, which exercises the built EXE against `TestFile/` (help output, default CommonMark dialect, DaringFireball, custom stylesheet, `-style:none`). Run it after building to sanity-check the CLI.

CLI usage: `MarkDownToHTML.exe processfile -in:<file.md> [-out:<file.html>] [-dialect:GitHub|CommonMark|GFM|DaringFireball|TxtMark] [-style:<file.css>|none] [-unsafe]`. Run `MarkDownToHTML.exe help processfile` for full help. The `-unsafe` flag maps to `TMarkdownProcessor.AllowUnsafe` (off by default → active HTML is omitted by CommonMark/GFM, escaped by DaringFireball/TxtMark).

## Library architecture

**Entry point** is `MarkdownProcessor.pas` → `TMarkdownProcessor`, an abstract base with a factory:

```pascal
md := TMarkdownProcessor.CreateDialect;         // mdGitHub (DefaultMarkdownDialect); or mdGFM / mdCommonMark / mdDaringFireball / mdTxtMark
md.Config.Extensions := md.Config.Extensions + [mexMath];  // new engine only
md.AllowUnsafe := false;        // true permits scripts/active content — security risk
html := md.Process(markdown);   // returns an HTML *fragment*, not a full page
doc := md.Parse(markdown);      // IMarkdownNode tree (new engine only; legacy raises)
md.Free;
```

`Process` returns a bare fragment with no `<html>`/`<head>`; callers (like the CLI) prepend their own CSS/`<style>` to make a full document.

There are **two engines**:

**New engine** (`mdGitHub` = default, `mdCommonMark`, `mdGFM`) — exact CommonMark 0.31.2 / GFM 0.29 output, two-phase algorithm of the spec appendix (structure follows commonmark.js). Must stay **Delphi XE3 compatible**: no inline `var`/`const`, no `[weak]`, no RTL string+index helpers (their indexing differs between versions), `Ord(C) < $80` instead of `C < #$80` (a two-digit `#$xx` literal is an AnsiChar converted through the code page).
- `MarkdownCommonMark.pas` — `TMarkdownCommonMark` (derives from `TMarkdownProcessor`, not DaringFireball), `TMarkdownGFM`, `TMarkdownGitHub`; wires parser → renderer (extensions, `MathRendering`, mermaid, hooks).
- `MarkdownAST.pas` — `TMarkdownNode` (public fields, linked children) / read-only `IMarkdownNode`; every node forwards its refcount to the document; `TMarkdownWalker` iterative (no recursion on deep trees).
- `MarkdownBlockParser.pas` — phase 1 (containers, lazy continuation, tabs as virtual columns, tables, `$$` blocks, alerts post-process, heading ids).
- `MarkdownInlineParser.pas` — phase 2 (delimiter stack with `openers_bottom`, bracket stack; `~ ^ + =` are exact-length delimiters; GFM autolinks; math; caches that keep pathological input linear).
- `MarkdownHtmlRenderer.pas` — one virtual method per node kind; safe mode; `codeBlockEmitter` / `specialLinkEmitter` hooks.
- Helpers: `MarkdownLinkRefs`, `MarkdownTextUtils`, `MarkdownEntities` (generated), `MarkdownGFM`, `MarkdownMath`, `MarkdownAlerts`, `MarkdownLegacyExt`.
- `MarkdownProcessorComponents.pas` — `TMarkdownToHTML`, non-visual component (palette page `Markdown`, icons in `source/MarkDownProcessor.dcr`, registered by `Packages/MarkdownProcessorRegister.pas` in `dclMarkdownProcessor`): holds the options (`ProcessorDialect`, `Extensions` — reset to `DefaultExtensions(dialect)` when the dialect changes (the dialect defaults plus all `LegacyExtensions` for mdCommonMark/mdGFM/mdGitHub), stored only if different —, `AllowUnsafe`, `MathRendering`, `CssStyle`) and converts `MarkdownContent` into `HtmlContent` on every change. Property names are the same as `TMarkdownViewer` (MarkdownHelpViewer).
- Extensions: `TMarkdownExtension` flags in `TConfiguration.Extensions` (mdCommonMark `[]`, mdGFM `GFMExtensions`, mdGitHub `GitHubExtensions` = GFM + math + alerts + mermaid). `TConfiguration.MathRendering`: `mmrMarkup` (KaTeX/MathJax, for WebView2) or `mmrCodeCogsImage` (for HTMLViewer, no JavaScript).

**Legacy engine** (`mdDaringFireball`, `mdTxtMark`) — **do not change its output** (snapshot tests). `TMarkdownTxtMark` extends `TMarkdownDaringFireball`; dialect-conditional behavior via `config.isDialect([...])`. `MarkdownUtils.pas` holds the shared legacy engine (`TLine`/`TBlock`, `TEmitter`, `TDecorator`, `MarkdownDefaultCSS`) plus the types shared with the new engine: `TMarkdownProcessorDialect = (mdDaringFireball, mdCommonMark, mdTxtMark, mdGFM, mdGitHub)` — order is load-bearing, append only (the default is `DefaultMarkdownDialect`, not ordinal 0) — `TMarkdownExtension(s)`, `TConfiguration`, `TBlockEmitter`, `TSpanEmitter`. `MarkdownTables.pas` and `MarkdownMathCode.pas` belong to the legacy engine.

## CLI architecture (`Cmd/MarkdownToHTML/source/`)

Standard VSoft.CommandLineParser pattern, split across units:
- `MarkDownToHTML.dpr` — main flow: set up console → `BootstrapCli` → `TOptionsRegistry.Parse` → on success `TCommandBroker.ExecuteCommand`. Exit codes in `MDProcessorCLI.Options.pas` (`EXITCODE_OK`/`_PARSE_ERROR`/`_UNDEFINED_ERROR`).
- `MDProcessorCLI.Bootstrap.pas` — `BootstrapCli` registers all options, commands, and handlers. **This is where you wire up a new command or option.**
- `MDProcessorCLI.Options.pas` — option storage (class vars on `TOptionsForInput`/`TOptionsForOutput`/etc.) and the command bodies (`TOptionsForProcessFile.Execute` does the actual file→HTML work).
- `MDProcessorCLI.Commands.pas` — `TCommandBroker`, a name→`TProc` dictionary dispatched by command string.
- `MDProcessorCLI.Console.pas` — colored console logging (`TConsole.Log`, levels).
- `MDProcessorCLI.ResourceStrings.pas` — all user-facing strings.

Adding a command means: register it + its options in `BootstrapCli`, store option values in a `TOptionsFor*` class, implement an `Execute` body, and `TCommandBroker.RegisterCommand` a handler that calls it.

Note: the `processfolder` command (`TOptionsForProcessFolder.Execute`) is a registered-but-empty **TODO stub** — it parses args but does nothing yet.
