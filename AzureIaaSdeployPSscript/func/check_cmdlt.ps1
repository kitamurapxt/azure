function check_cmdlt {
    Write-Host "| "
    Write-Host "| Checking if exsists cmdlt..."
    Write-Host "| "
    $cmdlt_all = (Get-Command).Source
    $cmdlt_list = ".\cmdlt.list"
    <#
        .SYNOPSIS
        Check Az Command.

        .DESCRIPTION
        This function checks if the commands listed in cmdlt.list exist.

        .PARAMETER
        This function uses CSV parameters loaded in deploy_AzVm.ps1.

        .EXAMPLE
        NONE. This function is called in "deploy_AzVm.ps1
    #>
    $cmdlt = Get-Content $cmdlt_list
    foreach ($line in $cmdlt) {
        $bln = $cmdlt_all.Contains($line)
        if ($bln) {
            # true
            Write-Host "| -- PASS --  Module [ ${line} ]  installed." -ForegroundColor Green
        } else {
            # false
            Write-Host "| -- ERROR --  Module [ ${line} ] not installed." -ForegroundColor Red
            Write-Host "| Az command must be installed for this script to work." -ForegroundColor Red
            exit
        }
    }
}

