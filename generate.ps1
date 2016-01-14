# ---------------
# Connect to Stash using powershell API #
# ---------------
$stash = New-Module -ScriptBlock {
	Function GetCommits(){
		param([string] $base, [string] $head)
		$stash_password = "xx";
		$stash_username = "xx";
		try{
			#$url = "https://<base>/rest/api/1.0/projects/JIRA/repos/jira-reporting-tool-sql/commits"
			$url = "https://<base>/rest/api/1.0/projects/CQA/repos/euromoney.saucelabs/commits";
			$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $stash_username,$stash_password)))

			return Invoke-RestMethod -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Uri $url -Verbose 
		}catch {
			$_.Exception.Response
		}		
	}
	Export-ModuleMember -Function GetCommits
	
} -AsCustomObject

Write-Host "Connecting to Stash..." -foreground Green
$data = $stash.GetCommits()
Write-Host "Data = $data"
