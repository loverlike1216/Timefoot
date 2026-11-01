param(
    [string]$VivadoBin = 'D:\Vivado\2025.2\2025.2\Vivado\bin',
    [switch]$IncludeImplementation
)
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'PowerShell 7 is required'}
$EvaluationRoot=[IO.Path]::GetFullPath($PSScriptRoot)
if((Get-Item -LiteralPath $EvaluationRoot).Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Reparse root requires review'}
$ReplayRoot=[IO.Path]::GetFullPath((Join-Path $EvaluationRoot ('.work\replay_'+(Get-Date -Format 'yyyyMMdd_HHmmss_fff'))))
$Relative=[IO.Path]::GetRelativePath($EvaluationRoot,$ReplayRoot)
if($Relative.StartsWith('..') -or [IO.Path]::IsPathRooted($Relative)){throw 'Replay boundary violation'}
if(-not(Test-Path -LiteralPath (Join-Path $VivadoBin 'xsim.bat'))){throw 'Vivado/XSIM installation not found'}
New-Item -ItemType Directory -Path $ReplayRoot | Out-Null
Copy-Item -LiteralPath (Join-Path $EvaluationRoot 'simulation') -Destination $ReplayRoot -Recurse
foreach($d in @('.work\tmp','evidence\environment','evidence\simulation_logs','evidence\waveforms','evidence\timing_reports','evidence\resource_reports')){
    New-Item -ItemType Directory -Path (Join-Path $ReplayRoot $d) -Force | Out-Null
}
Copy-Item -LiteralPath (Join-Path $EvaluationRoot 'evidence\environment\source_manifest.json') -Destination (Join-Path $ReplayRoot 'evidence\environment\source_manifest.json')
$env:TIMEFOOT_VIVADO_BIN=$VivadoBin
$env:TMP=Join-Path $ReplayRoot '.work\tmp';$env:TEMP=$env:TMP
$env:PYTHONIOENCODING='utf-8'
$TaskPython=Join-Path $EvaluationRoot '.work\venv\Scripts\python.exe'
if(-not(Test-Path -LiteralPath $TaskPython)){$TaskPython=(Get-Command python -ErrorAction Stop).Source}
Push-Location -LiteralPath $ReplayRoot
try{
    & $TaskPython '.\simulation\reference_model\experiments.py' *> '.\evidence\simulation_logs\reference_driver.log'
    if($LASTEXITCODE -ne 0){throw 'Reference-model validation failed'}
    foreach($tag in @('finalE','finalF')){
        & $TaskPython '.\simulation\scripts\run_xsim.py' --tag $tag *> ('.\evidence\simulation_logs\'+$tag+'_driver.log')
        if($LASTEXITCODE -ne 0){throw "Simulation failed: $tag"}
    }
    & $TaskPython '.\simulation\scripts\verify_evidence.py' *> '.\evidence\simulation_logs\verify_evidence.log'
    if($LASTEXITCODE -ne 0){throw 'Evidence cross-check failed'}
    if($IncludeImplementation){
        foreach($script in @('probe_vivado','build_ooc','pin_routing')){
            & (Join-Path $VivadoBin 'vivado.bat') -mode batch -source ('.\simulation\scripts\'+$script+'.tcl') -log ('.\evidence\environment\'+$script+'.log') -journal ('.\evidence\environment\'+$script+'.jou') *> ('.\evidence\environment\'+$script+'_launcher.log')
            if($LASTEXITCODE -ne 0){throw "Vivado flow failed: $script"}
        }
    }
    Write-Output "Replay evidence: $ReplayRoot\evidence"
    Write-Output 'Simulation PASS does not imply CDC, pin-output STA, electrical or hardware acceptance.'
}finally{Pop-Location}
