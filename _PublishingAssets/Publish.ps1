param(
    [string]$publishTo = "",
    [string]$projectPath = "",
    [string]$iisPath = "",
    [string]$releaseType = "patch",
    [string]$env = "Production"
)

$currentLoc = Get-Location
Import-Module WebAdministration

if (
    ($publishTo.Trim() -eq "") -or 
    -NOT (Test-Path -Path $publishTo -PathType Container)
) {
    Write-Host "We could not find the specified '-publishTo'. Please check that the below path exists and it's a folder" -ForegroundColor Red
    try {
        Write-Host ("-publishTo: " + (Resolve-Path $publishTo)) -ForegroundColor Red
    }
    catch {
        Write-Host ("-publishTo: """ + $publishTo + """") -ForegroundColor Red
    }
}
elseif (
    ($projectPath.Length -lt 8) -or 
    (".csproj" -ne $projectPath.Substring($projectPath.Length - 7)) -or 
    (-NOT (Test-Path -Path $projectPath -PathType Leaf))
) {
    Write-Host "We could not find the specified '-projectPath'. Please check that the below path exists and it is a .csproj file" -ForegroundColor Red
    try {
        Write-Host ("-projectPath: " + (Resolve-Path $projectPath)) -ForegroundColor Red
    }
    catch {
        Write-Host ("-projectPath: """ + $projectPath + """") -ForegroundColor Red
    }
}
elseif (
    ($iisPath.Trim() -eq "") -or 
    -NOT (Test-Path -Path ("IIS:\Sites\" + $iisPath) -PathType Container)
) {
    Write-Host "We could not resolve the '-iisPath'. Please check that the below application exists in IIS Sites" -ForegroundColor Red
    try {
        Write-Host ("iisPath: " + (Resolve-Path ("IIS:\Sites\" + $iisPath)).Replace("IIS:\Sites\", "IIS:\Sites\ => """) + """") -ForegroundColor Red
    }
    catch {
        Write-Host ("iisPath: IIS:\Sites\ => """ + $iisPath + """") -ForegroundColor Red
    }
}
elseif (
    -NOT ($releaseType -eq "major") -and
    -NOT ($releaseType -eq "minor") -and
    -NOT ($releaseType -eq "patch") -and
    -NOT ($releaseType -eq "suffix")
) {
    Write-Host ("'-releaseType' must be 'major', 'minor', 'patch' or 'suffix'. '" + $releaseType + "' is not valid") -ForegroundColor Red
}
elseif (
    -NOT (Test-Path -Path ("_version.txt") -PathType Leaf)
) {
    Write-Host ("We could not resolve the required version file. Please ensure that a '_version.txt' file exist at '" + $currentLoc + "'") -ForegroundColor Red
}
else {
    $revisionArray = (Get-Content -Path '_version.txt').Split('.')
    $revisionSuffixArray = ""

    if (
        Test-Path -Path ('_version-suffix-' + $env + '.txt') -PathType Leaf
    ) {
        $revisionSuffixArray = (Get-Content -Path ('_version-suffix-' + $env + '.txt')).Split(".")
    }
    
    if (
        -NOT ($revisionArray.Length -eq 3)
    ) {
        Write-Host "Version file does not contain a valid format. Please ensure that the '_version.txt' file contents follow the versioning requirements" -ForegroundColor Red
    }
    elseif (
        ($revisionSuffixArray -is [array] ) -and
        -NOT ($revisionSuffixArray.Length -gt 2)
    ) {
        Write-Host ("The suffix file is not a valid format. Please ensure that the '_version-suffix-" + $env + ".txt' file contents follow the versioning requirements") -ForegroundColor Red
    }
    elseif (
        ($revisionSuffixArray -eq "") -and
        ($releaseType -eq "suffix")
    ) {
        Write-Host ("A suffix file is required if the '-releaseType' is 'suffix'. Please ensure that the '_version-suffix-" + $env + ".txt' file exists") -ForegroundColor Red
    }
    else {

        Write-Host "--- Version Info ---"
        Write-Host ("Current version: " + ($revisionArray -join '.') + ($revisionSuffixArray -join '.'))

        switch ($releaseType) {
            "major" { 
                $revisionArray[0] = $revisionArray[0] + 1
                $revisionArray[1] = 0
                $revisionArray[2] = 0
            }
            "minor" { 
                $revisionArray[1] = $revisionArray[1] + 1
                $revisionArray[2] = 0
            }
            "patch" { 
                $revisionArray[2] = $revisionArray[2] + 1
            }
            Default {}
        }

        $newRevision = ($revisionArray -join '.')

        if (
            -NOT ($revisionSuffixArray -eq "")
        ){
            if (
                $releaseType -eq "suffix"
            ) {
                if (
                    $revisionSuffixArray -is [array]
                ) {
                    $revisionSuffixArray[1] = $revisionSuffixArray[1] + 1
                }
                else {
                    $revisionSuffixArray = $revisionSuffixArray + 1
                }
            }
            else {
                if (
                    $revisionSuffixArray -is [array]
                ) {
                    $revisionSuffixArray[1] = 0
                }
                else {
                    $revisionSuffixArray = 0
                }
            }

            $newRevision += ("-" + ($revisionSuffixArray -join '.'))
        }

        Write-Host ("New version: " + $newRevision)
        Write-Host "--- Starting ---"

        if (
            -NOT (($publishTo.LastIndexOf("\") + 1) -eq $publishTo.Length) -and
            -NOT (($publishTo.LastIndexOf("/") + 1) -eq $publishTo.Length)
        ) {
            $publishTo += "\"
        }

        $newPath = $publishTo + $newRevision + "\"

        Try {
            Write-Host ("Started to publish version: " + $newRevision)
            dotnet publish $projectPath -c Release -o $newPath -p:EnvironmentName=$env
            
            Write-Host ("Changing IIS location of '" + $iisPath + "' to new version (" + $newRevision + ")")
            Set-Location IIS:\Sites\
            Set-ItemProperty $iisPath -name physicalPath -value $newPath

            Set-Location $currentLoc
            
            Set-Content -Path "_version.txt" -value ($revisionArray -join ".")

            if (
                -NOT ($revisionSuffixArray -eq "")
            ) {
                Set-Content -Path ('_version-suffix-' + $env + '.txt') -value ($revisionSuffixArray -join ".")
            }
            Write-Host ("Now running version: " + $newRevision)

            Write-Host "Waiting 10 seconds before deleting old files"
            Start-Sleep -s 10
            Write-Host "Deleting"
            if (
                (Test-Path -Path ($publishTo + $revision + "\") -PathType Container)
            ) {
                Remove-Item ($publishTo + $revision + "\") -Recurse
            }
        }
        Catch {
            Write-Host $_ -ForegroundColor Red
            Write-Host "Error in publishing, please see error log"
        }

        Remove-Variable -name newRevision
        Remove-Variable -name newPath
    }

    Remove-Variable -name revisionArray
    Remove-Variable -name revisionSuffixArray
}
Remove-Module WebAdministration
Remove-Variable -name currentLoc