CALL GetDateTime
SET __7z_date__=%__year__%%__month__%%__day__%

:: https://stackoverflow.com/questions/53283240/how-to-create-tar-file-with-7zip

:: To compress general files.
:: -sccUTF-8: console output UTF-8
:: -bt: show time statistics
:: -slp: use large memory pages
:: -mx1: compression level fastest (key factor for compression speed)
:: -md=28: dictionary size 2^28=256MB (key factor for compression ratio)
:: -mmf=hc4: match finder hc4 (hash chain 4B, key factor for compression speed)
:: -mfb=273: word size 273B
:: -ms=4g: solid block size 4GB
:: -mmt: multithreading (use all CPU cores)
:: -mmtf: multithreading for filters
:: -myx: analyze all files
:: -mqs: sort by type (better compression ratio)
:: -mhe: encrypt archive header
SET __7z_lzma_args__=-sccUTF-8 -bt -slp -mx1 -md=28 -mfb=273 -ms=4g -mmt -mmtf -myx -mqs -mhe

:: To compress with hard and symbolic links.
:: -an: no archive_name field
:: -snh: keep hard links
:: -snl: keep symbolic links
SET __7z_tar_args__=-an -snh -snl

EXIT /B