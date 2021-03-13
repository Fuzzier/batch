# requires -version 5.0

param(
    [string] $alg = "sha1",       # The hash algorithm.
	[Alias('v')] $verify = $null, # The path of the hash file to verify.
	[Parameter(Position=0, ValueFromRemainingArguments=$true)] $args
)

function Generate([string] $alg)
{
    $alg = $alg.ToUpper()
    Write-Host Generate $alg by Microsoft PowerShell Get-FileHash command-let
    $content = ''
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
		    $content = "$content`n$line"
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
			    $content = "$content`n$line"
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
}

function Verify([string] $file)
{
    If ([System.IO.File]::Exists($file))
    {
        # The file extension is the algorithm.
        # Otherwise, the file name is the algorithm.
        $alg = ($file -split '\.')[-1]
        $alg = $alg.ToUpper()
        Write-Host Verify $alg by Microsoft PowerShell Get-FileHash command-let
        $content = Get-Content -LiteralPath $file -Encoding UTF8
        $lines = $content -split '\n'
        ForEach ($line In $lines)
        {
            # Skip comment lines that start with ';'.
            If ($line -match '^\s*;')
            {
                Continue
            }
            # A hash value line looks like '0123456789ABCDEF *filename'
            # The hexadecimal value and the filename are separated by '*'.
            If ($line -match '^\s*([0-9A-Za-z]+)\s*\*\s*(.*)')
            {
                $hash = $Matches[1].ToUpper()
                $name = $Matches[2].TrimEnd()
                Write-Host * $name
                Write-Host -NoNewline "  expect: $hash"
                $csum = Get-FileHash -Algorithm $alg -LiteralPath $name
                $csum = $csum.Hash.ToUpper()
                If ($hash -eq $csum)
                {
                    Write-Host -ForegroundColor DarkGreen "  passed"
                }
                Else
                {
                    Write-Host -ForegroundColor DarkRed "  wrong"
                    Write-Host "  actual: $csum"
                }
            }
        }
    }
}

If ($verify -eq $null)
{
    Generate -alg $alg @args
}
Else
{
    Verify -file $verify
}
