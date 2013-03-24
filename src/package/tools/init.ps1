param($installPath, $toolsPath, $package, $project)

Import-Module (Join-Path $toolsPath Resolve-RootFolder.psm1)

function Setup-FolderStructure {
    Write-Debug "First time setup of documentation"
}

function Upgrade-FolderStructure {
    Write-Debug "Existing documentation folder already found"
}

$project_root = Resolve-RootFolder($toolsPath);

Write-Host "Adding docs folder into folder $project_root"

$docs_folder = Join-Path -Path $project_root "docs"
$configFile = Join-Path -Path $docs_folder "scribble.json"
$version = $package.ToString()

# if this is the first time we run the package
if ([IO.Directory]::Exists($docs_folder) -eq $false) {

    Setup-FolderStructure
    
    # create folder
	$templatePath = Join-Path -Path $toolsPath "template\*"

	# populate folder with template contents
    New-Item -ItemType directory -Path $docs_folder
	Copy-Item -Path $templatePath -Destination $docs_folder -Recurse | Out-Null

    $port =  Get-Random -Minimum 30000 -Maximum 50000
    
	# dump the version and created port to the config file
    $properties = @{}
    $properties.Add('version',$version)
    $properties.Add('port',$port)
    ConvertTo-Json $properties | Out-File $configFile

    # TODO: overwrite template references to localhost:????? to localhost:40000

	# open the file in Visual Studio
    $index = Join-Path -Path $docs_folder "index.md"
	$dte.ItemOperations.OpenFile($index)

} else {  

	$installed_version = $null
    $port = 40000 

	if ([IO.File]::Exists($configFile) -eq $true) {
        $json = Get-Content $configFile | Out-String 
        $properties = ConvertFrom-Json $json
		$installed_version = $properties.version
        $port = $properties.port
    }

	if ($installed_version -ne $package) {
        
        Upgrade-FolderStructure

		# update the version stored in configuration
        if ([IO.File]::Exists($configFile) -eq $true) {
            Remove-Item $configFile
        }

        $properties = @{}
        $properties.Add('version',$version)
        $properties.Add('port',$port)
        ConvertTo-Json $properties | Out-File $configFile
	} else {
        Write-Debug "No changes necessary, you've got the latest code"
    }
}

# TODO: hook in any other commands

# launch ze missiles
$launch_script = Join-Path -Path $toolsPath "_pretzel\Launch-Docs.ps1"
powershell -File $launch_script -DocsRoot $docs_folder -PortNumber $port