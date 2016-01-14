#
# Assumptions
#
# 1. If you have a Octopus release deployed, say 1.0.0.73, there is a git
#    tag set for that commit in GitHub that is "v1.0.0.73".
#
# 2. You have TeamCity label each successful build in GitHub with the format
#    "v{build number}. Sidenote: it appears that TeamCity only labels the
#    default branch, but not feature branches.
#
# 3. Your TeamCity build numbers match your Octopus release versions. For
#    example, if TeamCity runs a build labeled #1.1.0.97, Octopus must
#    have a release called "1.1.0.97"
#
# 4. The latest production deployment will be used for comparison, even
#    if the deployment failed.
#
# 5. If you have no production build, the next highest environment will be used.
#
# 6. Your default branch in TeamCity is "master".
#
# 7. When creating the Octopus release, all Nuget packages use the same
#    version number. You can remove the octo.exe call at the bottom and use
#    the generated releasenotes.txt to perform your own API call to Octopus
#    in a different build step if you wish.
#

#
# Define all necessary variables
# ---------------------------------------------------------
$github_owner = "GITHUB_OWNER"
$github_repo = "GITHUB_REPO"
$github_token = "GITHUB_TOKEN"

$octopus_url = "OCTOPUS_URL"
$octopus_username = "OCTOPUS_USERNAME"
$octopus_password = "OCTOPUS_PASSWORD"
$octopus_apikey = "OCTOPUS_APIKEY"
$octopus_projectName = "OCTOPUS_PROJECTNAME"

$jira_url = "JIRA_URL"
$jira_username = "JIRA_USERNAME"
$jira_password = "JIRA_PASSWORD"

$teamcity_username = "TEAMCITY_USERNAME"
$teamcity_password = "TEAMCITY_PASSWORD"
$teamcity_url = "TEAMCITY_URL"

# These variables are set by TeamCity
$teamcity_buildTypeName = "%system.teamcity.buildConfName%"
$teamcity_buildTypeId = "%system.teamcity.buildType.id%"
$teamcity_buildId = "%teamcity.build.id%"
$teamcity_commitId = "%build.vcs.number.1%"
$teamcity_version = "%build.number%"
$teamcity_branch = "%teamcity.build.branch%"

if ($teamcity_branch -eq "<default>") {
  $teamcity_branch = "master"
}

#
# TeamCity API
# ---------------------------------------------------------
$teamcity = New-Module -ScriptBlock {
    $password = ConvertTo-SecureString -String "$teamcity_password" -AsPlainText -Force
    $credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $teamcity_username, $password
 
    function GetBuild {
        param([string] $buildId)
 
        $url = "$teamcity_url/httpAuth/app/rest/builds/id:$buildId"
 
        return Invoke-RestMethod -Uri $url -Credential $credentials -Verbose -WebSession $session
    }
 
    function GetBuilds {
        param([string] $branch, [string] $sinceBuild)
 
        $url = "$teamcity_url/httpAuth/app/rest/builds/?locator=buildType:$teamcity_buildTypeId,canceled:false,branch:$branch,sinceBuild:$sinceBuild"
        
        return Invoke-RestMethod -Uri $url -Credential $credentials -Verbose -WebSession $session
    }
 
    Export-ModuleMember -Function GetBuild, GetBuilds
 
    # Call the TeamCity API in order to retreive the session variable; otherwise each call is VERY slow.
    Invoke-RestMethod -Uri "$teamcity_url/httpAuth/app/rest/" -Credential $credentials -Verbose -SessionVariable session
} -AsCustomObject
 
#
# JIRA API
# ---------------------------------------------------------
$jira = New-Module -ScriptBlock {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes("$jira_username`:$jira_password")
    $encodedCredentials = [System.Convert]::ToBase64String($bytes)
 
    function GetIssue {
        param([string] $issueId)
 
        return Invoke-RestMethod -Uri "$jira_url/rest/api/latest/issue/$issueId" -Headers @{"Authorization"="Basic $encodedCredentials"} -ContentType application/json -Verbose
    }
 
    Export-ModuleMember -Function GetIssue
} -AsCustomObject
 
#
# GitHub API
# ---------------------------------------------------------
$github = New-Module -ScriptBlock {
    function GetCommits {
        param([string] $base, [string] $head)
 
        $url = "https://api.github.com/repos/$github_owner/$github_repo/compare/" + $base + "..." + $head + "?access_token=$github_token"
        return  Invoke-RestMethod -Uri $url -Verbose
    }
 
    Export-ModuleMember -Function GetCommits
} -AsCustomObject
 
#
# Octopus API
# ---------------------------------------------------------
$octo = New-Module -ScriptBlock {
    $password = ConvertTo-SecureString -String "$octopus_password" -AsPlainText -Force
    $credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $octopus_username, $password
 
    function Get {
        param([string] $url)
 
        return Invoke-RestMethod -Uri $octopus_url$url -ContentType application/json -Headers @{"X-Octopus-ApiKey"="$octopus_apikey"} -Method Get -Credential $credentials -Verbose
    }
 
    function GetProject {
        param([string] $name)
 
        $projects = Get($root.Links.Projects)
 
        foreach ($project in $projects) {
            if ([string]::Compare($project.Name, $name, $true) -eq 0) {
                return $project;
            }
        }
 
        throw "A project named '$name' could not be found."
    }
 
    function GetLatestDeployedRelease {
        param($project)
        
        $environments = Get($root.Links.Environments) 
        $deployments = Get($project.Links.RecentDeployments)
 
        foreach ($env in $environments | Sort-Object SortOrder -descending) {
            foreach ($deployment in $deployments) {
                if ([string]::Compare($env.Id, $deployment.EnvironmentId, $true) -eq 0) {
                    return Get($deployment.Links.Release)
                }
            }
        }
 
        return $null;
    }
 
    Export-ModuleMember -Function GetProject, GetLatestDeployedRelease
 
    $root = Get("/api")
} -AsCustomObject
 
#
# Get all commits from latest deployment to this commit
# ---------------------------------------------------------
Write-Host ("Getting all commits from git tag v" + $release.Version + " to commit sha $teamcity_commitId.")
$project = $octo.GetProject($octopus_projectName)
$release = $octo.GetLatestDeployedRelease($project)
 
$response = $github.GetCommits("v" + $release.Version, $teamcity_commitId)
$commits = $response.commits | Sort-Object -Property @{Expression={$_.commit.author.date}; Ascending=$false} -Descending
 
#
# Get all JIRA issues from latest deployment to this build
# ---------------------------------------------------------
Write-Host "Getting all issues."
$response = $teamcity.GetBuilds($teamcity_branch, $release.Version)
$builds = Select-Xml -Xml $response -XPath "/builds/build" | Select-Object -ExpandProperty Node | Select-Object id,number,status,webUrl
 
$issues = $null
foreach ($build in $builds) {
    $response = $teamcity.GetBuild($build.id)
    $issues = $issues + (Select-Xml -Xml $response -XPath "/build/relatedIssues/issueUsage/issue" | Select-Object -ExpandProperty Node | Select-Object id,url -Unique)
}
$issues = $issues | Sort-Object id -Unique
 
#
# Generate release notes based on commits and issues
# ---------------------------------------------------------
Write-Host "Generating release notes based on commits."
$nl = [Environment]::NewLine
$releaseNotes = 
    "Automatic release created from TeamCity build configuration [$teamcity_buildTypeName]($teamcity_url/viewLog.html?buildTypeId=$teamcity_buildTypeId&buildId=$teamcity_buildId). " +
    "Git version [$teamcity_branch](https://github.com/$github_owner/$github_repo/tree/$teamcity_commitId)" +
    " / [" + $teamcity_commitId.Substring(0, 10) + "](https://github.com/$github_owner/$github_repo/commit/$teamcity_commitId)."
 
$releaseNotes = $releaseNotes + "$nl$nl### All work since Release [" + $release.Version + "](" + $octopus_url + $release.Links.Web + ")<br/>$nl"
 
if ($commits -ne $null) {
    foreach ($commit in $commits) {
        $releaseNotes = $releaseNotes + "[" + $commit.sha.Substring(0, 10) + "](https://github.com/$github_owner/$github_repo/commit/" + $commit.sha + ") - " + $commit.commit.message + "<br/>$nl"
    }
 
    if ($issues -ne $null) {
        $releaseNotes = $releaseNotes + "<br/>$nl"
 
        foreach ($issue in $issues) {
            $jiraIssue = $jira.GetIssue($issue.id)
            $releaseNotes = $releaseNotes + "[" + $issue.id + "](" + $issue.url + ") - " + $jiraIssue.fields.summary + "<br/>$nl"
        }
    }
}
else {
    $releaseNotes = $releaseNotes + "There are no new items for this release.<br/>$nl"
}
 
Write-Host $releaseNotes

#
# Create & Deploy Octopus Release
# -------------------------------
Write-Host "Creating Octopus release for $teamcity_version."

New-Item releasenotes.txt -type file -force -value $releaseNotes
& "f:\Octopus Tools\octo.exe" create-release --project="$octopus_projectName" --server=$octopus_url --apiKey=$octopus_apikey --version=$teamcity_version --packageversion=$teamcity_version --forceversion --releasenotesfile=releasenotes.txt | Write-Host
Remove-Item releasenotes.txt