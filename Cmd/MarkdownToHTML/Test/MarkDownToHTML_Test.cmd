@echo Off
Set CommandFile="..\..\Win64\MarkDownToHTML.exe"
@echo Using: %CommandFile%

@echo *************************************************************************
@echo Test simple call (shows help)
@echo calling: %CommandFile%
call %CommandFile%

@echo *************************************************************************
@echo Test help command (shows generic help)
@echo calling: %CommandFile% help
call %CommandFile% help

@echo *************************************************************************
@echo Test help for processfile command (shows detailed help for processfile)
@echo calling: %CommandFile% help processfile
call %CommandFile% help processfile

@echo *************************************************************************
@echo Test processfile command with only input filename
@echo calling: %CommandFile% processfile -in:"..\..\..\TestFile\MarkDown Support Test.md"
call %CommandFile% processfile -in:"..\..\..\TestFile\MarkDown Support Test.md"

@echo *************************************************************************
@echo Test processfile command with input and output filename
@echo calling: %CommandFile% processfile -in:"..\..\..\TestFile\MarkDown Support Test.md" -out:"..\..\..\TestFile\CommonMark.html"
call %CommandFile% processfile -in:"..\..\..\TestFile\MarkDown Support Test.md" -out:"..\..\..\TestFile\CommonMark.html"

@echo *************************************************************************
@echo Test processfile command with input and output filename
@echo calling: %CommandFile% processfile -in:"..\..\..\TestFile\MarkDown Support Test.md" -out:"..\..\..\TestFile\CommonMark.html"
call %CommandFile% processfile -in:"..\..\..\TestFile\MarkDown Support Test.md" -out:"..\..\..\TestFile\CommonMark.html"

@echo *************************************************************************
@echo Test processfile command with DaringFireball Dialect
@echo calling: %CommandFile% processfile -dialect:DaringFireball -in:"..\..\..\TestFile\MarkDown Support Test.md" -out:"..\..\..\TestFile\DaringFireball.html"
call %CommandFile% processfile -dialect:DaringFireball -in:"..\..\..\TestFile\MarkDown Support Test.md" -out:"..\..\..\TestFile\DaringFireball.html"

@echo *************************************************************************
@echo Test processfile command with GFM Dialect (GitHub Flavored Markdown)
@echo calling: %CommandFile% processfile -dialect:GFM -in:"..\..\..\TestFile\MarkDown Support Test.md" -out:"..\..\..\TestFile\GFM.html"
call %CommandFile% processfile -dialect:GFM -in:"..\..\..\TestFile\MarkDown Support Test.md" -out:"..\..\..\TestFile\GFM.html"

@echo *************************************************************************
@echo Test processfile command with Custom StyleSheet
@echo calling: %CommandFile% processfile -in:"..\..\..\TestFile\MarkDown Support Test.md" -out:"..\..\..\TestFile\UseCustomStyleSheet.html" -Style:"..\..\..\TestFile\MarkDown Support Test.css"
call %CommandFile% processfile -in:"..\..\..\TestFile\MarkDown Support Test.md" -out:"..\..\..\TestFile\UseCustomStyleSheet.html" -Style:"..\..\..\TestFile\MarkDown Support Test.css"

@echo *************************************************************************
@echo Test processfile command without StyleSheet
@echo calling: %CommandFile% processfile -in:"..\..\..\TestFile\MarkDown Support Test.md" -out:"..\..\..\TestFile\NoStyleSheet.html" -Style:none
call %CommandFile% processfile -in:"..\..\..\TestFile\MarkDown Support Test.md" -out:"..\..\..\TestFile\NoStyleSheet.html" -Style:none

@echo *************************************************************************
@echo Test processfile command with Unsafe mode (active content NOT escaped)
@echo calling: %CommandFile% processfile -in:"..\..\..\TestFile\MarkDown Support Test.md" -out:"..\..\..\TestFile\Unsafe.html" -unsafe
call %CommandFile% processfile -in:"..\..\..\TestFile\MarkDown Support Test.md" -out:"..\..\..\TestFile\Unsafe.html" -unsafe

@echo *************************************************************************
@echo End of Test.
:exit
pause