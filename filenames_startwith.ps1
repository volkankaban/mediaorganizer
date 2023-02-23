$folderPath = "D:\Pictures\2003"
$files = Get-ChildItem $folderPath -File -Recurse
$renameCounters = @{} # A hashtable to store the rename counters for each date

$shell = New-Object -ComObject Shell.Application

foreach ($file in $files) {
    # Check if the file name starts with "IMG_", "IMG-", "VID_", "VID-", or already has the format "yyyyMMdd_HHmmss"
    if (($file.Name -clike "IMG_*") -or ($file.Name -clike "IMG-*") -or ($file.Name -clike "VID_*") -or ($file.Name -clike "VID-*") -or ($file.Name -match "\d{8}_\d{6}")) {
        Write-Host "Skipping $($file.FullName) as it already has a valid name" -ForegroundColor Green
        continue
    }

    # Get the date taken and modified of the file
    $dateTaken = $file.CreationTime
    $dateModified = $file.LastWriteTime

    $dir = $shell.NameSpace( $file.Directory.FullName )

    $fileTemp = $dir.ParseName( $file.Name )
    $dateTakenTemp = $dir.GetDetailsof($fileTemp, 12)
    # Check if the file has a "Date taken" property and extract the date
    if ("" -ne $dateTakenTemp) {
        try {
            $dateTaken = [DateTime]::ParseExact($dateTakenTemp.Trim().replace("`u{200E}", "").replace("`u{200F}", ""), "MM/dd/yyyy HH:mm", $null)
        } catch {
            Write-Host "Error parsing date for file $($file.FullName): $_" -ForegroundColor Red
        }
        $date = $dateTaken
    } else {
        $date = $dateModified
    }

    # Determine the rename counter for the current date
    $renameCounter = $renameCounters[$date.ToString("yyyyMMdd_HHmmss")]
    if ($renameCounter -eq $null) {
        $renameCounter = 1
    } else {
        $renameCounter++
    }
    $renameCounters[$date.ToString("yyyyMMdd_HHmmss")] = $renameCounter

    # Rename the file with the date in YYYYMMDD-HHmmss format, followed by the rename counter
    $newName = $date.ToString("yyyyMMdd_HHmmss") + "_$renameCounter" + $file.Extension

    # Attempt to rename the file, with error handling to output any errors to the console
    try {
        Rename-Item -Path $file.FullName -NewName $newName -ErrorAction Stop
    } catch {
        Write-Host "Error renaming file $($file.FullName): $_" -ForegroundColor Red
    }
}
