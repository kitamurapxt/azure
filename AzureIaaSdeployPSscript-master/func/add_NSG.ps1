function add_NSG {
    foreach ($line in $nw_csv) {
        $location = $line.location
        $nsgNames = $line.NSG_names.Split(";")
        $nsgResourceGroup = $line.NSG_resourceGroups.Split(";")
        <#
            .SYNOPSIS
            Deploy New NSG.

            .DESCRIPTION
            This function creates New NSG.

            .PARAMETER
            This function uses CSV parameters loaded in deploy_AzVm.ps1.

            .EXAMPLE
            NONE. This function is called in "deploy_AzVm.ps1
        #>

        $nsg_num = 0
        foreach ($nsgName in $nsgNames) {
            if(!($nsgName)){ break }
            $nsg_rg = $nsgResourceGroup[$nsg_num]

            $nsg = Get-AzNetworkSecurityGroup -Name $nsgName -resourceGroup $nsg_rg -ErrorAction SilentlyContinue
            if (!($nsg)) {
                # Function call. Create resource group if it does not exist.
                add_ResourceGroup $nsg_rg $location
                Write-Host -Object "| Azure_Network_Security_Group [ ${nsgName} ]"
                Write-Host -Object "|"
                Write-Host -Object "| NSG [ ${nsgName}] deploying..."
                New-AzNetworkSecurityGroup -Name $nsgName -resourceGroup $nsg_rg -Location $Location -AsJob -Force | Out-Null
                Get-Job | Wait-Job | Out-Null
                if (Get-Job -State Failed) {
                    Write-Host -Object "| -- Error -- some jobs failed as follows:" -ForegroundColor "Red" ; (Get-Job -State Failed).Error
                    Get-Job | Remove-Job | Out-Null
                    break ; Write-Host -Object "|"
                }
                Get-Job | Remove-Job | Out-Null
                Write-Host -Object "|"
                Write-Host -Object "| NSG_ID: "
                Write-Host "|"(Get-AzNetworkSecurityGroup -Name $nsgName -resourceGroup $nsg_rg).Id
                } else {
                    Write-Host -Object "| NSG [ ${nsgName}] already exists." -ForegroundColor "Yellow"
                }
            $nsg_num ++ ; Start-Sleep 1
            Write-Host -Object "| - - - - -"
        }
    }
    Write-Host -Object "| function add_NSG completed."
    Write-Host -Object "|"
}

