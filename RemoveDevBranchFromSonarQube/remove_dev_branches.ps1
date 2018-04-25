[CmdletBinding()]
param (
 	
 	# It has been realized that binding mandatory fields as cmdlet parameters works 
 	# inconsistently as it may not always possible to pass them as inputs to a Powershell script. 
 	# For that particular reason, the parameters below are commented out and they are
 	# read using 'Get-VstsInput' below.

    # [parameter(Mandatory=$true, HelpMessage="The key associated with your SonarQube project")]
    # $project_key,

    # [parameter(Mandatory=$true, HelpMessage="The URL to your SonarQube server, e.g. http://unitfs:9000")]
    # $sonar_url 

)

# Set a flag to force verbose as a default
$VerbosePreference = 'Continue' # equiv to -verbose

# Read Build Task parameters
$project_key = Get-VstsInput -Name project_key -Require
$sonar_url = Get-VstsInput -Name sonar_url -Require
$admin_token = Get-VstsInput -Name admin_token -Require

# Read required build variables
$source_branch = $env:BUILD_SOURCEBRANCH
$tfs_uri = $env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI
$repo = $env:BUILD_REPOSITORY_NAME
$team_project = $env:SYSTEM_TEAMPROJECT

# Using "xxxx" credentials
$username = "xxxx"
$pwd = ConvertTo-SecureString "xxxx" -AsPlainText -Force

# Create a Credential object to consume TFS RESTful API
$cred = New-Object System.Management.Automation.PSCredential ($username, $pwd)

if(!($source_branch -match "refs/heads/\d+\.\d+\.\d+")) {
	throw "This task should only be run on a release branch."
}

Import-Module -Name "$PSScriptRoot\module.psm1" -Force

# Get list of completed PRs
$branches_to_delete = Get-CompletedPRs -tfs_uri $tfs_uri -team_project $team_project -repository $repo -target_branch $source_branch -cred $cred

Write-Host "Deleting branches..."
foreach($branch in $branches_to_delete) {
    DeleteBranchFromSonar -sonar_url $sonar_url -project_key $project_key -branch $branch -admin_token $admin_token
}