#Parameters to be received from TeamCity
param(
	[parameter(Mandatory=$false)] [string]$stashprojectname = "ATH/repos/athena",
    [parameter(Mandatory=$false)] [string]$buildcounter,
    [parameter(Mandatory=$false)] [string]$fromtag = "1.1.8",
    [parameter(Mandatory=$false)] [string]$totag = "1.1.7"
)

$global:stashBaseUrl = "xx";
$global:stash_username = "xx";
$global:stash_password = "xx";

$global:fromtag = $fromtag;
$global:totag = $totag;

$global:projectName = $stashprojectname;
$global:nl = [Environment]::NewLine;
$global:commits = $null;
Write-Host "Trying connecting to Stash..." -foreground Green
# ---------------
# Connect to Stash using powershell API #
# ---------------
$stash = New-Module -ScriptBlock {
	Function GetCommitsBetweenGitSHA(){
	param([string] $sinceSHA, [string] $untilSHA)
		try{
			$url = "$global:stashBaseUrl" + "$global:projectName" + "/commits?since=$sinceSHA&until=$untilSHA";
			Write-Host "*********** Commits From SHA - Unitl( $sinceSHA, $untilSHA )*************" -foreground Green;
			
			$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $global:stash_username,$global:stash_password)))
			return Invoke-RestMethod -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Uri $url -Verbose 
		}catch {
			Write-Host "Execption: $_.Exception.Response";
		}		
	}

	Function GetCommitsBetweenTags{
		try{
			$url = "$global:stashBaseUrl" + "$global:projectName" + "/compare/commits?from=refs/tags/$global:fromtag&to=refs/tags/$global:totag";
			Write-Host "*********** Comparing Tags ( $global:fromtag, $global:totag )*************";
			
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
	
	Function GenerateReleaseNotes(){
		if ($global:commits -ne $null) {
			foreach ($commit in $global:commits) {
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
			
		Write-Host "=======Final Release notes=========" -foreground blue;
		Write-Host $global:nl $releaseNotes -foreground Green;
		Write-Host "===================================" -foreground blue;
	}
	
	Export-ModuleMember -Function GetCommits
	Export-ModuleMember -Function GetCommitsBetweenTags
	Export-ModuleMember -Function GetCommitsBetweenGitSHA
	Export-ModuleMember -Function GenerateReleaseNotes
	
} -AsCustomObject

Function GenerateReleaseNotesForLatestCommit()
{
	Write-Host "========= Latest Commits ============";
	$response = $stash.GetCommits()
	$global:commits = $response.values;
	######### | Sort-Object -Property @{Expression={$_.commit.author.date}; Ascending=$false} -Descending
	$stash.GenerateReleaseNotes();
}

Function GenerateReleaseNotesBetweenTags()
{
	Write-Host "========= Compare Tag ============";
	$response = $stash.GetCommitsBetweenTags();
	$global:commits = $response.values;
	$stash.GenerateReleaseNotes();
}

Function GenerateReleaseNotesFromSHA()
{
	Write-Host "========= Compare SHA ============";
	#$response = $stash.GetCommitsBetweenGitSHA("af30d3b0d0a", "815f7cb5958");
	$response = $stash.GetCommitsBetweenGitSHA("refs/tags/1.1.7", "815f7cb5958");
	$global:commits = $response.values;
	$stash.GenerateReleaseNotes();
}

Function Main()
{
	#GenerateReleaseNotesForLatestCommit;
	#GenerateReleaseNotesBetweenTags;
	GenerateReleaseNotesFromSHA;
}

Main;
