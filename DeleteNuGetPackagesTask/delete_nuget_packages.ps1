[CmdletBinding()]
param (
 	
 	# It has been realized that binding mandatory fields as cmdlet parameters works 
 	# inconsistently as it may not always possible to pass them as inputs to a Powershell script. 
 	# For that particular reason, the parameters below are commented out and they are
 	# read using 'Get-VstsInput' below.

    # [parameter(Mandatory=$true, HelpMessage="The target feed name from which the release candidates will be removed")]
    # $feedname,

	# [parameter(Mandatory=$true, HelpMessage="The package versions matching this pattern will be removed from the given feed. By default, all versions will be included.")]
    # $inc,

	# [parameter(Mandatory=$false, HelpMessage="The package versions matching this pattern will be excluded from removal. By default, none will be excluded.")]
    # $exc

)

# Reading Build Task parameters
$feedname = Get-VstsInput -Name feedname -Require
$inc = Get-VstsInput -Name inc -Require
$exc = Get-VstsInput -Name exc

# If exclusion regex parameter is left blank, ensure they are assigned empty strings.
if ([string]::IsNullOrEmpty($exc)) {
	$exc = ""
}

# Set a flag to force verbose as a default
$VerbosePreference ='Continue' # equiv to -verbose

Import-Module -Name "$PSScriptRoot\module.psm1" -Force 

# Read required build variables
$tfsUri = $env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI

# Using "devdexmonugetuser" credentials
$username = "devdexmonugetuser"
$pwd = ConvertTo-SecureString "95Ba!!23613" -AsPlainText -Force

# Create a Credential object to consume TFS RESTful API
$cred = New-Object System.Management.Automation.PSCredential ($username, $pwd)

# Get packages in the target feed
Write-Verbose "Connecting to target feed $($feedname)..."
$pList = Get-Packages -tfsuri $tfsUri -feedName $feedname -cred $cred

# Determine which packages are to be deleted
$deletePackages =  Get-PackageVersions -pList $pList -inc $inc -exc $exc -cred $cred

# Delete packages matching the given version regex
Invoke-DeletePackages -tfsuri $tfsUri -feedName $feedname -deletePackages $deletePackages -cred $cred
