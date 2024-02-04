function enable_BackupProtection {
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
            Enable VM Backup Protection.

            .DESCRIPTION
            This function Enable VM Backup Protection.

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
        if(!($rsc)) { break }
        # Get-AzRecoveryServicesBackupProtectionPolicy
        $vault = Get-AzRecoveryServicesVault -Name $rsc_name -ResourceGroupName $rsc_rg
        $pol = Get-AzRecoveryServicesBackupProtectionPolicy -Name $policy -VaultId $vault.ID  -ErrorAction SilentlyContinue
        if(!($pol)) { break }

        # Set-AzRecoveryServicesBackupProperty
        $vault = Get-AzRecoveryServicesVault -Name $rsc_name -ResourceGroupName $rsc_rg
        $RSC_Redundancy = Get-AzRecoveryServicesBackupProperties -Vault $vault -ErrorAction SilentlyContinue
        while ($RSC_Redundancy -eq $null) {
            Start-Sleep 2
            $RSC_Redundancy = Get-AzRecoveryServicesBackupProperties -Vault $vault -ErrorAction SilentlyContinue
        }
        $Redundancy_type = $RSC_Redundancy.BackupStorageRedundancy
        Write-Host -Object "| RSC [ $RscName ]'s BackupRedundancy [ ${Redundancy_type} ]"
        Write-Host -Object "|"

        $item = Get-AzRecoveryServicesBackupItem -VaultId $vault.ID -BackupManagementType 'AzureVM' -WorkloadType 'AzureVM'
        if(!($item)) {
            # Check BackupStorageRedundancy
            if(!($Redundancy -eq $Redundancy_type)) {
                try{
                    Write-Host -Object "| Changing BackupRedundancy..."
                    # Set BackupStorageRedundancy
                    @(1..5) | %{ Set-AzRecoveryServicesBackupProperty -Vault $vault -BackupStorageRedundancy $Redundancy; (START-SLEEP -m 5000); }
                } catch {
                    Write-Host -Object "| -- Error -- : " + $Error[0] -ForegroundColor Red
                    break
                }
                $vault = Get-AzRecoveryServicesVault -Name $rsc_name -ResourceGroupName $rsc_rg
                $Redundancy_type = (Get-AzRecoveryServicesBackupProperties -Vault $vault).BackupStorageRedundancy
                Write-Host -Object "| Current BackupRedundancy [ ${Redundancy_type} ]"
                Write-Host -Object "|"
            }
        }

        # Enable-AzRecoveryServicesBackupProtection
        $pol = Get-AzRecoveryServicesBackupProtectionPolicy -Name $policy -VaultId $vault.ID
        $recoveryVaultInfo = Get-AzRecoveryServicesBackupStatus -Name $AzVM.Name -ResourceGroupName $AzVM.ResourceGroupName -Type 'AzureVM'
        if ($recoveryVaultInfo.BackedUp -eq $true){
            Write-Host -Object "| VM [ ${vm_name} ] BackupProtection is already Enabled." -ForegroundColor Yellow
        } else {
            $VmName = $AzVM.Name
            $RscName = $vault.Name
            if($AzVM.Location -eq $vault.Location){
                try {
                    Write-Host -Object "| Enable VM [ ${vm_name} ] BackupProtection."
                    Enable-AzRecoveryServicesBackupProtection -Policy $pol -Name $vm_name -ResourceGroupName $vm_rg -VaultId $vault.ID
                    Write-Host -Object "| VM [ ${vm_name} ] BackupProtection Enabled."
                } catch {
                    Write-Host -Object "| -- Error -- : " + $Error[0] -ForegroundColor Red
                    break ; Write-Host -Object "|"
                }
            } else {
                Write-Host -Object "| -- Error --  VM [ $VmName ] and [ $RscName ] must be in the same location." -ForegroundColor Red
                break ; Write-Host -Object "|"
            }
        }    
        Write-Host -Object "| - - - - -"
    }
    Write-Host -Object "| function enable_BackupProtection complete."
    Write-Host -Object "|"
}

