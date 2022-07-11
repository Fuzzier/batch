@ECHO OFF

:: https://stackoverflow.com/questions/53283240/how-to-create-tar-file-with-7zip

:: To compress general files.
:: -sccUTF-8: console output UTF-8
:: -bt: show time statistics
:: -slp: use large memory pages
:: -mx1: compression level fastest (key factor for compression speed)
:: -md=27: dictionary size 2^27=128MB (key factor for compression ratio)
:: -mmf=hc4: match finder hc4 (hash chain 4B, key factor for compression speed)
:: -mfb=273: word size 273B
:: -ms=4g: solid block size 4GB
:: -mmt: multithreading (use all CPU cores)
:: -mmtf: multithreading for filters
:: -myx: analyze all files
:: -mqs: sort by type (better compression ratio)
:: -mhe: encrypt archive header
SET __7z_lzma_args__=-sccUTF-8 -bt -slp -mx1 -md=27 -mfb=273 -ms=4g -mmt -mmtf -myx -mqs -mhe

:: To compress x86/x64 executables.
:: -mf=BCJ2::d27
::     use BCJ2 filter (for x86 executables)
::     d27: dictionary size 2^27=128MB
SET __7z_bcj_args__=-mf=BCJ2:d=27

:: To compress with hard and symbolic links.
:: -an: no archive_name field
:: -snh: keep hard links
:: -snl: keep symbolic links
SET __7z_tar_args__=-an -snh -snl

:: tar7z <command> <arguments>
:: command:
::   a:  add
::   at: add tar.7z
::   x:  extract
::   xt: extract tar.7z

IF "%~1"=="a" (
    CALL :Add7z%*
) ELSE IF "%~1"=="at" (
    CALL :AddTar7z%*
) ELSE IF "%~1"=="x" (
    CALL :Extract7z%*
) ELSE IF "%~1"=="xt" (
    CALL :ExtractTar7z%*
)

SET __7z_archive__=

EXIT /B

========= Add7z =========
:Add7za
:: a: add to archive
7z.exe a %__7z_lzma_args__% %*
EXIT /B


========= AddTar7z =========
:AddTar7zat
:: a: add to archive
:: -ttar: create tarball
:: -so: write to stdout
:: -si: read from stdin
7z.exe a -ttar -so %__7z_tar_args__% "%~1" | 7z.exe a -si %__7z_lzma_args__% "%~1.tar.7z"
EXIT /B


========= Extract =========
:Extract7zx
:: x: extract with full paths
:: -si: read from stdin
:: -bt: show time statistics
:: -sccUTF-8: console output UTF-8
7z.exe x -bt -sccUTF-8 "%~1"
EXIT /B


========= Extract =========
:ExtractTar7zxt
:: e: extract without paths (it is a tarball)
:: x: extract with full paths
:: -so: write to stdout
:: -si: read from stdin
:: -bt: show time statistics
:: -sccUTF-8: console output UTF-8
7z.exe e -so "%~1" | 7z.exe x -ttar -si -bt -sccUTF-8
EXIT /B
