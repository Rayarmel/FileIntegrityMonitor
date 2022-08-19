


Write-Host ""

# ask host what they would like to do

Write-Host "What would you like to do?"
Write-Host ""
Write-Host "    A) Collect new Baseline?"
Write-Host "    B) Begin monitoring files with saved Baseline?"
Write-Host ""

$response = Read-Host -Prompt "Please enter 'A' or 'B'"
Write-Host ""

# function to get file hash

Function Calculate-File-Hash($filepath) {
    $filehash = Get-FileHash -Path $filepath -Algorithm SHA512
    return $filehash
}

# function to erase basline file if it already exists
Function Erase-Baseline-If-Already-Exists() {
    $baselineExists = Test-Path -Path .\baseline.txt

    if ($baselineExists) {
    # Delete it
    Remove-Item -Path .\baseline.txt
    }
}

# make sure user inputs valid option

if (-not($response -ne "A" -or "B")) {
    $response = Read-Host -Prompt "Please enter 'A' or 'B'"
}  else {
        Write-Host "user entered $($response.ToUpper())"
}

if ($response -eq "A".ToUpper()) {
    # Delete baseline.txt if it already exists
    Erase-Baseline-If-Already-Exists

    # Calculate hash from the target files and store in baseline.txt   
    # Collect all files in the target folder
    $files = Get-ChildItem -Path .\OneDrive\Desktop\FIM\Files

    # For each file, calculate the hash, and write to baseline.txt
    foreach ($i in $files) {
        $hash = Calculate-File-Hash $i.FullName
        "$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append  # append file so it doesn't keep getting overrided

    }
}
elseif ($response -eq "B".ToUpper()) {

    $fileHashDictionary = @{}

    # Load files|hash from baseline.txt and store them in a dictionary
    $filePathsAndHashes = Get-Content -Path .\baseline.txt

    foreach ($i in $filePathsAndHashes) {
        $fileHashDictionary.Add($i.split("|")[0],$i.split("|")[1])
        
    }

    # Begin (continously) monitoring files with saved Baseline
    while ($true) {
        Start-Sleep -Seconds 1

        $files = Get-ChildItem -Path .\OneDrive\Desktop\FIM\Files

        # For each file, calculate the hash, and write to baseline.txt
        foreach ($i in $files) {
            $hash = Calculate-File-Hash $i.FullName
            
            # notify if a new file has been created
            if ($fileHashDictionary[$hash.Path] -eq $null) {
                # a new file has been created!
                Write-Host "$($hash.Path) has been created!" -ForegroundColor Green
            }
            else {
                # notify if a new file has been changed
                if ($fileHashDictionary[$hash.Path] -eq $hash.Hash) {
                    # the file has not changed
                }
                else {
                # file has been compromised, notify user
                Write-Host "$($hash.Path) has changed!!" -ForegroundColor Cyan
                }
            }
            
        }

        foreach ($key in $fileHashDictionary.Keys) {
                $baselineFileStillExists = Test-Path -Path $key
                if (-Not $baselineFileStillExists) {
                    # one of the baseline files must have been deleted, notify user
                    Write-Host "$($key) has been deleted!" -ForegroundColor Red -BackgroundColor Gray
                }
            }
    }
}
