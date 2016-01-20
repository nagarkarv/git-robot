param(
	[string]$projectname
)

# All System configurations are avaliable in the TEAMCITY_BUILD_PROPERTIES_FILE
Function LoadTeamcityProperties()
{
		$file = "$env:TEAMCITY_BUILD_PROPERTIES_FILE";
		Write-Host "##Loading TeamCity properties from $file ##";
		$file = (Resolve-Path $file).Path;
		$buildPropertiesXml = New-Object System.Xml.XmlDocument;
		$buildPropertiesXml.XmlResolver = $null; # force the DTD not to be tested
		Write-Host "File is $file";
		# Loading a XML File
		$xmldoc = Get-Content -Path "$file";
		Write-Host $xmldoc;
		$AppProps = convertfrom-stringdata (Get-Content -Path "$file" -raw);
		$AppProps.Keys | % { "key = $_ , value = " + $AppProps.Item($_) }	
		Write-Host "Branch value is -->" $AppProps["current.branch"];
}

<#$teamcity_buildcounter = "%build.counter%";
Write-Host "env:build_number is 	: $env:build_number";
Write-Host "env:build_vcs_number is : $env:build_vcs_number";
Write-Host "env:PATH = $env:PATH";
Write-Host "env:teamcity.project.name = $env:teamcity_project_name";
Write-Host "env:teamcity.build.branch = $env:teamcity_build_branch";
Write-Host "env:vcsroot.WwwTestCom_WwwTestComGit1.branch = $env:vcsroot_WwwTestCom_WwwTestComGit1_branch";
Write-Host "env:teamcity.build.vcs.branch.WwwTestCom_WwwTestComGit1 = $env:teamcity_build_vcs_branch_WwwTestCom_WwwTestComGit1";
Write-Host "======";
Write-Host "APPDATA = $env:APPDATA";
Write-Host "system.agent.home.dir = $env:agent_home_dir";
Write-Host "system.agent.home.dir = $sys:agent_home_dir";
Write-Host "env.branch = $env:branch";
Write-Host "env.solution.file = $env:solution_file";
Write-Host "env:TEAMCITY_BUILD_PROPERTIES_FILE = $env:TEAMCITY_BUILD_PROPERTIES_FILE";
#>
Write-Host "env:TEAMCITY_BUILD_PROPERTIES_FILE = $env:TEAMCITY_BUILD_PROPERTIES_FILE";

Write-Host "Project name is $env:Octopus_Project";
$project = "%Octopus_Project%";
Write-Host "Project name is $project";
Write-Host "Project name is $projectname";

#$projectName = "%Octopus_Project%";
#Write-Host "Project name with % $projectName";
Write-Host "env.branch = $env:branch";

LoadTeamcityProperties;
