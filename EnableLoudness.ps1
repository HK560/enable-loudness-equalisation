<#
.SYNOPSIS
    Automatically adds and enables loudness equalisation to any playback device.
.DESCRIPTION
    Imports registry keys to add enhancement features and enables loudness equalisation.
    It restarts audio service to apply imported registry settings.
.LINK
    https://github.com/HK560/enable-loudness-equalisation
.PARAMETER playbackDeviceName
    Searches for Audio Device Names starting with or containing this String. If omitted, prompts user to select from active devices.
.PARAMETER maxDeviceCount
    Limits the amount of devices to be configured.
.PARAMETER releaseTime
    Time until audio level is adjusted: from "2" (fast adjustment) up to "7" (slow adjustment).
.EXAMPLE
    PS> .\EnableLoudness.ps1
    Prompts user to select from current active audio output devices.
.EXAMPLE
    PS> .\EnableLoudness.ps1 -playbackDeviceName BE279
    Enables loudness equalisation for Audio Device matching BE279.
.EXAMPLE
    PS> .\EnableLoudness.ps1 -releaseTime 2
    Sets shortest possible time until audio level is adjusted.
#>

Param(
   [Parameter(Mandatory=$false, HelpMessage='Which Playback Device Name should be configured? If omitted, you will be prompted to select.')]
   [ValidateLength(1,100)]
   [string]$playbackDeviceName,
   
   [ValidateRange(1, 10)]
   [int]$maxDeviceCount=2,

   [ValidateRange(2, 7)]
   [int]$releaseTime=4
)

Add-Type -AssemblyName System.Windows.Forms
function exitWithErrorMsg ([String] $msg){
    [void][System.Windows.Forms.MessageBox]::Show($msg, $PSCommandPath,
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Error)
    Write-Error $msg
    exit 1
}

function importReg ([String] $file){
    $startprocessParams = @{
        FilePath     = "$Env:SystemRoot\REGEDIT.exe"
        ArgumentList = '/s', $file
        Verb         = 'RunAs'
        PassThru     = $true
        Wait         = $true
    }
    $proc = Start-Process @startprocessParams
    If($? -eq $false -or $proc.ExitCode -ne 0) {
        exitWithErrorMsg "Failed to import $file"
    }
}

function Get-ActiveAudioRenderDevices {
    $friendlyNameKey = "{a45c254e-df1c-4efd-8020-67d146a850e0},2"
    $deviceDescKey   = "{b3f8fa53-0004-438e-9003-51a46e139bfc},6"
    $renderPath      = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render"
    
    if (-not (Test-Path $renderPath)) {
        exitWithErrorMsg "Script does not have access to MMDevices registry path. Try running as Administrator."
    }

    $renderDevices = Get-ChildItem $renderPath -ErrorAction Ignore
    if ($null -eq $renderDevices -or $renderDevices.Count -eq 0) {
        return @()
    }

    $result = @()
    foreach ($devKey in $renderDevices) {
        $devItem = Get-ItemProperty $devKey.PSPath -ErrorAction Ignore
        # DeviceState eq 1 represents active state (DEVICE_STATE_ACTIVE)
        if ($devItem -and $devItem.DeviceState -eq 1) {
            $propPath = Join-Path $devKey.PSPath "Properties"
            $props = Get-ItemProperty -Path $propPath -ErrorAction Ignore
            
            $friendlyName = $null
            $deviceDesc   = $null

            if ($props) {
                if ($props.PSObject.Properties[$friendlyNameKey]) {
                    $friendlyName = $props.$friendlyNameKey
                }
                if ($props.PSObject.Properties[$deviceDescKey]) {
                    $deviceDesc = $props.$deviceDescKey
                }
            }

            # Filter invisible/non-printable control characters
            if ($friendlyName -and $friendlyName -match "^\s*[\x00-\x1F\x7F-\x9F\uFFFD]*\s*$") {
                $friendlyName = $null
            }
            if ($deviceDesc -and $deviceDesc -match "^\s*[\x00-\x1F\x7F-\x9F\uFFFD]*\s*$") {
                $deviceDesc = $null
            }

            # Format display name with interface name and original hardware description
            if ($friendlyName -and $deviceDesc -and ($friendlyName -ne $deviceDesc)) {
                $displayName = "$friendlyName ($deviceDesc)"
            } elseif ($friendlyName) {
                $displayName = $friendlyName
            } elseif ($deviceDesc) {
                $displayName = $deviceDesc
            } else {
                $displayName = "Unknown Audio Device ($($devKey.PSChildName))"
            }

            $result += [PSCustomObject]@{
                PSPath         = $devKey.PSPath
                PropertiesPath = $propPath
                Name           = $displayName
                FriendlyName   = $friendlyName
                DeviceDesc     = $deviceDesc
                Id             = $devKey.PSChildName
                DeviceItem     = $devItem
            }
        }
    }
    return $result
}

$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$regFile = "$env:temp\SoundEnhancementsTMP.reg"
$enhancementFlagKey = "{fc52a749-4be9-4510-896e-966ba6525980},3"
$releaseTimeKey = "{9c00eeed-edce-4cd8-ae08-cb05e8ef57a0},3"
$enhancementTabKey = "{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},3"
$enhancementTabValue = "{5860E1C5-F95C-4a7a-8EC8-8AEF24F379A1}"
$releaseTimeStr = $releaseTime.ToString().PadLeft(2,'0')
$fxPropertiesImport = @"
"{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},1"="{62dc1a93-ae24-464c-a43e-452f824c4250}" ;PreMixEffectClsid activates effects
"{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},2"="{637c490d-eee3-4c0a-973f-371958802da2}" ;PostMixEffectClsid activates effects
"{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},3"="{5860E1C5-F95C-4a7a-8EC8-8AEF24F379A1}" ;UserInterfaceClsid shows it in ui
"{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},5"="{62dc1a93-ae24-464c-a43e-452f824c4250}" ;StreamEffectClsid
"{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},6"="{637c490d-eee3-4c0a-973f-371958802da2}" ;ModeEffectClsid
"{fc52a749-4be9-4510-896e-966ba6525980},3"=hex:0b,00,00,00,01,00,00,00,ff,ff,00,00 ;enables loudness equalisation
"{9c00eeed-edce-4cd8-ae08-cb05e8ef57a0},3"=hex:03,00,00,00,01,00,00,00,$releaseTimeStr,00,00,00 ;equalisation release time 2 to 7
"@

# Display Banner
Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "           Enable Loudness Equalization Tool" -ForegroundColor Yellow
Write-Host "  Original Author : Falcosc (https://github.com/Falcosc)" -ForegroundColor Gray
Write-Host "  Modified By     : HK560" -ForegroundColor Gray
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""

# Fetch active audio output devices
$activeDevices = Get-ActiveAudioRenderDevices
if ($activeDevices.Count -eq 0) {
    exitWithErrorMsg "No active audio output devices found. Please check your audio hardware or run as Administrator."
}

$selectedDevices = @()

if (-not [string]::IsNullOrWhitespace($playbackDeviceName)) {
    # Match specified device name keyword
    $selectedDevices = @($activeDevices | Where-Object { $_.Name -like "*$playbackDeviceName*" -or $_.FriendlyName -like "*$playbackDeviceName*" -or $_.DeviceDesc -like "*$playbackDeviceName*" })
    if ($selectedDevices.Count -eq 0) {
        # Fallback search in all device properties
        foreach ($dev in $activeDevices) {
            $props = Get-ItemProperty -Path $dev.PropertiesPath -ErrorAction Ignore
            if ($props) {
                foreach ($pName in $props.PSObject.Properties.Name) {
                    if ($props.$pName -like "*$playbackDeviceName*") {
                        $selectedDevices += $dev
                        break
                    }
                }
            }
        }
    }
    if ($selectedDevices.Count -eq 0) {
        exitWithErrorMsg "Could not find any active audio device matching '$playbackDeviceName'."
    }
} else {
    # Display interactive selection menu
    Write-Host "==================== Active Audio Devices ====================" -ForegroundColor Cyan
    for ($i = 0; $i -lt $activeDevices.Count; $i++) {
        Write-Host " [$($i + 1)] $($activeDevices[$i].Name)" -ForegroundColor Green
    }
    Write-Host "==============================================================" -ForegroundColor Cyan

    if ($activeDevices.Count -eq 1) {
        Write-Host "Single active audio device detected. Automatically selected: $($activeDevices[0].Name)" -ForegroundColor Yellow
        $selectedDevices = @($activeDevices[0])
    } else {
        $selectionIndex = -1
        while ($selectionIndex -lt 0 -or $selectionIndex -ge $activeDevices.Count) {
            $inputVal = Read-Host "Select an audio device to enable Loudness Equalization (1-$($activeDevices.Count))"
            if ($inputVal -match "^\d+$") {
                $idx = [int]$inputVal - 1
                if ($idx -ge 0 -and $idx -lt $activeDevices.Count) {
                    $selectionIndex = $idx
                }
            }
            if ($selectionIndex -lt 0 -or $selectionIndex -ge $activeDevices.Count) {
                Write-Host "Invalid input. Please enter a valid number between 1 and $($activeDevices.Count)." -ForegroundColor Red
            }
        }
        $selectedDevices = @($activeDevices[$selectionIndex])
        Write-Host "Selected Device: $($selectedDevices[0].Name)" -ForegroundColor Green
    }
}

if ($selectedDevices.Count -gt $maxDeviceCount) {
    exitWithErrorMsg "Execution aborted: Number of matched devices exceeds max limit ($maxDeviceCount)."
}

$missingLoudness = $false
"Windows Registry Editor Version 5.00" > $regFile
$selectedDevices | ForEach-Object {
    $cleanPath = $_.PSPath.Replace("Microsoft.PowerShell.Core\Registry::", "")
    $fxKeyPath = Join-Path -Path $cleanPath -ChildPath FxProperties
    $fxProperties = Get-ItemProperty -Path "Registry::$fxKeyPath" -ErrorAction Ignore
    if (($fxProperties -eq $null) -or ($fxProperties.$enhancementFlagKey -eq $null) -or 
        ($fxProperties.$enhancementFlagKey[8] -ne 255) -or ($fxProperties.$enhancementFlagKey[9] -ne 255) -or
        ($fxProperties.$releaseTimeKey -eq $null) -or ($fxProperties.$releaseTimeKey[8] -ne $releaseTime) -or
        ($fxProperties.$enhancementTabKey -eq $null) -or ($fxProperties.$enhancementTabKey -ne $enhancementTabValue)) {
        "[" + $fxKeyPath + "]" >> $regFile
        $fxPropertiesImport >> $regFile
        $missingLoudness = $true
    }
    if ($fxProperties -eq $null) {
        Write-Host "FxProperties registry key missing at '$fxKeyPath'" -ForegroundColor Red
        Write-Host "Your audio driver package might not include effect extensions." -ForegroundColor Yellow
    }
}

if (!$missingLoudness) {
    Write-Host "Loudness Equalization is already enabled for the selected device. No action needed." -ForegroundColor Green
    Start-Sleep -Seconds 3
    exit 0
}

# Privilege elevation check
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $targetName = $selectedDevices[0].Name
    Write-Host "Administrator rights required. Requesting elevation..." -ForegroundColor Yellow
    $arguments = "-File `"$($myInvocation.MyCommand.Definition)`" -playbackDeviceName `"$targetName`" -maxDeviceCount $maxDeviceCount -releaseTime $releaseTime"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    exit
}

Write-Host "Importing loudness equalization settings into registry..." -ForegroundColor Cyan
importReg $regFile

Write-Host "Restarting Windows Audio service (audiosrv) to apply settings..." -ForegroundColor Cyan
Restart-Service audiosrv -Force
Write-Host "Loudness Equalization has been successfully enabled!" -ForegroundColor Green
