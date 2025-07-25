$date = Get-Date
$__7z_date__='{0:D4}{1:D2}{2:D2}{3:D2}{4:D2}{5:D2}' -f $date.Year, $date.Month, $date.Day, $date.Hour, $date.Minute, $date.Second
$date = $null

# To compress general files.
# -sccUTF-8: console output UTF-8
# -bt: show time statistics
# -slp: use large memory pages
# -mx1: compression level fastest (key factor for compression speed)
# -md=28: dictionary size 2^28=256MB (key factor for compression ratio)
# -mmf=hc4: match finder hc4 (hash chain 4B, key factor for compression speed)
# -mfb=273: word size 273B
# -ms=4g: solid block size 4GB
# -mmt: multithreading (use all CPU cores)
# -mmtf: multithreading for filters
# -myx: analyze all files
# -mqs: sort by type (better compression ratio)
# -mhe: encrypt archive header
$__7z_lzma_args__='-sccUTF-8 -bt -slp -mx1 -md=28 -mfb=273 -ms=4g -mmt -mmtf -myx -mqs -mhe'

# https://stackoverflow.com/questions/53283240/how-to-create-tar-file-with-7zip
# To compress with hard and symbolic links.
# -an: no archive_name field
# -snh: keep hard links
# -snl: keep symbolic links
$__7z_tar_args__='-an -snh -snl'
