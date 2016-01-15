# Parameters to be received from TeamCity
param(
    #[parameter(Mandatory=$false)] [string]$stashProjectName = "xx",
	[parameter(Mandatory=$false)] [string]$stashProjectName = "xx",
    [parameter(Mandatory=$false)] [string]$buildcounter
)

$global:stashBaseUrl = "https://<>/rest/api/1.0/projects/";
$global:stash_username = "xx";
$global:stash_password = "xx";

$global:projectName = $stashProjectName;
$global:nl = [Environment]::NewLine;


Write-Host "Trying connecting to Stash..." -foreground Green

# ---------------
# Connect to Stash using powershell API #
# ---------------
$stash = New-Module -ScriptBlock {
	Function CompareTagGetCommits(){
		param([string] $fromTag, [string] $toTag)
		try{
			#$url = "$global:stashBaseUrl" + "$global:projectName" + "/compare/commits?from=refs/tags/1.1.8&to=refs/tags/1.1.7";
			$url = "$global:stashBaseUrl" + "$global:projectName" + "/compare/commits?from=refs/tags/$fromTag&to=refs/tags/$toTag";
			Write-Host "URL = " + $url;
			Write-Host "=======Comparing Tags - $fromTag and $toTag =========";
			
			$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $global:stash_username,$global:stash_password)))
			return Invoke-RestMethod -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Uri $url -Verbose 
		}catch {
			$_.Exception.Response
		}		
	}

	Function GetCommits(){
		try{
			$url = "$global:stashBaseUrl" + "$global:projectName" + "/commits";
			Write-Host "URL = " + $url;
			$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $global:stash_username,$global:stash_password)))
			return Invoke-RestMethod -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Uri $url -Verbose 
		}catch {
			$_.Exception.Response
		}		
	}
	
	Export-ModuleMember -Function GetCommits
	Export-ModuleMember -Function CompareTagGetCommits
	
} -AsCustomObject

$response = $stash.GetCommits()
Write-Host "response is  = $response";

$commits = $response.values;
# | Sort-Object -Property @{Expression={$_.commit.author.date}; Ascending=$false} -Descending

if ($commits -ne $null) {
    foreach ($commit in $commits) {
		$max = $commit.message.length;
		if($max -ge 50){
			$max = 50;
			Write-Host "*** Max = $max";
		}
		$releaseNotes = $releaseNotes + "-- [ " + $commit.message.substring(0,$max) + " ]" + "$global:nl";
		#$releaseNotes = $releaseNotes + "==>[ " + $commit.author.name + " ] " + "ID = " + $commit.author.name + "$global:nl";
		#Write-Host "Inside ForEach $commit";
	}
}
        #$releaseNotes = $releaseNotes + "[" + $commit.sha.Substring(0, 10) + "](https://github.com/$github_owner/$github_repo/commit/" + $commit.sha + ") - " + $commit.commit.message + "<br/>$nl"
		#$releaseNotes = $releaseNotes + "[" + $commit.sha.Substring(0, 10) + "];
	
Write-Host "=======Final Release notes=========";
Write-Host $global:nl $releaseNotes;
Write-Host "===================================";

Write-Host "=========Compare Tag============";
$stash.CompareTagGetCommits("1.1.8","1.1.7");

