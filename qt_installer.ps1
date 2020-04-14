$dir=Get-Location

$qtInstallerRootUrl="http://download.qt.io/official_releases/online_installers"
$qtInstallerScriptFile="$dir\control_script.js"

$env:QT_INSTALLER_VARS=".\ci\vars_linux.js"
#$env:QT_INSTALLER_DOWNLOAD_NAME="qt-unified-linux-x64-online.run"
$env:QT_INSTALLER_DOWNLOAD_NAME="qt-unified-windows-x86-online.exe"

function injectVars()
{
    Write-Host "Injecting variables to installer control script"
    Get-Content -Path $env:QT_INSTALLER_VARS | Add-Content -Path $qtInstallerScriptFile
}

# Download Qt installer
function downloadInstaller()
{
    $qtInstallerUrl="$qtInstallerRootUrl/$env:QT_INSTALLER_DOWNLOAD_NAME"
    Write-Host "Downloading the online installer from $qtInstallerUrl"
    #Invoke-WebRequest -Uri $qtInstallerUrl -OutFile $env:QT_INSTALLER_DOWNLOAD_NAME

    $client = New-Object System.Net.WebClient

    try {
        Register-ObjectEvent $client DownloadProgressChanged -action {     
            if ( $eventargs.ProgressPercentage -gt $percent ) {
                $percent = $eventargs.ProgressPercentage
                if ( $start_time -eq $null ) {
                    $start_time = $(get-date)
                }
                # Get the elapsed time since we displayed the last percentage change
                $elapsed_time = new-timespan $start_time $(get-date)
                #write-host "`rPercent complete:" $eventargs.ProgressPercentage "($elapsed_time)" -NoNewline 
                Write-Progress -Activity "Percent complete:" -Status "$eventargs.ProgressPercentage% Complete:" -PercentComplete $eventargs.ProgressPercentage;
            }
        }

        Register-ObjectEvent $client DownloadFileCompleted -SourceIdentifier Finished

        $client.DownloadFileAsync($qtInstallerUrl, "$dir\$env:QT_INSTALLER_DOWNLOAD_NAME")

        # optionally wait, but you can break out and it will still write progress
        Wait-Event -SourceIdentifier Finished

    } finally {
        write-host "File download completed"
        $client.dispose()
        Unregister-Event -SourceIdentifier Finished
        Remove-Event -SourceIdentifier Finished
    }
}

function installOnLinux()
{
 
    $command = "chmod o+x ""$dir\$env:QT_INSTALLER_DOWNLOAD_NAME"""
    Invoke-Expression $command
    $command = "sudo ""${DIR}/${QT_INSTALLER_DOWNLOAD_NAME}"" --verbose --script ""$qtInstallerScriptFile"""
    Invoke-Expression $command
}

function installOnWindows()
{
    $command = "$dir\$env:QT_INSTALLER_DOWNLOAD_NAME --verbose --script $qtInstallerScriptFile"
    Invoke-Expression $command 
}

function installQt()
{
    installOnWindows
}

injectVars
downloadInstaller
installQt
