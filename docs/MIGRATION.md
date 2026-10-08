# Migrating to the new MarkdownProcessor engine

Instructions for migrating from 1.x to 2.x version.

---

## The default dialect

`TMarkdownProcessor.CreateDialect` has a parameter with a default value, `DefaultMarkdownDialect = mdGitHub`: `CreateDialect` without arguments creates
an `mdGitHub` processor. Existing calls that pass a dialect are unchanged.
`mdGitHub` is appended at the end of `TMarkdownProcessorDialect`: the ordinals of the existing dialects (0 DaringFireball, 1 CommonMark, 2 TxtMark, 3 GFM) do not change, so settings saved as integers keep working.

MarkDownToHTML.exe now uses `GitHub` when `-dialect:` is not given (it used `CommonMark`). Its pages have no scripts, so it writes math as codecogs images (as before) and mermaid diagrams as their source.

This page lists what changes for a program that used `mdCommonMark`, and how to get the previous features back.

## Breaking changes of `mdCommonMark`

1. **Tables, task lists and strikethrough** are not CommonMark: they need `mdGFM`, or the flags `mexTables`, `mexTaskLists`, `mexStrikethrough`.
2. **The non-standard syntax is off by default**: smart typography, `~sub~`, `^sup^`, `++ins++`, `==mark==`, `# Title {#id}`, `[[wiki links]]` and `$` math must be enabled through `Config.Extensions`.
3. **Math HTML** changed from an `<img src="https://latex.codecogs.com/...">`
   to KaTeX/MathJax markup: `<span class="math">\(...\)</span>` (inline) and
   `<div class="math">\[...\]</div>` (display). The page that shows the HTML
   needs KaTeX or MathJax.
4. **Safe mode** (`AllowUnsafe = False`, the default) omits raw HTML (it writes
   `<!-- raw HTML omitted -->`) instead of escaping it, and empties
   `javascript:`, `vbscript:`, `file:` and `data:` links.
5. **Output whitespace** follows the specification: tables use
   `<thead>`/`<tbody>` without indentation, `<br />`, `<hr />`, `<img ... />`,
   list items without blank lines in tight lists.
6. **Smart typography** (with `mexSmartTypography`) writes Unicode characters
   (`–`, `—`, `…`, `©`, `“`...) instead of HTML entities (`&ndash;`...).
7. `TMarkdownCommonMark` no longer derives from `TMarkdownDaringFireball`, and
   `TDecorator` is not used by the new engine: a custom decorator affects only
   the legacy dialects. To change the markup of the new engine, derive from
   `TMarkdownHtmlRenderer` (one virtual method per node kind).
8. `TMarkdownProcessorDialect` has two new values, `mdGFM` and `mdGitHub`,
   appended at the end: a `case` over the dialects may need new branches.

## Getting the previous behavior back

The features of the old `mdCommonMark`, on the new engine:

```Pascal
md := TMarkdownProcessor.CreateDialect(mdGitHub); // tables, task lists, ~~del~~, autolinks, math
md.Config.Extensions := md.Config.Extensions +
  [mexSubscript, mexSuperscript, mexInsert, mexMark,
   mexSmartTypography, mexHeadingAttributes, mexWikiLinks];
md.Config.MathRendering := mmrCodeCogsImage;    // math as <img>, as the old engine
```

With both `mexStrikethrough` and `mexSubscript`, `~~x~~` is strikethrough and
`~x~` subscript (GFM alone would strike `~x~` too).

## Notes for the consumers

- **MarkdownShellExtensions**: default dialect `mdGitHub`; add the flags of the
  toolbar (mark, sub/superscript, insert) and `mexAutoHeadingIds`; CSS for
  `thead`/`tbody`, `.markdown-alert-*`, `.math`. With **WebView2**: load KaTeX
  (or MathJax) and mermaid.js in the page template, keep the default
  `mmrMarkup`. With the **HTMLViewer** fallback: `Config.MathRendering :=
  mmrCodeCogsImage`; mermaid diagrams show their source (or remove
  `mexMermaid`). `Config.codeBlockEmitter` still receives every code block
  (mermaid included) when assigned.
- **MarkDownHelpViewer**: same choices; heading ids for the table of contents
  come from `mexHeadingAttributes` / `mexAutoHeadingIds`.
- **MarkDownToHTML.exe**: default dialect `GitHub`; `-dialect:GFM` and
  `-dialect:CommonMark` are available.

See `docs/COMMONMARK_PLAN.md` for the design and `Tests/CONFORMANCE.md` for the
conformance results.
