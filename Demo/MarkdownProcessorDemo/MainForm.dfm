object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Markdown Processor Demo'
  ClientHeight = 640
  ClientWidth = 1100
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  TextHeight = 15
  object Splitter: TSplitter
    Left = 540
    Top = 0
    Width = 6
    Height = 596
    MinSize = 150
    ResizeStyle = rsUpdate
  end
  object SourcePanel: TPanel
    Left = 0
    Top = 0
    Width = 540
    Height = 596
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 0
    object SourceToolPanel: TPanel
      Left = 0
      Top = 0
      Width = 540
      Height = 41
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      DesignSize = (
        540
        41)
      object SourceLabel: TLabel
        Left = 8
        Top = 12
        Width = 100
        Height = 15
        Caption = 'Markdown source'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object LoadFileButton: TButton
        Left = 392
        Top = 8
        Width = 140
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'Load from file...'
        TabOrder = 0
        OnClick = LoadFileButtonClick
      end
    end
    object MarkdownSourceMemo: TMemo
      Left = 0
      Top = 41
      Width = 540
      Height = 555
      Align = alClient
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Consolas'
      Font.Style = []
      Lines.Strings = (
        'Markdown support test'
        '====================='
        ''
        '![Markdown logo](markdownlogo.png)'
        ''
        'This page demonstrates the Markdown syntax supported by the **GitHub** dialect of the Markdown Processor (the default dialect): CommonMark 0.31.2, the GitHub Flavored Markdown extensions, GitHub alerts, math formulas and mermaid diagrams, plus the extensions of the Markdown Processor enabled by default in the TMarkdownToHTML component.'
        ''
        'The file is encoded in UTF-8 format with BOM (this is a UTF-8 symbol: '#8364')'
        ''
        '## Headings'
        ''
        '# heading 1'
        '## heading 2'
        '### heading 3'
        '#### heading 4'
        '##### heading 5'
        '###### heading 6'
        ''
        'Setext heading 1'
        '================'
        ''
        'Setext heading 2'
        '----------------'
        ''
        '## Paragraphs and line breaks'
        ''
        'A paragraph is made of one or more lines of text.'
        'A single line break is a soft break,'
        'two spaces at the end of a line  '
        'make a hard break, and so does a backslash\'
        'at the end of a line.'
        ''
        '## Emphasis'
        ''
        '*Italic* or _Italic_, **Bold** or __Bold__, ***Bold italic***, ~~Strikethrough~~ and `inline code`.'
        ''
        'Intraword emphasis: un*frigging*believable, while snake_case_words stay as they are.'
        ''
        '## Backslash escapes and entities'
        ''
        '\*not italic\*, \# not a heading, \[not a link\]'
        ''
        'Entities: &copy; &amp; &lt;tag&gt; &#8364; &#x1F600;'
        ''
        '## Links'
        ''
        '- Inline link: [Ethea](https://www.ethea.it "Ethea home page")'
        '- Reference links: from [CommonMark] and from the [GFM specification][gfm]'
        '- Autolinks: <https://www.markdownguide.org> and <info@ethea.it>'
        '- Extended autolinks: www.github.com, https://github.com/EtheaDev/MarkdownProcessor and info@ethea.it'
        ''
        '[CommonMark]: https://spec.commonmark.org/0.31.2/'
        '[gfm]: https://github.github.com/gfm/ "GitHub Flavored Markdown"'
        ''
        '## Images'
        ''
        '![Markdown logo](markdownlogo.png "Markdown")'
        ''
        '## Block quotes'
        ''
        '> Markdown is a plain text format for writing structured documents,'
        '> based on conventions for indicating formatting in email and Usenet posts.'
        '>'
        '> > A nested block quote.'
        ''
        '## Lists'
        ''
        '* Unordered List one'
        '* Unordered List two'
        '  * Nested item'
        '  * Another nested item'
        '* Unordered List three'
        ''
        '1. Ordered List one'
        '2. Ordered List two'
        '   1. Nested ordered item'
        '3. Ordered List three'
        ''
        '### Task list'
        ''
        '- [x] Write the new engine'
        '- [x] Pass all the CommonMark and GFM examples'
        '- [ ] Release the new version'
        ''
        '## Code'
        ''
        'Indented code block:'
        ''
        '    procedure HelloWorld;'
        '    begin'
        '      ShowMessage(''Hello World'');'
        '    end;'
        ''
        'Fenced code block with the language:'
        ''
        '```Delphi'
        'procedure HelloWorld;'
        'begin'
        '  ShowMessage(''Hello World'');'
        'end;'
        '```'
        ''
        '## Horizontal rule'
        ''
        '---'
        ''
        '## Tables'
        ''
        '| First Header | Second Header | Third Header |'
        '| :----------- | :-----------: | -----------: |'
        '| Left         | Center        | Right        |'
        '| Second row   | **strong**    | *italic*     |'
        ''
        '### Table with inline formatting'
        ''
        'Each cell is an independent inline scope: inline markers (`*`, `**`, `` ` ``, `~~`, ...) must NOT span across cells/rows.'
        ''
        '| Header **A** | Header *B* | Col `C` |'
        '| :----------- | :--------: | ------: |'
        '| **strong**          | *italic*                     | `code()`     |'
        '| ~~strike~~          | [link](https://www.ethea.it) | www.ethea.it |'
        '| pipe \| escaped     | normal                       | end          |'
        ''
        '## Alerts'
        ''
        '> [!NOTE]'
        '> Useful information that users should know, even when skimming content.'
        ''
        '> [!TIP]'
        '> Helpful advice for doing things better or more easily.'
        ''
        '> [!IMPORTANT]'
        '> Key information users need to know to achieve their goal.'
        ''
        '> [!WARNING]'
        '> Urgent info that needs immediate user attention to avoid problems.'
        ''
        '> [!CAUTION]'
        '> Advises about risks or negative outcomes of certain actions.'
        ''
        '## Math formulas'
        ''
        'Inline formula written between single dollar signs: $E = mc^2$ rendered inside the text, while prices like $10 and $20 stay text.'
        ''
        'Display formula in a `$$` block:'
        ''
        '$$'
        '\frac{-b \pm \sqrt{b^2 - 4ac}}{2a}'
        '$$'
        ''
        'Display formula in a `math` code block:'
        ''
        '```math'
        '\sum_{i=1}^{n} i = \frac{n(n+1)}{2}'
        '```'
        ''
        '## Mermaid diagrams'
        ''
        '```mermaid'
        'graph LR'
        '  A[Markdown] --> B(Markdown Processor)'
        '  B --> C[HTML]'
        '```'
        ''
        '### Charts'
        ''
        'Charts are mermaid diagrams too: a pie chart and a bar and line chart.'
        ''
        '```mermaid'
        'pie title Markdown dialects'
        '  "GitHub" : 45'
        '  "GFM" : 25'
        '  "CommonMark" : 20'
        '  "Legacy" : 10'
        '```'
        ''
        '```mermaid'
        'xychart-beta'
        '  title "Monthly downloads"'
        '  x-axis [Jan, Feb, Mar, Apr, May, Jun]'
        '  y-axis "Downloads" 0 --> 1000'
        '  bar [250, 400, 520, 610, 780, 900]'
        '  line [250, 400, 520, 610, 780, 900]'
        '```'
        ''
        '## Extensions of the Markdown Processor'
        ''
        'Enabled by default in the TMarkdownToHTML component (or one by one with `Config.Extensions`):'
        ''
        '- Subscript: H~2~O and superscript: x^2^'
        '- Inserted text: ++inserted++ and highlighted text: ==marked=='
        '- Smart typography: -- en dash, --- em dash, ellipsis..., (C) (R) (TM), "double quotes", << guillemets >>'
        '- Wiki link: [[Main Page]] (the link is written by the application through `SpecialLinkEmitter`, without it the text is kept)'
        ''
        '### Heading with a custom id {#custom-id}'
        ''
        'Automatic heading ids: every other heading gets a GitHub-style id, like `math-formulas` for "Math formulas".'
        ''
        '## Raw HTML'
        ''
        'Inline HTML: <kbd>Ctrl</kbd>+<kbd>C</kbd> (omitted in safe mode, the default).')
      ParentFont = False
      ScrollBars = ssBoth
      TabOrder = 1
      WordWrap = False
    end
  end
  object DestPanel: TPanel
    Left = 546
    Top = 0
    Width = 554
    Height = 596
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object DestToolPanel: TPanel
      Left = 0
      Top = 0
      Width = 554
      Height = 41
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      DesignSize = (
        554
        41)
      object DestLabel: TLabel
        Left = 8
        Top = 12
        Width = 68
        Height = 15
        Caption = 'HTML result'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object ProcessButton: TButton
        Left = 260
        Top = 8
        Width = 140
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'Process...'
        TabOrder = 0
        OnClick = ProcessButtonClick
      end
      object OpenInBrowserButton: TButton
        Left = 406
        Top = 8
        Width = 140
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'Open in Browser...'
        TabOrder = 1
        OnClick = OpenInBrowserButtonClick
      end
    end
    object OptionsPanel: TPanel
      Left = 0
      Top = 41
      Width = 554
      Height = 96
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 1
      object DialectLabel: TLabel
        Left = 8
        Top = 12
        Width = 39
        Height = 15
        Caption = 'Dialect:'
      end
      object LegacyLabel: TLabel
        Left = 240
        Top = 12
        Width = 196
        Height = 15
        Caption = 'Legacy extensions (new engine only):'
      end
      object DialectComboBox: TComboBox
        Left = 60
        Top = 8
        Width = 160
        Height = 23
        Style = csDropDownList
        TabOrder = 0
        OnChange = DialectComboBoxChange
      end
      object SubscriptCheckBox: TCheckBox
        Tag = 7
        Left = 8
        Top = 44
        Width = 130
        Height = 17
        Caption = 'Subscript ~x~'
        TabOrder = 1
        OnClick = LegacyExtensionCheckBoxClick
      end
      object SuperscriptCheckBox: TCheckBox
        Tag = 8
        Left = 144
        Top = 44
        Width = 130
        Height = 17
        Caption = 'Superscript ^x^'
        TabOrder = 2
        OnClick = LegacyExtensionCheckBoxClick
      end
      object InsertCheckBox: TCheckBox
        Tag = 9
        Left = 280
        Top = 44
        Width = 130
        Height = 17
        Caption = 'Insert ++x++'
        TabOrder = 3
        OnClick = LegacyExtensionCheckBoxClick
      end
      object MarkCheckBox: TCheckBox
        Tag = 10
        Left = 416
        Top = 44
        Width = 130
        Height = 17
        Caption = 'Mark ==x=='
        TabOrder = 4
        OnClick = LegacyExtensionCheckBoxClick
      end
      object SmartTypographyCheckBox: TCheckBox
        Tag = 11
        Left = 8
        Top = 68
        Width = 130
        Height = 17
        Caption = 'Smart typography'
        TabOrder = 5
        OnClick = LegacyExtensionCheckBoxClick
      end
      object HeadingAttributesCheckBox: TCheckBox
        Tag = 12
        Left = 144
        Top = 68
        Width = 130
        Height = 17
        Caption = 'Heading {#id}'
        TabOrder = 6
        OnClick = LegacyExtensionCheckBoxClick
      end
      object AutoHeadingIdsCheckBox: TCheckBox
        Tag = 13
        Left = 280
        Top = 68
        Width = 130
        Height = 17
        Caption = 'Auto heading ids'
        TabOrder = 7
        OnClick = LegacyExtensionCheckBoxClick
      end
      object WikiLinksCheckBox: TCheckBox
        Tag = 14
        Left = 416
        Top = 68
        Width = 130
        Height = 17
        Caption = 'Wiki links [[x]]'
        TabOrder = 8
        OnClick = LegacyExtensionCheckBoxClick
      end
    end
    object HTMLDestMemo: TMemo
      Left = 0
      Top = 137
      Width = 554
      Height = 459
      Align = alClient
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Consolas'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssBoth
      TabOrder = 2
      WordWrap = False
    end
  end
  object NotePanel: TPanel
    Left = 0
    Top = 596
    Width = 1100
    Height = 44
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    DesignSize = (
      1100
      44)
    object NoteLinkLabel: TLinkLabel
      Left = 8
      Top = 4
      Width = 1084
      Height = 36
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Caption = 
        'Projects that use the Markdown Processor: <a href="https://githu' +
        'b.com/EtheaDev/MarkdownShellExtensions">MarkdownShellExtensions<' +
        '/a> (Markdown Text Editor, Preview Panel and Thumbnails for Wind' +
        'ows Explorer) and <a href="https://github.com/EtheaDev/MarkdownH' +
        'elpViewer">MarkdownHelpViewer</a> (help system and TMarkdownView' +
        'er component for Delphi applications). Documentation: <a href="h' +
        'ttps://ethea.it/docs/markdowntools/">https://ethea.it/docs/markd' +
        'owntools/</a>'
      TabOrder = 0
      OnLinkClick = NoteLinkLabelLinkClick
    end
  end
  object MarkdownToHTML: TMarkdownToHTML
    Left = 640
    Top = 200
  end
  object FileOpenDialog: TFileOpenDialog
    FavoriteLinks = <>
    FileTypes = <
      item
        DisplayName = 'Markdown files (*.md, *.markdown)'
        FileMask = '*.md;*.markdown;*.mdown;*.mkd'
      end
      item
        DisplayName = 'Text files (*.txt)'
        FileMask = '*.txt'
      end
      item
        DisplayName = 'All files (*.*)'
        FileMask = '*.*'
      end>
    Options = [fdoFileMustExist]
    Title = 'Load a Markdown file'
    Left = 200
    Top = 200
  end
end
