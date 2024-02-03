function add_BackupPolicy {
    $ErrorActionPreference = "Stop"

    # JSON File Path
    $AzBackupPolicy_parameter_original = $PSScriptRoot + "\json\parameters_bkpol.json"
    $AzBackupPolicy_parameter_edit = $PSScriptRoot + "\json\parameters_edit.json"
    $AzBackupPolicy_template = $PSScriptRoot + "\json\template_bkpol.json"

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
            Deploy New VM_Backup Policy.

            .DESCRIPTION
            This function creates New VM_Backup Policy.

            .PARAMETER
            This function uses CSV parameters loaded in deploy_AzVm.ps1.

            .EXAMPLE
            NONE. This function is called in "deploy_AzVm.ps1
        #>

        add_ResourceGroup $rsc_rg $location

        if(!($rsc_name)) { break }
        $rsc = Get-AzRecoveryServicesVault -Name $rsc_name -ResourceGroupName $rsc_rg -ErrorAction SilentlyContinue
        if(!($rsc)) { break }
        # Get-AzRecoveryServicesBackupProtectionPolicy
        Write-Host -Object "| --  Azure_Backup_BackupPolicy [ ${policy} ] in [ ${rsc_name} ] --"
        Write-Host -Object "|"
        $vault = Get-AzRecoveryServicesVault -Name $rsc_name -ResourceGroupName $rsc_rg
        $pol = Get-AzRecoveryServicesBackupProtectionPolicy -Name $policy -VaultId $vault.ID  -ErrorAction SilentlyContinue
        if($pol) { 
            Write-Host -Object "| --  Azure_Backup_BackupPolicy [ ${policy} ] already exists." -ForegroundColor "Yellow"
            Write-Host -Object "|"
        } else {
            # Read parameters.json
            try {
                $Get_BackupPolicy_Config = Get-Content $AzBackupPolicy_parameter_original -Raw | ConvertFrom-Json
            } catch {
                Write-Host -Object "| -- Error -- : " + $Error[0] -ForegroundColor Red
                break
            }

            # Edit parameters
            $UtcTime = Get-Date -Date $schedule_runtime
            $JstTime = $UtcTime.AddHours(+9)
            $Get_BackupPolicy_Config.parameters.timeZone = @{value = $timeZone }
            $Get_BackupPolicy_Config.parameters.vaultName = @{value = $rsc_name }
            $Get_BackupPolicy_Config.parameters.instantRpRetentionRangeInDays = @{value = [int]$instantRp }
            $Get_BackupPolicy_Config.parameters.policyName = @{value = $policy }
            $Get_BackupPolicy_Config.parameters.schedule.value.scheduleRunFrequency = $frequency
            $Get_BackupPolicy_Config.parameters.schedule.value.scheduleRunTimes[0] = $JstTime
            if($frequency -eq "Daily") {
                $Get_BackupPolicy_Config.parameters.schedule.value.scheduleRunDays = $null
                $Get_BackupPolicy_Config.parameters.retention.value.weeklySchedule = $null
                $Get_BackupPolicy_Config.parameters.retention.value.dailySchedule.retentionTimes[0] = $JstTime
                $Get_BackupPolicy_Config.parameters.retention.value.dailySchedule.retentionDuration.count = [int]$count
            } elseif($frequency -eq "Weekly") {
                $Get_BackupPolicy_Config.parameters.retention.value.dailySchedule = $null
                $Get_BackupPolicy_Config.parameters.schedule.value.scheduleRunDays[0] = $weekly
                $Get_BackupPolicy_Config.parameters.retention.value.weeklySchedule.daysOfTheWeek[0] = $weekly
                $Get_BackupPolicy_Config.parameters.retention.value.weeklySchedule.retentionTimes[0] = $JstTime
                $Get_BackupPolicy_Config.parameters.retention.value.weeklySchedule.retentionDuration.count = [int]$count
            } else {
                Write-Host -Object "| -- Error --  Invalid ScheduleRunFrequency. Choose [ Daily ] or [ Weekly ]." -ForegroundColor Red
                break ; Write-Host -Object "|"
            }

            # Rewrite parameters_edit.json
            try {
                $Get_BackupPolicy_Config | ConvertTo-Json -Depth 100 | foreach {
                    [System.Text.RegularExpressions.Regex]::Unescape($_)
                } 
                Set-Content $AzBackupPolicy_parameter_edit 
                Write-Host -Object "| BackupPolicy [ ${policy} ] deploying..."
                New-AzResourceGroupDeployment -ResourceGroupName $rsc_rg -TemplateFile $AzBackupPolicy_template -TemplateParameterFile $AzBackupPolicy_parameter_edit
                Remove-Item $AzBackupPolicy_parameter_edit
                Write-Host -Object "|"
            } catch {
                Write-Host -Object "| -- Error -- : " + $Error[0] -ForegroundColor Red
                break ; Write-Host -Object "|"
            }        
        }   
        Write-Host -Object "| - - - - -"
    }
    Write-Host -Object "| function add_BackupPolicy complete."
    Write-Host -Object "|"
}

