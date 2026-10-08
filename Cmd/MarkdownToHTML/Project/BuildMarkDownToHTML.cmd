call "C:\BDS\Studio\37.0\bin\rsvars.bat"
msbuild.exe "MarkDownToHTML.dproj" /target:Clean;Build /p:Platform=Win64 /p:config=release
msbuild.exe "MarkDownToHTML.dproj" /target:Clean;Build /p:Platform=Win32 /p:config=release

call D:\ETHEA\Certificate\SignFileWithSectico.bat D:\ETHEA\MarkdownProcessor\Cmd\Win32\MarkDownToHTML.exe
call D:\ETHEA\Certificate\SignFileWithSectico.bat D:\ETHEA\MarkdownProcessor\Cmd\Win64\MarkDownToHTML.exe

:END
pause
