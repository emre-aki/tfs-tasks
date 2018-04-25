function Get-QualityGateStatus {
 
	param
    (
		$sonar_url,
		$project_key,
		$branch,
		$break_build
    )
	
	$request_uri = "$($sonar_url)/api/project_analyses/search?project=$($project_key)&branch=$($branch)&category=QUALITY_GATE&ps=1&p=1"
	Write-Host "Connecting to SonarQube project with key $($project_key) at $($sonar_url)..."
	
	# An analysis report should be present at this path since 
	# SonarQube tasks have been completed in previous steps.
	$reports_path =  "$((get-item  $($env:BUILD_ARTIFACTSTAGINGDIRECTORY)).parent.FullName)\.sonarqube\out\summary.md"
	
    try {
		# Retrieve analyses and their details by consuming SonarQube RESTful Web API
		$response = Invoke-RestMethod -uri $request_uri -Method GET
	} catch {
		throw "Error while retrieving quality gate status from Sonar. Make sure you have conducted a 'full' analysis prior to this task."
	}

	Write-Host "Connected to project at branch $($branch)."
	if($($response.paging.total) -eq "0") {
		throw "No analysis for the project $($project_key) at branch $($branch) has been found. Please make sure you have conducted a 'full' analysis prior to this task."
	}
	Write-Host "A total of $($response.paging.total) related analyses has been found."
	
	foreach($event in $response.analyses[0].events) {
		if(($event.category -eq "QUALITY_GATE") -and (($event.name -eq "Red (was Green)") -or ($event.name -eq "Red"))) {
			Write-Host "Quality Gate failure: $($event.name)"
			Write-Host "SonarQube Report: $($event.description)"
			ConstructSummary -reports_path $reports_path -is_success $false
			Write-Host "Appropriate build report has been generated at $($reports_path)."
			if($break_build) {
				Write-Host "Breaking build..."
				throw "Quality gate is not satisfied ($($event.description))."	
			} else {
				return
			}
		}
	}
	Write-Host "Quality gate status is valid for the project with key $($project_key) at branch $($branch)."
	ConstructSummary -reports_path $reports_path -is_success $true
	Write-Host "Appropriate build report has been generated at $($reports_path)."
	
}


function ConstructSummary {

	param
	(
		$reports_path,
		$is_success
	)

	$report = ""
	if($is_success) {
		$report += "`r`nQuality gate"
		$report += "<span style='color: #FFFFFF; background-color: #85BB43; border-radius: 3px; padding:4px 10px; margin-left: 5px;'>passed</span>."
	} else {
		$report += " `r`nQuality gate is not satisfied."
		$report += "<span style='color: #F3F3F3; background-color: #D4333F; border-radius: 3px; padding:4px 10px; margin-left: 5px;'>$($event.description)</span>"
		$report += " [More...]($($sonar_url)/dashboard?branch=$($branch)&id=$($project_key))"
	}
	$report > "$($reports_path)"
	Write-Host "##vso[task.addattachment type=Distributedtask.Core.Summary;name=SonarQube Analysis Report;]$reports_path"

}