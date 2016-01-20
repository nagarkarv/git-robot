#Parameters to be received from TeamCity
param(
	[parameter(Mandatory=$false)] [string]$stashprojectname = "ATH/repos/athena",
    [parameter(Mandatory=$false)] [string]$buildcounter,
    [parameter(Mandatory=$false)] [string]$fromtag = "1.1.8",
    [parameter(Mandatory=$false)] [string]$totag = "1.1.7"
)

$global:stashBaseUrl = "https://stash.euromoneydigital.com/rest/api/1.0/projects/";
$global:stash_username = "vikram.nagarkar";
$global:stash_password = "Vikram@2016";

$global:fromtag = $fromtag;
$global:totag = $totag;

$global:projectName = $stashprojectname;
#$global:nl = [Environment]::NewLine;
$global:nl = " ";
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
				#$releaseNotes = $releaseNotes + "-- [ " + $commit.message.substring(0,$max) + " ]" + "$global:nl";
				$releaseNotes = $releaseNotes + "-- " + $commit.message.substring(0,$max) + " " + "$global:nl";
				$releaseNotes = $releaseNotes.replace('\','_');
				$releaseNotes = $releaseNotes.replace('/','_');
				
				#$releaseNotes = $releaseNotes + "==>[ " + $commit.author.name + " ] " + "ID = " + $commit.author.name + "$global:nl";
			}
		}
		#$releaseNotes = $releaseNotes + "[" + $commit.sha.Substring(0, 10) + "](https://github.com/$github_owner/$github_repo/commit/" + $commit.sha + ") - " + $commit.commit.message + "<br/>$nl"
		#$releaseNotes = $releaseNotes + "[" + $commit.sha.Substring(0, 10) + "];
			
		Write-Host "=======Final Release notes=========" -foreground blue;
		Write-Host $global:nl $releaseNotes -foreground Green;
		Write-Host "===================================" -foreground blue;
		return $releaseNotes;
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
	return $stash.GenerateReleaseNotes();
}

Function GenerateReleaseNotesBetweenTags()
{
	Write-Host "========= Compare Tag ============";
	$response = $stash.GetCommitsBetweenTags();
	$global:commits = $response.values;
	return $stash.GenerateReleaseNotes();
}

Function GenerateReleaseNotesFromSHA()
{
	Write-Host "========= Compare SHA ============";
	#$response = $stash.GetCommitsBetweenGitSHA("af30d3b0d0a", "815f7cb5958");
	$response = $stash.GetCommitsBetweenGitSHA("refs/tags/1.1.7", "815f7cb5958");
	$global:commits = $response.values;
	return $stash.GenerateReleaseNotes();
}

Function Main()
{
	#GenerateReleaseNotesForLatestCommit;
	#GenerateReleaseNotesBetweenTags;
	$notes = GenerateReleaseNotesFromSHA;
	$notes = $notes.replace('\','_');
	$notes = $notes.replace('''','_');
	$notes = $notes.replace([Environment]::NewLine,' ');
	#Set-TeamCity-Parameter "ReleaseNotes" "$notes.substring(0,20)";
	Write-Host "Final Notes being set is ------ ==> $notes";
	#Set-TeamCity-Parameter "ReleaseNotes" "$notes";
	Set-TeamCity-Parameter "ReleaseNotes" "-- Merge branch release_1.1.8 -- remove awards link, copied sitecore jade file to s  -- IIATHENA-2443 - Merged into develop - Cookie Contr  -- added class to handle IE9 cookie control closing  -- IIATHENA-2573 - Merged into develop - Add ManagCom  -- IIATHENA-2577 - Merged into develop - Social icons  --" + [Environment]::NewLine + "IIATHENA-2586 - Merged into develop - GA tracking  -- rebuilding it  -- fixed typos  -- added create index GA tag  -- Ran BuildAll  -- 2577 - Fixed position of social sharing  -- Merge latest develop into branch  -- Merge branch develop into feature_IIATHENA-2586 - END";
	$teamcity_version = "%build.counter%";
	Write-Host "*** FIRST - Team City Parameter build.number - $teamcity_version" 
	Get-TeamCity-Parameter "build.counter" $teamcity_version;
	Write-Host "*** SECOND - Team City Parameter build.number - $teamcity_version" 
	$projectName = "%Octopus.Project%";
	Write-Host "Project name is $projectName";
	
}

function Set-TeamCity-Parameter($name, $value) {
    Write-Host "Setting TC Parameter"
	Write-Host "##teamcity[setParameter name='$name' value='$value']"
	#Ref https://gist.github.com/mbenford/e306ff83ff0a70799e14 	
}

function Get-TeamCity-Parameter($name, $value) {
    Write-Host "Getting TC Parameter"
	Write-Host "##teamcity[getParameter name='$name' value='$value']"
	#Ref https://gist.github.com/mbenford/e306ff83ff0a70799e14 	
}

Main;

Set-TeamCity-Parameter "test" "OK"
#Set-TeamCity-Parameter "ReleaseNotes" "Vikram"


<#
Get Latest Release deployed in Octopus from Within TeamCity

$octopusProject = '%octopus.project.name%'
$environment = '%octopus.environment.target%'

$octoExe = '%teamcity.tool.OctopusTools%\Octo.exe'
$deployments = &$octoExe list-latestdeployments --project="$octopusProject" --server=%octopus.server.url% --apikey=%octopus.api.key% --environment="$environment"
$latestVersion = $deployments | Where { $_.Contains('Version:') } | Select -First 1
if ($latestVersion)
{
    Write-Host ("##teamcity[setParameter name='octopus.deployment.latest' value='{0}']" -f $latestVersion.Split(':')[1].Trim())
}
#>

<# Sample to add release notes to nuspec

param(   
    [Parameter(Mandatory = $true, HelpMessage="NuSpec filepath")]    
    [System.String]$nuspecFilePath
    )
 
[string]$currentBranch = git rev-parse --abbrev-ref HEAD
[string]$latestTag = git describe --abbrev=0 --tags
 
# Check for release branch
if($currentBranch.StartsWith('release/') -or $currentBranch.StartsWith('hotfix/')){
 
    Write-Output "Current $currentBranch"
    Write-Output "Tag $latestTag"
 
    $cmd = "git log --no-merges --pretty=format:""* %h - %s __[%an]__"" $latestTag..$currentBranch"
    $log = Invoke-Expression $cmd  
 
    if($log){  
        [string]$temp = $log
        $formatted = $temp
        Write-Output "Release notes:"
        Write-Output "----------------------------------"
        Write-Output $formatted.Replace(" * ", "`n* ")
        Write-Output "----------------------------------"       
    }
 
    #get nuspec file path
    $path = $nuspecFilePath
        
    if($path){
       [xml]$xml = Get-Content $path
       $parentNode = $xml.SelectSingleNode("//metadata")  
        $node = $xml.SelectSingleNode("//releaseNotes")        
        
        # remove existing releasenotes node
        if ($node -ne $null) {
            $parentNode = $node.ParentNode         
            $node.ParentNode.RemoveChild($node)
        } 
 
        # create new node
        $relNotes = $xml.CreateElement('releaseNotes')
        $relNotes.InnerText = $formatted.Replace(" * ", "`n* ")
        $parentNode.AppendChild($relNotes)
        
        # save nuspec file
        $xml.Save($path)
            
        Write-Output "NuSpec updated"
        
    } else {
        Write-Output "NuSpec file not found"
    }
}
#>

<#

<#
.Synopsis
Loads TeamCity system build properties into the current scope
Unless forced, doesn't do anything if not running under TeamCity
# >
param(
    $prefix = 'TeamCity.',
    $file = $env:TEAMCITY_BUILD_PROPERTIES_FILE + ".xml",
    [switch] $inTeamCity = (![String]::IsNullOrEmpty($env:TEAMCITY_VERSION))
)

if($inTeamCity){
    Write-Host "Loading TeamCity properties from $file"
    $file = (Resolve-Path $file).Path;

    $buildPropertiesXml = New-Object System.Xml.XmlDocument
    $buildPropertiesXml.XmlResolver = $null; # force the DTD not to be tested
    $buildPropertiesXml.Load($file);
    $buildProperties = @{};
    foreach($entry in $buildPropertiesXml.SelectNodes("//entry")){
        $key = $entry.key;
        $value = $entry.'#text';
        $buildProperties[$key] = $value;
        $key = $prefix + $key;

        Write-Verbose ("[TeamCity] Set {0}={1}" -f $key,$value);
        Set-Variable -Name:$key -Value:$value -Scope:1; # variables are loaded into parent scope
    }
}
#>
