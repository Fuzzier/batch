# requires -version 5.0

param(
    [string] $alg = "sha1",
	[Parameter(Position=0, ValueFromRemainingArguments=$true)] $args
)
Write-Host $alg.ToUpper() by Microsoft PowerShell Get-FileHash command-let

$content = ""
$alg = $alg.ToUpper()
ForEach ($f In $args)
{
	If ((Get-Item $f) -Is [System.IO.FileInfo])
	{
		$name = (Get-Item $f).Name
		# Write-Host $name
		# Calculate hash.
		$hash = Get-FileHash -Algorithm $alg -LiteralPath $name
		$hash = $hash.Hash
		$line = "$hash *$name"
		$content = "$content`r`n$line"
		Write-Host $line
	}
    Else
	{
		ForEach ($name In (Get-Item $f).Name)
		{
			# Write-Host $name
			# Calculate hash.
			$hash = Get-FileHash -Algorithm $alg -LiteralPath $name
			$hash = $hash.Hash
			$line = "$hash *$name"
			$content = "$content`r`n$line"
			Write-Host $line
		}
	}
}

If ($content.Length)
{
    $d = Get-Location
    $d = (Get-Item $d).Name
    $hashFile = "$d.$($alg.ToLower())"
    # Write header.
    $line = "; $($alg.ToUpper()) by Microsoft PowerShell Get-FileHash command-let"
    Out-File -FilePath $hashFile -Encoding utf8 -InputObject $line
    Out-File -FilePath $hashFile -Encoding utf8 -Append -InputObject ";"
    $datetime = Get-Date
    $line = "; Generated on $datetime"
    Out-File -FilePath $hashFile -Encoding utf8 -Append -InputObject $line
    Out-File -FilePath $hashFile -Encoding utf8 -Append -InputObject ";"
    # Write hash.
    Out-File -FilePath $hashFile -Encoding utf8 -Append -InputObject $content
}
