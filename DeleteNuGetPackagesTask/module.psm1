function Get-Packages {
 
	param
    (
		$tfsuri,
        $feedName,
        $cred
    )
	
	$pList = New-Object System.Collections.ArrayList
    Write-Host "Fetching packages from the feed $($feedName)..."

    try {
		# Retrieve feed and its packages by consuming TFS RESTful API
		$jsonresponse = Invoke-RestMethod -uri "$($tfsuri)/_apis/packaging/feeds/$($feedName)/?api-version=2.0-preview.1" -Method GET -Credential $cred
		$url2Packages = $jsonresponse._links.packages.href
		$packages_json = Invoke-RestMethod -Uri $url2Packages -Method GET -Credential $cred
		Write-Host "Fetching complete: $($packages_json.count) package(s) have been fetched."
		# Collect packages in pList
		Write-Host "Retrieving fetched packages..."
		foreach($package in $packages_json.value) {
			[Void] $pList.Add($package)
			Write-Host ">       Retrieved package: $($package.name)."
		}
		Write-Host "$($pList.Count) package(s) have been retrieved."
	}
	catch {
		throw "Error while retrieving packages: $($_.Exception.Message)"
	}
	return ,$pList
 
}
 
 
function Get-PackageVersions {
	param
	(
		$pList,
		$inc,
		$exc,
		$cred
	)
 
	# Stores ($($package.name), $($package.version)) tuples in a list
	$tList = New-Object System.Collections.ArrayList
	Write-Host "Retrieving package versions:"
	Write-Host "--> Matching ""$($inc)"""
	if (!([string]::IsNullOrEmpty($exc))) {
		Write-Host "--> Excluding ""$($exc)""."
	}

	try { 
		$countTotalPackageVersions = 0
		# Iterate over packages in the list
		foreach($package in $pList) {           
			$countPackageVersionsRetrieved = 0
			Write-Host ">       Retrieving versions for $($package.name)..."
			# Get version metadata by consuming RESTful for the current package 
			$versions_md = Invoke-RestMethod -Uri $package._links.versions.href -Method GET -Credential $cred
			# Iterate over package versions
			foreach($normalized_ver in $versions_md.value) {
				# Append the tuple (package[i].name, package[i].version[j]) if version matches the include regex
				if (($normalized_ver.version -match $inc)){
					$countPackageVersionsRetrieved += 1
					[Void] $tList.Add([System.Tuple]::Create($($package.name), $normalized_ver.version))
					Write-Host ">              Retrieved $($package.name)-v$($normalized_ver.version)."
					# Remove the tuple (package[i].name, package[i].version[j]) if version matches the exclude regex
					if((!([string]::IsNullOrEmpty($exc))) -and ($normalized_ver.version -match $exc)) {
						$countPackageVersionsRetrieved -= 1
						$tList.RemoveAt(($tList.Count) - 1)
						Write-Host ">              Excluding $($tList[$tList.Count - 1].Item1)-v$($tList[$tList.Count - 1].Item2)."
					}
				}
			}
			Write-Host ">       Retrieved $($countPackageVersionsRetrieved) version(s) for $($package.name)."
			$countTotalPackageVersions += $countPackageVersionsRetrieved
		}
		Write-Host "$($countTotalPackageVersions) package version(s) in total have been received."
	}
	catch {
		throw "Error while retrieving versions: $($_.Exception.Message)"
	}
	return ,($tList.ToArray())
               
}
 
 
function Invoke-DeletePackages {
 
	param        
	(
		$tfsuri,
		$feedName,
		$deletePackages,
		$cred
	)
 
	Write-Host "Deleting packages..."
	try {
		$countDeleted = 0
		foreach($package in $deletePackages) {
			$jsonresponse = Invoke-RestMethod -uri "$($tfsuri)/_apis/packaging/feeds/$($feedName)/nuget/packages/$($package.Item1)/versions/$($package.Item2)?api-version=3.0-preview" -Method DELETE -Credential $cred
			Write-Host ">       $($jsonresponse.deletedDate): Deleted $($package.Item1)-v$($package.Item2)."
			$countDeleted += 1
		}
	}
	catch {
		throw "Error while deleting packages: $($_.Exception.Message)"
	}
	Write-Host "Deleted $($countDeleted) package(s)."
 
}