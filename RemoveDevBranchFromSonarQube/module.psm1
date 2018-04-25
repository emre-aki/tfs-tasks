function Get-CompletedPRs {
 
	param
    (
		$tfs_uri,
		$team_project,
		$repository,
		$target_branch,
		$cred
    )
	
	$bList = New-Object System.Collections.ArrayList
	Write-Host "Fetching completed PRs from the from $($team_project)/$($repository)/$($target_branch)..."

    try {
		# Retrieve  completed PRs by consuming TFS RESTful API
		$response = Invoke-RestMethod -uri "$($tfs_uri)/$($team_project)/_apis/git/repositories/$($repository)/pullRequests?api-version=3.0&targetRefName=$($target_branch)&status=Completed" -Method GET -Credential $cred
		# Collect fetched PRs in bList
		foreach($pr in $response.value) {
			[Void] $bList.Add($pr.sourceRefName.split('/')[-1])
	}
		Write-Host "Fetch complete: $($bList.Count) branch(es) have been fetched."
	} catch {
		throw "Error while retrieving branches: $($_.Exception.Message)"
	}
	return ,$bList
 
}

function DeleteBranchFromSonar {
 
	param
    (
		$sonar_url,
		$project_key,
		$branch,
		$admin_token
    )
	
	Write-Host "Deleting branch $($branch) from SonarQube project with key $($project_key)."
	$request_url = "$($sonar_url)/api/project_branches/delete?branch=$($branch)&project=$($project_key)"
	$params = @{uri = $request_url;
                Method = 'POST';
				# Authorization : Basic username:password
                Headers = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($admin_token):"))}
			   }
	try {
		Invoke-RestMethod @params
		Write-Host "Removed branch $($project_key)/$($branch) successfully."
	} catch {
		Write-Warning "Failed to remove: Branch $($project_key)/$($branch) not found."
	}

}