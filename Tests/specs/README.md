# Test corpora

Where the JSON files in this folder come from, and under which terms they are
included. Every corpus is a JSON array of entries with `markdown`, `html`,
`example` and `section` (the specification corpora also carry `start_line` and
`end_line`).

## commonmark-0.31.2.json

The 652 examples of the CommonMark specification, version 0.31.2, in the
`spec.json` form generated from `spec.txt`.

- Upstream: <https://spec.commonmark.org/0.31.2/spec.json>
- Specification: <https://spec.commonmark.org/0.31.2/>
- Copyright: John MacFarlane and the CommonMark contributors
- Licence: Creative Commons CC-BY-SA 4.0, the licence of the CommonMark
  specification. See <https://creativecommons.org/licenses/by-sa/4.0/>.

## gfm-0.29.json

The 24 extension examples of the GitHub Flavored Markdown specification,
version 0.29-gfm: tables, task list items, strikethrough, extended autolinks
and the tag filter, with the example numbers of the GFM specification.

- Specification: <https://github.github.com/gfm/>
- Copyright: GitHub, Inc. and the CommonMark contributors
- Licence: Creative Commons CC-BY-SA 4.0, as a derivative of the CommonMark
  specification.

## math.json

The 35 math examples (inline `$`/`$$`, display blocks, ```` ```math ```` fence)
written for the Markdown4D project and copied unchanged. They pin the
KaTeX/MathJax-ready HTML: `<span class="math">\(...\)</span>` and
`<div class="math">\[...\]</div>`.

- Origin: Markdown4D, `Tests/specs/math.json`
- Copyright: (c) 2026 GDK Software
- Licence: MIT, see `../LICENSE-Markdown4D.txt`.

## safety.json

Written for this project (Apache 2.0, like the rest of MarkdownProcessor).
Safe mode (`AllowUnsafe = False`) of `mdCommonMark`: raw HTML omitted,
dangerous destinations emptied, allowed ones kept.

## alerts.json

Written for this project (Apache 2.0). GitHub alerts (`> [!NOTE]` ...) on
`mdGFM` with `mexAlerts`, with the GitHub markup
(`<div class="markdown-alert markdown-alert-note">`). The rules follow GitHub
and the Markdown4D alert tests: only top-level block quotes, the marker is the
whole first line, any case.

## extensions.json

Written for this project (Apache 2.0). The legacy (non-standard) extensions
of the old `mdCommonMark` as flags of the new engine: sub/superscript,
insert, mark, smart typography, heading ids, wiki links. Each section runs
with its own dialect and flags (`MarkdownProcessor.Tests.Extensions.pas`).

## Updating a corpus

Replace the file, keep the version in the file name, update the entry above,
and check the example count asserted by the `*_Corpus_ContainsAllExamples`
tests.
