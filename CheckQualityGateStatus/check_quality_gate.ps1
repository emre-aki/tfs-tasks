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

# Read Build Task parameters
$project_key = Get-VstsInput -Name project_key -Require
$sonar_url = Get-VstsInput -Name sonar_url -Require
$break_build = Get-VstsInput -Name break_build

# Read required build variables
$source_branch = $env:SYSTEM_PULLREQUEST_SOURCEBRANCH

if(!$source_branch) {
    throw "Environment Error: The build should have been triggered via a Pull Request."
} 

$source_branchname = $source_branch.split("/")[-1]

# Set a flag to force verbose as a default
$VerbosePreference = 'Continue' # equiv to -verbose

Import-Module -Name "$PSScriptRoot\module.psm1" -Force
Get-QualityGateStatus -sonar_url $sonar_url -project_key $project_key -branch $source_branchname -break_build $break_build