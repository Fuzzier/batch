$date = Get-Date
$__rar_date__='{0:D4}{1:D2}{2:D2}{3:D2}{4:D2}{5:D2}' -f $date.Year, $date.Month, $date.Day, $date.Hour, $date.Minute, $date.Second
$date = $null

# To compress general files.
# -htb: use BLAKE2 hash function
# -m3: compression level normal
# -md256m: dictionary size 256MB (key factor for compression ratio)
# -mlp: large memory pages (rar v7.10+)
# -idn: disables archived names output
# -oc: set NTFS "Compressed" attribute
# -oh: save hard links as link
# -ol: save symbolic links as link (if the actual target is not archived, the symlink will NOT be archived)
# -oi: save identical files as references
# -r: recurse subfolders
# -rr3p: add data recovery record (3 percent)
# -s: create a solid archive
$__rar_args__='-htb -m3 -md256m -mlp -idn -oc -oh -ol -oi -r -rr3p -s'
