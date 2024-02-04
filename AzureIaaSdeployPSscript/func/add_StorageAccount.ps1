function add_StorageAccount {
    foreach ($line in $storage_csv) {
        $storageAccount = $line.storageName
        $storageResourceGroup = $line.storageResourceGroup
        $location = $line.location
        $sku = $line.sku
        $vmNames = $line.bootdiag_vmNames.Split(";")
        $vmRGs = $line.vmResourceGroups.Split(";")
        $nsgNames = $line.flowlog_nsgs.Split(";")
        $nsgRGs = $line.nsgResourceGroups.Split(";")
        $retentions = $line.RetentionInDays.Split(";")
        <#
            .SYNOPSIS
            Deploy New StorageAccount.

            .DESCRIPTION
            This function creates New StorageAccount, Set VM BootDiag and NSG FlowLog.

            .PARAMETER
            This function uses CSV parameters loaded in deploy_AzVm.ps1.

            .EXAMPLE
            NONE. This function is called in "deploy_AzVm.ps1
        #>
        if (!($storageAccount)) { $storageAccount = "-" }

        # VM BOOT DIAGNOSTICS with Managed Storage Account
        if ($storageAccount -eq "-") {
            $vm_num = 0
            foreach ($vmName in $vmNames) {
                if(!($vmName)){ break }
                Write-Host -Object "| Set-AzVMBootDiagnostic [ ${vmName} ] with Managed Storage Account"
                Write-Host -Object "|"
                $vm = Get-AzVM -Name $vmName -resourceGroup $vmRGs[$vm_num] -ErrorAction SilentlyContinue
                if (!($vm)) {
                    Write-Host -Object "| -- Error -- VM [ ${vmName} ] not found." -ForegroundColor "Red"
                    break ; Write-Host -Object "|"
                }
                $vm.DiagnosticsProfile.BootDiagnostics.Enabled=$true                
                Update-AzVM -VM $vm -ResourceGroupName $vmRGs[$vm_num] -AsJob | Out-Null
                Get-Job | Wait-Job | Out-Null
                if (Get-Job -State Failed) {
                    Write-Host -Object "| -- Error -- some jobs failed as follows:" -ForegroundColor "Red" ; (Get-Job -State Failed).Error
                    Get-Job | Remove-Job | Out-Null
                    break ; Write-Host -Object "|"
                }
                Get-Job | Remove-Job | Out-Null
                Write-Host -Object "| BootDiagnosticSettings: "
                (Get-AzVM -Name $vmName -resourceGroup $vmRGs[$vm_num]).DiagnosticsProfile.BootDiagnostics
                Write-Host -Object "|"
                $vm_num ++ ; Start-Sleep 1
                Write-Host -Object "| - - - - -"
            }
        } else {
            # Function call. Create resource group if it does not exist.
            add_ResourceGroup $storageResourceGroup $location

            $storage = Get-AzStorageAccount -AccountName $storageAccount -ResourceGroup $storageResourceGroup -ErrorAction SilentlyContinue
            # Check if STORAGEACCOUNT exist.
            if (!($storage)) {
                $fqdn = "https://" + $storageAccount + ".blob.core.windows.net"
                try {
                    $url = curl $fqdn
                    if ($url) {
                        Write-Host -Object "| -- Error -- ${storageAccount} is not available. StorageAccountName must be unique." -ForegroundColor "Red"
                        break ; Write-Host -Object "|"
                    }
                } catch {
                    Write-Host -Object "| Azure_Storage_Account [ $storageAccount ]"
                    Write-Host -Object "|"
                    Write-Host -Object "| STORAGE [ ${storageAccount} ] deploying..."
                    New-AzStorageAccount -AccountName $storageAccount -resourceGroup $storageResourceGroup -Location $location -SkuName $sku -AsJob | Out-Null
                }
                Get-Job | Wait-Job | Out-Null
                if (Get-Job -State Failed) {
                    Write-Host -Object "| -- Error -- some jobs failed as follows:" -ForegroundColor "Red" ; (Get-Job -State Failed).Error
                    Get-Job | Remove-Job | Out-Null
                    break ; Write-Host -Object "|"
                }
                Get-Job | Remove-Job | Out-Null
                $storage = Get-AzStorageAccount -AccountName $storageAccount -ResourceGroup $storageResourceGroup -ErrorAction SilentlyContinue
                Write-Host -Object "| STORAGE ResourceID: "
                Write-Host "|"$storage.Id
            } else {
                Write-Host -Object "| STORAGE [ ${storageAccount} ] already exists." -ForegroundColor "Yellow"
            }
            Write-Host -Object "|"

            # VM BOOT DIAGNOSTICS with Custom Storage Account
            $vm_num = 0
            foreach ($vmName in $vmNames) {
                if(!($vmName)){ break }
                Write-Host -Object "| Set-AzVMBootDiagnostic [ ${vmName} ] with Custom Storage Account"
                Write-Host -Object "|"
                $vm = Get-AzVM -Name $vmName -resourceGroup $vmRGs[$vm_num] -ErrorAction SilentlyContinue
                if (!($vm)) {
                    Write-Host -Object "| -- Error -- VM [ ${vmName} ] not found." -ForegroundColor "Red"
                    break ; Write-Host -Object "|"
                }
                Set-AzVMBootDiagnostic -VM $vm -Enable -ResourceGroupName $storageResourceGroup -StorageAccountName $storageAccount
                Update-AzVM -VM $vm -ResourceGroupName $vmRGs[$vm_num] -AsJob | Out-Null
                Get-Job | Wait-Job | Out-Null
                if (Get-Job -State Failed) {
                    Write-Host -Object "| -- Error -- some jobs failed as follows:" -ForegroundColor "Red" ; (Get-Job -State Failed).Error
                    Get-Job | Remove-Job | Out-Null
                    break ; Write-Host -Object "|"
                }
                Get-Job | Remove-Job | Out-Null
                Write-Host -Object "| BootDiagnosticSettings: "
                (Get-AzVM -Name $vmName -resourceGroup $vmRGs[$vm_num]).DiagnosticsProfile.BootDiagnostics
                Write-Host -Object "|"
                $vm_num ++ ; Start-Sleep 1
            }
        }

        # NSG FLOWLOG
        $nsg_num = 0
        foreach ($nsgName in $nsgNames) {
            if(!($nsgName)){ break }
            # Check if NSG exist.
            Write-Host -Object "| Set-AzNetworkWatcherConfigFlowLog [${nsgName}]"
            Write-Host -Object "|"
            $nsg = Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $nsgRGs[$nsg_num] -ErrorAction SilentlyContinue
            if (!($nsg)) {
                Write-Host -Object "| -- Error --  NSG [ ${nsgName} ] not found." -ForegroundColor "Red"
                break ; Write-Host -Object "|"
            }
            $NwWatcher = "NetworkWatcher_" + $location
            $NW = Get-AzNetworkWatcher -ResourceGroupName NetworkWatcherRg -Name $NwWatcher
            Set-AzNetworkWatcherConfigFlowLog -NetworkWatcher $NW -TargetResourceId $nsg.Id -EnableFlowLog $true `
            -StorageAccountId $storage.Id -EnableRetention $true -RetentionInDays $retentions[$nsg_num] -FormatVersion 2 -AsJob | Out-Null

            Get-Job | Wait-Job | Out-Null
            if (Get-Job -State Failed) {
                Write-Host -Object "| -- Error -- some jobs failed as follows:" -ForegroundColor "Red" ; (Get-Job -State Failed).Error
                Get-Job | Remove-Job | Out-Null
                break ; Write-Host -Object "|"
            }
            Get-Job | Remove-Job | Out-Null
            Write-Host -Object "| FlowLogSettings: "
            $NW = Get-AzNetworkWatcher -ResourceGroupName NetworkWatcherRg -Name $NwWatcher
            Get-AzNetworkWatcherFlowLogStatus -NetworkWatcher $NW -TargetResourceId $nsg.Id
            Write-Host -Object "|"
            $nsg_num ++ ; Start-Sleep 1
        }
        Start-Sleep 1
        Write-Host -Object "| - - - - -"
    }
    Write-Host -Object "| function add_StorageAccount completed."
    Write-Host -Object "|"
}

