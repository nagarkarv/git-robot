$teamcity_buildcounter = "%build.counter%";
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

