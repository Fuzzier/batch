CALL GetDateTime
SET __rar_date__=%__year__%%__month__%%__day__%

:: To compress general files.
:: -htb: use BLAKE2 hash function
:: -m3: compression level normal
:: -md256m: dictionary size 128MB (key factor for compression ratio)
:: -mlp: large memory pages (rar v7.10+)
:: -idn: disables archived names output
:: -oc: set NTFS "Compressed" attribute
:: -oh: save hard links as link
:: -ol: save symbolic links as link (if the actual target is not archived, the symlink will NOT be archived)
:: -r: recurse subfolders
:: -rr3p: add data recovery record (3 percent)
:: -s: create a solid archive
SET __rar_args__=-htb -m3 -md128m -mlp -idn -oc -oh -ol -r -rr3p -s

EXIT /B