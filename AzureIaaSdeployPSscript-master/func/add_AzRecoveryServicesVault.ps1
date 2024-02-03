function add_AzRecoveryServicesVault {
    $ErrorActionPreference = "Stop"

    foreach ($param in $backup_csv) {
        $vm_name = $param.vmName
        $vm_rg = $param.vmRg
        $rsc_name = $param.RecoveryServicesName
        $rsc_rg = $param.RecoveryServicesRg
        $policy = $param.policyName
        $frequency = $param.scheduleRunFrequency
        $schedule_runtime = $param.scheduleRunTimes
        $instantRp = $param.instantRpRetentionRangeInDays
        $count = $param.count
        $weekly = $param.weeklySchedule
        $timezone = $param.timeZone
        $Redundancy = $param.Redundancy
        <#
            .SYNOPSIS
            Deploy New RecoveryServicesVault.

            .DESCRIPTION
            This function creates New RecoveryServicesVault.

            .PARAMETER
            This function uses CSV parameters loaded in deploy_AzVm.ps1.

            .EXAMPLE
            NONE. This function is called in "deploy_AzVm.ps1
        #>

        $AzVM = Get-AzVM -Name $vm_name -ResourceGroupName $vm_rg -ErrorAction SilentlyContinue
        if(!($AzVM)) {
            Write-Host -Object "| -- Error --  VM [ ${vm_name} ] not found." -ForegroundColor Red
            Write-Host -Object "|" ; break
        }

        add_ResourceGroup $rsc_rg $location

        if(!($rsc_name)) { break }
        $rsc = Get-AzRecoveryServicesVault -Name $rsc_name -ResourceGroupName $rsc_rg -ErrorAction SilentlyContinue
        if(!($rsc)) {
            Write-Host -Object "| Azure_Backup [ ${rsc_name} ] "
            Write-Host -Object "|"
                Write-Host -Object "| RecoveryServicesVault [ ${rsc_name} ] deploying..."
            New-AzRecoveryServicesVault -Name $rsc_name -ResourceGroupName $rsc_rg -Location $AzVM.Location
        }        
        Write-Host -Object "| RSC ResourceID: "
        Write-Host "|"(Get-AzRecoveryServicesVault -Name $rsc_name -ResourceGroupName $rsc_rg).Id
        Write-Host -Object "|"
    }
    Write-Host -Object "| function add_AzRecoveryServicesVault complete."
    Write-Host -Object "|"
}

