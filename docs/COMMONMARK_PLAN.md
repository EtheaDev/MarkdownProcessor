# CommonMark / GFM Conformance Plan

Status: **phases 0-9 done** (all corpora green; §10 decisions implemented) — 2026-10-04
Author: Carlo Barazzetta (Ethea S.r.l.), analysis drafted with Claude Code

## 1. Goal

Make `MarkdownProcessor` produce **standard-conformant HTML**:

- `mdCommonMark` → CommonMark **0.31.2**, all 652 official examples, byte-for-byte.
- new `mdGFM` → GitHub Flavored Markdown **0.29-gfm** extensions, all 24 official examples.
- `$` math, GitHub alerts, and a code-block hook for mermaid / chart, each with its own test corpus.

Visual rendering (HTMLViewer, CSS, PDF export in MarkdownShellExtensions) is **out of scope**:
first the HTML must be correct, then the consumers will be adapted.

`mdDaringFireball` and `mdTxtMark` are kept **unchanged** for backward compatibility.

## 2. Baseline

Measured with a throw-away console program that runs the official corpora through
`TMarkdownProcessor.Process` (`AllowUnsafe := True`).
"Lenient" ignores all whitespace; "strict" compares the exact HTML.

### CommonMark 0.31.2 (652 examples)

| Engine | Lenient | Strict |
|---|---:|---:|
| `mdDaringFireball` | 330 (51%) | 254 |
| `mdCommonMark` | 325 (50%) | 250 |
| Markdown4D (reference) | 652 | 652 |

Weakest sections for `mdCommonMark` (lenient): fenced code blocks 2/29, link reference
definitions 8/27, entities 5/17, HTML blocks 12/44, setext headings 12/27, backslash
escapes 5/13, lists 12/26, list items 24/48, emphasis 71/132, links 45/90.

### GFM 0.29 extensions (24 examples)

| Section | N | `mdCommonMark` |
|---|---:|---:|
| Tables | 8 | 0 (tables are rendered, but without `<thead>`/`<tbody>` and with indentation) |
| Task list items | 2 | 0 |
| Strikethrough | 2 | 2 |
| Autolinks | 11 | 0 |
| Disallowed raw HTML | 1 | 0 |

Root causes, from reading the code:

- The engine classifies **one line at a time** (`TLine.getLineType`) and has no real model
  of nested containers. CommonMark needs the two-phase algorithm: block structure first
  (with open/closed containers and lazy continuation), then inlines (delimiter stack).
- `mdCommonMark` turns on **non-standard extensions** that change standard output:
  smart typography (`--`, `---`, `...`, `(C)`, curly quotes, `<<`/`>>`), `~sub~`, `^sup^`,
  `++ins++`, `==mark==`, `{#id}` headings, `[[...]]` links, `$` math as `<img>` from
  latex.codecogs.com.
- `TCommonMark` **inherits** from `TMarkdownDaringFireball`, so you cannot fix one without
  touching the other.

## 3. Decisions

| # | Topic | Decision |
|---|---|---|
| D1 | Architecture | **New engine** in new units for `mdCommonMark`/`mdGFM`. The current engine stays for `mdDaringFireball`/`mdTxtMark` and is not modified. |
| D2 | Dialects | `mdCommonMark` = pure CommonMark. New **`mdGFM`** appended to the enum (order is load-bearing). |
| D3 | Delphi | Library stays compatible with **Delphi XE3**. Only the test project requires Delphi 13. |
| D4 | Scope | CommonMark + GFM (5 extensions) + Math + GitHub Alerts + mermaid/chart hook. |
| D5 | Legacy extensions | Each becomes an **individual flag**, **off by default** in `mdCommonMark` and `mdGFM`. |
| D6 | Math HTML | **math.json format**: `<span class="math">\(...\)</span>` / `<div class="math">\[...\]</div>` (KaTeX/MathJax-ready). |
| D7 | Mermaid / chart | **Standard output** (`<pre><code class="language-mermaid">`) + the existing `codeBlockEmitter` hook. Diagram-syntax parsing is deferred. |
| D8 | Safe mode | **Like Markdown4D**: safe = raw HTML omitted + dangerous URLs emptied; unsafe = exact spec output. |
| D9 | API | `Process(string): string` unchanged + new **read-only AST** via `Parse`. Separate renderer. |
| D10 | Heading ids | Two flags: **`HeadingAttributes`** (`{#id}`) and **`AutoHeadingIds`** (GitHub slugs). Both off by default. |
| D11 | Tests | **DUnitX**, Delphi 13, **Win32 + Win64**, `RunTests.cmd` with a conformance dashboard. |
| D12 | Document | This file, English, `docs/COMMONMARK_PLAN.md`. |

## 4. Public API

### 4.1 Dialects

```pascal
TMarkdownProcessorDialect = (mdDaringFireball, mdCommonMark, mdTxtMark, mdGFM); // append only
```

`TMarkdownProcessor.CreateDialect(mdGFM)` returns the new GFM processor.
`TMarkdownCommonMark` stops inheriting from `TMarkdownDaringFireball` and derives directly
from `TMarkdownProcessor`.

### 4.2 Extensions

```pascal
TMarkdownExtension = (
  // GFM
  mexTables, mexTaskLists, mexStrikethrough, mexAutolinks, mexTagFilter,
  // Other standards in common use
  mexMath, mexAlerts,
  // Legacy (Ethea) extensions — non-standard
  mexSubscript,        // ~x~
  mexSuperscript,      // ^x^
  mexInsert,           // ++x++
  mexMark,             // ==x==
  mexSmartTypography,  // -- --- ... (C) (R) (TM) "quotes" << >>
  mexHeadingAttributes,// # Title {#id}
  mexAutoHeadingIds,   // GitHub-style slug ids
  mexWikiLinks         // [[...]]
);
TMarkdownExtensions = set of TMarkdownExtension;
```

New property: `TConfiguration.Extensions: TMarkdownExtensions`.

| Dialect | Default `Extensions` |
|---|---|
| `mdCommonMark` | `[]` |
| `mdGFM` | `[mexTables, mexTaskLists, mexStrikethrough, mexAutolinks, mexTagFilter]` |

The client can change the set after `CreateDialect`. For example, MDTextEditor will add
`mexMath, mexAlerts, mexMark, mexSubscript, mexSuperscript, mexInsert` (its toolbar
buttons) and `mexAutoHeadingIds`.

**Known conflict**: GFM strikethrough accepts both `~x~` and `~~x~~`, while `mexSubscript`
uses `~x~`. When both are on: `~~x~~` → `<del>`, `~x~` → `<sub>` (a documented deviation
from GFM example 491, tested separately).

### 4.3 Safe mode (`AllowUnsafe`)

| | `AllowUnsafe = False` (default) | `AllowUnsafe = True` |
|---|---|---|
| Raw HTML blocks and inline raw HTML | **omitted** | emitted as is |
| `javascript:`, `vbscript:`, `file:`, `data:` URLs | `href`/`src` **emptied** (except `data:image/png\|gif\|jpeg\|webp`) | emitted as is |
| `mexTagFilter` (GFM) | — (HTML already omitted) | `<title> <textarea> <style> <xmp> <iframe> <noembed> <noframes> <script> <plaintext>` neutralized as `&lt;` |

The spec corpora run with `AllowUnsafe = True`. A dedicated suite covers safe mode.

### 4.4 AST

A read-only node tree, interface-based (reference-counted, XE3-compatible):

```pascal
md := TMarkdownProcessor.CreateDialect(mdGFM);
doc := md.Parse(source);          // IMarkdownNode (Document)
html := md.Render(doc);           // same output as md.Process(source)
```

Node kinds: Document, BlockQuote, List, ListItem, Paragraph, Heading, ThematicBreak,
CodeBlock (indented/fenced + info string), HtmlBlock, Table/TableRow/TableCell, Alert,
MathBlock; inline: Text, SoftBreak, HardBreak, Code, Emphasis, Strong, Strikethrough,
Link, Image, Autolink, HtmlInline, MathInline, TaskMarker, plus the legacy
Sub/Sup/Ins/Mark nodes.
Each node exposes kind, children, parent, its specific properties and the source line
range (`StartLine`/`EndLine`), which is useful for editor ↔ preview sync.

### 4.5 Hooks (backward compatible)

- `TConfiguration.codeBlockEmitter: TBlockEmitter` keeps its signature
  `emitBlock(out_, lines: TStringList, meta: String)`. In the new engine `meta` is the
  **whole info string**. When the emitter is assigned it receives **all** fenced and
  indented code blocks, including `mermaid` and `chart`. The emitter decides what to do
  (highlighting, `<pre class="mermaid">`, SVG, ...).
- Without an emitter the output is standard:
  `<pre><code class="language-xxx">` for the first word of the info string.
- `TDecorator` is **not** used by the new engine; the renderer is a separate class
  (`TMarkdownHtmlRenderer`) with virtual methods per node kind.
- `specialLinkEmitter` (`[[...]]`) is used only when `mexWikiLinks` is on.

## 5. Engine architecture

New units in `source/`, plain Object Pascal, XE3-compatible: no inline `var`, no
`System.JSON`, no `TCharHelper`-only APIs; character classification goes through
`System.Character` functions or our own tables.

| Unit | Content |
|---|---|
| `MarkdownAST.pas` | Node interfaces and implementation, visitor |
| `MarkdownBlockParser.pas` | Phase 1: line-by-line container/leaf block parser (spec appendix "A parsing strategy") |
| `MarkdownInlineParser.pas` | Phase 2: inlines, delimiter stack and `process emphasis` algorithm, link/image brackets |
| `MarkdownLinkRefs.pas` | Link reference definitions, label normalization (Unicode case fold) |
| `MarkdownEntities.pas` | Full HTML5 named entity table (2231 entries), generated (see §8) |
| `MarkdownHtmlRenderer.pas` | AST → HTML, safe mode, URL encoding/escaping as in the spec reference implementation |
| `MarkdownGFM.pas` | Tables, task lists, strikethrough, extended autolinks, tag filter |
| `MarkdownMath.pas` | `$`/`$$` inline, `$$` blocks, ```` ```math ```` fence (replaces `MarkdownMathCode.pas` in the new engine) |
| `MarkdownAlerts.pas` | `> [!NOTE]` … `[!CAUTION]` → GitHub markup (`<div class="markdown-alert markdown-alert-note">` + `<p class="markdown-alert-title">Note</p>`) |
| `MarkdownLegacyExt.pas` | sub/sup/ins/mark/smart typography/heading attributes/auto ids/wiki links, on the new engine |

`MarkdownCommonMark.pas` becomes a thin wrapper: build pipeline → parse → render.
`MarkdownUtils.pas`, `MarkdownDaringFireball.pas`, `MarkdownTxtMark.pas`,
`MarkdownTables.pas` and `MarkdownMathCode.pas` stay as they are for the old dialects.
The only additions are the enum value, `Extensions` and the `TConfiguration` defaults.

**Performance**: the spec requires linear time on pathological input (deep nesting,
thousands of `[` or `*`). The algorithm must avoid quadratic backtracking (bracket
"bottom" pointers, `openers_bottom` per delimiter kind and length mod 3).

## 6. Test project

```
Tests/
  MarkdownProcessor.Tests.dpr / .dproj   DUnitX console, Delphi 13, Win32 + Win64
  RunTests.cmd                           build both platforms, run, XML + dashboard
  CONFORMANCE.md                         generated dashboard (per-section pass rate)
  specs/
    README.md                            origin and license of each corpus
    commonmark-0.31.2.json               CC-BY-SA 4.0 (CommonMark spec)
    gfm-0.29.json                        CC-BY-SA 4.0 (GFM spec)
    math.json                            MIT (Markdown4D, GDK Software)
    alerts.json                          ours
    extensions.json                      ours (legacy flags)
    safety.json                          ours (safe mode)
  LICENSE-Markdown4D.txt                 MIT notice for material copied from Markdown4D
  MarkdownProcessor.Tests.Corpus.pas      JSON corpus loader (System.JSON allowed here)
  MarkdownProcessor.Tests.CommonMark.pas  one TestCase per spec section (26)
  MarkdownProcessor.Tests.GFM.pas         one TestCase per GFM section (5)
  MarkdownProcessor.Tests.Math.pas
  MarkdownProcessor.Tests.Alerts.pas
  MarkdownProcessor.Tests.Extensions.pas  legacy flags + sub/strikethrough conflict
  MarkdownProcessor.Tests.Safety.pas
  MarkdownProcessor.Tests.Hooks.pas       codeBlockEmitter, specialLinkEmitter
  MarkdownProcessor.Tests.AST.pas         node tree, source line ranges
  MarkdownProcessor.Tests.Legacy.pas      DaringFireball/TxtMark snapshots: must not change
  MarkdownProcessor.Tests.Performance.pas pathological inputs under a time budget
```

Rules:

- **Comparison is strict**: the only normalization is CRLF → LF. No whitespace folding.
- A failing test reports the example number, the markdown, the expected and the actual HTML.
- Before any engine change, `Tests.Legacy` records snapshots of the current output of
  `mdDaringFireball` and `mdTxtMark` on `TestFile/` and on the whole CommonMark corpus.
  This guarantees D1 (old dialects untouched).
- `RunTests.cmd` exits non-zero on failure and regenerates `CONFORMANCE.md`
  (same format as the Markdown4D dashboard).

### Licenses of reused material

- CommonMark and GFM corpora: **CC-BY-SA 4.0**. Attribute them in `specs/README.md`.
  If modified, they stay CC-BY-SA; the code that reads them is not affected.
- `math.json` and any code adapted from Markdown4D: **MIT**. Keep the copyright notice and
  add `LICENSE-Markdown4D.txt`. MIT material may be included in this Apache-2.0 project.
- Markdown4D test *code* is not copied as is: it targets its own API. It is only used as
  a model for the runner and the corpus loader.

## 7. Phases and acceptance criteria

| Phase | Work | Done when |
|---|---|---|
| **0** | Test project, corpora, loader, dashboard, legacy snapshots. Run against the **current** engine. | `RunTests.cmd` green on build; dashboard shows the baseline of §2 |
| **1** | AST + block parser: tabs, thematic breaks, ATX/setext headings, indented/fenced code, 7 HTML block kinds, link ref definitions, paragraphs, blank lines, block quotes, list items, lists (tight/loose) | All block-level sections ≥ 95% |
| **2** | Inline parser: backslash escapes, entities, code spans, emphasis (delimiter algorithm), links, images, autolinks, raw HTML, hard/soft breaks | Inline sections ≥ 95% |
| **3** | HTML renderer, safe mode, wire `mdCommonMark` to the new engine | **652/652**, safety suite green, legacy snapshots unchanged |
| **4** | `mdGFM`, the 5 GFM extensions, CLI `-dialect:GFM` | **24/24** GFM + 652/652 CommonMark still green |
| **5** | Math | **35/35** math.json |
| **6** | Alerts | own corpus green |
| **7** | Legacy extensions as flags (incl. heading ids) | extensions suite green; `TestFile/MarkDown Support Test.md` renders all features with flags on |
| **8** | Hooks + AST API finalized, performance suite, README/CLAUDE.md update, migration notes | performance budget met; docs updated |

**Phase 0 result** (2026-10-04, strict, identical on Win32 and Win64, see `Tests/CONFORMANCE.md`):
CommonMark 258/652 (§2 says 250: that figure came from the throw-away program, whose
comparison was not identical), GFM 2/24, Math 6/35. Legacy snapshots: 4 files in
`Tests/snapshots`, green on both platforms. The legacy engine obfuscates e-mail
autolinks with `random(2)`, so the snapshot suite fixes `RandSeed` before each render.

**Phase 1 result** (2026-10-04): new units `MarkdownAST`, `MarkdownBlockParser`,
`MarkdownLinkRefs`, `MarkdownTextUtils`, `MarkdownEntities` (generated by
`tools/GenerateEntities.py`), `MarkdownHtmlRenderer`; `mdCommonMark` already runs on the
new engine (inline content still plain text). CommonMark 342/652: Tabs, Indented code,
Block quotes, List items, Lists at 100%; every remaining failure of the block-level
sections depends on inline parsing (emphasis, links, escapes, raw HTML, hard breaks)
and is the target of phase 2.

**Phase 2 result** (2026-10-04): `MarkdownInlineParser` (delimiter stack with
`openers_bottom`, bracket stack, backtick-run cache). **CommonMark 652/652** on Win32 and
Win64, legacy snapshots unchanged. Pitfall found: in Delphi a two-digit literal such as
`#$80` is an AnsiChar converted through the system code page (0x80 = U+20AC in
Windows-1252), so comparisons use `Ord(C) < $80`.

**Phase 3 result** (2026-10-04): `MarkdownHtmlRenderer` complete for CommonMark, safe mode
as Markdown4D (`<!-- raw HTML omitted -->`, dangerous destinations emptied), `mdCommonMark`
wired to the new engine (done early, in phase 1). New corpus `Tests/specs/safety.json`
(25 examples) and `Tests.Safety`: green. CommonMark 652/652, legacy snapshots unchanged.

**Phase 4 result** (2026-10-04): `mdGFM` (`TMarkdownGFM`), `TMarkdownExtension`/`Extensions`
in `TConfiguration`, `MarkdownGFM.pas` (tables, task list items, strikethrough, extended
autolinks, tag filter, following cmark-gfm: www/URL autolinks while parsing inlines,
e-mail autolinks as a post-process of text nodes, the header row is the last line of the
paragraph). **GFM 24/24**, CommonMark 652/652. CLI: `-dialect:GFM`.

**Phase 5 result** (2026-10-04): `MarkdownMath.pas` (`mexMath`): inline `$...$` / `$$...$$` with
the opener/closer rules of Markdown4D, the GitLab form ``$`...`$``, display blocks between
`$$` lines (a fence with `$` as character), ```` ```math ```` fences. **Math 35/35** (corpus run on
`mdGFM` + `mexMath`); `RunTests.cmd` fully green (736/736) on Win32 and Win64.

**Phase 6 result** (2026-10-04): `MarkdownAlerts.pas` (`mexAlerts`): top-level block quotes whose
first line is `[!NOTE]`, `[!TIP]`, `[!IMPORTANT]`, `[!WARNING]` or `[!CAUTION]` (any case)
become `nkAlert`, rendered with the GitHub markup. New corpus `Tests/specs/alerts.json`
(20 examples, rules of GitHub and of the Markdown4D tests): **20/20**; all corpora 756/756.

**Phase 7 result** (2026-10-04): `MarkdownLegacyExt.pas` + inline parser: `~x~` sub, `^x^` sup,
`++x++` ins, `==x==` mark as exact-length delimiters of the delimiter stack (with
`mexSubscript` and strikethrough both on, `~x~` is sub and `~~x~~` del); smart typography as a
post-process of text nodes (Unicode characters instead of the old HTML entities; code spans and
autolinks untouched); `{#id}` and GitHub slugs (`IMarkdownNode.Id`, unique with `-1`, `-2`);
`[[...]]` as `nkWikiLink`, rendered through `specialLinkEmitter` (brackets as text without it).
New corpus `Tests/specs/extensions.json` (35 examples, flags per section): **35/35**;
`TestFile/MarkDown Support Test.md` renders all its features on `mdGFM` + math/sub/sup/ins/mark.

**Phase 8 result** (2026-10-04): hooks — `codeBlockEmitter` receives every code block (lines
without line endings, whole info string as meta), `specialLinkEmitter` the rendered content of
`[[...]]`; `TMarkdownProcessor.Parse`/`Render` virtual (legacy dialects raise
`ENotSupportedException`); new fixtures `Tests.Hooks`, `Tests.AST`, `Tests.Performance`
(32 pathological inputs, 3 s budget each on a Debug build; slowest now ~0.25 s, the 1 MB paragraph). Quadratic
paths found and fixed: link reference definitions copied the rest of the paragraph,
unclosed link destinations (parentheses nesting limited to 32, as the spec allows),
`a@b@c` e-mail candidates, closer searches of inline HTML/`[[`/`$`, the first-closer
search of "process emphasis" walking the whole delimiter stack on every link (also present
in commonmark.js), `FindNextNonspace` rescanning the indentation for every container.
No memory leaks (allocated memory stable over repeated runs of all corpora). README, CLAUDE.md
and `docs/MIGRATION.md` updated. The library was compiled only with Delphi 13: Delphi XE3
compatibility follows the coding rules (no inline variables, guarded `TCharHelper` use) but has
not been verified with an XE3 compiler.

Phases 1 and 2 overlap with 3 in practice: the renderer is needed to run the corpora,
so a minimal renderer is written in phase 1 and completed in phase 3.

## 8. Implementation notes

- **Entities**: generate `MarkdownEntities.pas` from WHATWG `entities.json` with a script
  kept in `tools/`. Use a sorted array + binary search (XE3-safe, no large `case`).
- **Unicode case fold** for link labels (spec example with `ẞ`/`SS`): `AnsiUpperCase` is
  not enough. Implement simple + special full case folding for the characters the spec
  exercises, table-driven.
- **Tabs**: virtual columns with tab stop 4 (partial tab consumption in containers).
- **Line endings**: input CR, LF and CRLF accepted; output always LF.
- **NUL** (U+0000) replaced by U+FFFD.
- **Info string**: entities and backslash escapes are processed;
  `class="language-` + first word.
- **URL output**: percent-encode as the reference implementation does (keep `%xx`
  already present, encode the rest of the non-safe characters), HTML-escape
  `& < > "`.
- **Tables** (GFM): `<thead>`/`<tbody>`, `align="left|center|right"`; no `<tbody>` when
  there are no body rows; `\|` inside code spans is unescaped by the table step.
- **Autolinks** (GFM): `www.`, `http(s)://`, email, trailing punctuation and `)` balancing
  rules from the spec.

## 9. Breaking changes (to put in README / release notes)

1. `mdCommonMark` **no longer renders tables, task lists or strikethrough**: they need
   `mdGFM` (or the matching `mex*` flags).
2. Smart typography, sub/sup/ins/mark, `{#id}`, `[[links]]` and math are **off by
   default** and must be enabled through `Extensions`.
3. Math HTML changes from `<img src="https://latex.codecogs.com/...">` to KaTeX/MathJax
   markup.
4. Safe mode omits raw HTML instead of escaping it.
5. Output whitespace follows the spec (e.g. no indentation inside tables).

Consumers to update afterwards (out of scope here): **MarkdownShellExtensions** (default
dialect → `mdGFM`, extension flags, CSS for `thead`/`tbody`/alerts, math rendering in
HTMLViewer, mermaid via `codeBlockEmitter`), MarkDownHelpViewer, `MarkDownToHTML.exe`.

## 10. Decisions on the open points

Context: the viewer of MarkdownShellExtensions will use **WebView2** when it is installed
(mermaid.js and KaTeX/MathJax run there) and fall back to **HTMLViewer** otherwise (no
JavaScript). The processor provides both kinds of output; the viewer chooses.

| # | Topic | Decision |
|---|---|---|
| D13 | `mdGFM` defaults | Unchanged: `mdGFM` = GFM 0.29 exactly (`GFMExtensions`). |
| D14 | New dialect | **`mdGitHub`**, appended to the enum: the behavior of github.com = `GFMExtensions + [mexMath, mexAlerts, mexMermaid]`. |
| D15 | Mermaid | New flag **`mexMermaid`**: a ```` ```mermaid ```` fence is written as `<pre class="mermaid">` + escaped source + `</pre>` (the markup mermaid.js scans). On only in `mdGitHub`; `mdCommonMark`/`mdGFM` keep the spec output `<pre><code class="language-mermaid">`. `codeBlockEmitter`, when assigned, still takes precedence. The `<script>` of mermaid.js is added by the viewer, not by the processor. No parsing of the diagram syntax (the full mermaid set needs mermaid.js). |
| D16 | Math fallback | `TConfiguration.MathRendering := mmrCodeCogsImage` writes math as `<img class="math" src="https://latex.codecogs.com/png.image?..." alt="..." />` (PNG, as `MarkdownMathCode.pas`, because HTMLViewer handles PNG better than SVG; display blocks centered in `<div class="math" style="text-align:center;">`) for HTMLViewer; the default `mmrMarkup` stays the KaTeX/MathJax markup for WebView2. |

| D17 | Default dialect | **`mdGitHub` is the default**, but it is appended at the end of the enum (ordinals unchanged: settings saved as integers keep working). The default is explicit: `const DefaultMarkdownDialect = mdGitHub`, `CreateDialect(Dialect = DefaultMarkdownDialect)`, default of the CLI `-dialect:`. |

These become **phase 9**: `mdGitHub` (default), `mexMermaid`, math `<img>` option,
corpora/tests (mermaid and math-image examples), CLI `-dialect:GitHub` as default,
README/MIGRATION update.

**Phase 9 result**: implemented as decided. `extensions.json` grows to 48
examples (sections Mermaid, Mermaid off, Math images, GitHub dialect) and a test pins the
default dialect and the unchanged ordinals. The CLI writes standalone pages without
scripts, so with the new default it sets `mmrCodeCogsImage` (math as images, as the
previous versions did); mermaid diagrams show their source there. All corpora 804/804.
