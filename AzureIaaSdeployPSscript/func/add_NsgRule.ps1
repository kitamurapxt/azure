function add_NsgRule {
    foreach ($line in $nsg_csv) {
        $nsg_name = $line.nsgName
        $nsg_resourceGroup = $line.nsgResourceGroup
        $rule_name = $line.ruleName
        $access = $line.access
        $protocol = $line.protocol
        $direction = $line.direction
        $priority = $line.priority
        $sourceAddress = $line.sourceAddresses.Split(";")
        $sourcePort = $line.sourcePorts.Split(";")
        $destAddress = $line.destAddresses.Split(";")
        $destPort = $line.destPorts.Split(";")
        $description = $line.description
        if (!($description)) { $description = "-" }
        <#
            .SYNOPSIS
            Set New NSG Rule.

            .DESCRIPTION
            This function creates New NSG Rule.

            .PARAMETER
            This function uses CSV parameters loaded in deploy_AzVm.ps1.

            .EXAMPLE
            NONE. This function is called in "deploy_AzVm.ps1
        #>

        # Check if NSG_RULE exist.
        Write-Host -Object "|"
        Write-Host -Object "| Azure_Network_Security_Group [ $nsg_name ]"
        $nsg = Get-AzNetworkSecurityGroup -Name $nsg_name -ResourceGroupName $nsg_resourceGroup -ErrorAction SilentlyContinue
        if (!($nsg)) {
            Write-Host -Object "| -- Error -- NSG [ ${nsg_name} ] not found." -ForegroundColor "Red"
            break ; Write-Host -Object "|"
        }
        $rule = Get-AzNetworkSecurityRuleConfig -Name $rule_name -NetworkSecurityGroup $nsg -ErrorAction SilentlyContinue
        if (!($rule)) {
            Get-AzNetworkSecurityGroup -Name $nsg_Name -ResourceGroupName $nsg_resourceGroup | Add-AzNetworkSecurityRuleConfig `
            -Name $rule_name `
            -Access $access `
            -Protocol $protocol `
            -Direction $direction `
            -Priority $priority `
            -SourceAddressPrefix $sourceAddress `
            -SourcePortRange $sourcePort `
            -DestinationAddressPrefix $destAddress `
            -DestinationPortRange $destPort `
            -Description $description | Set-AzNetworkSecurityGroup -AsJob | Out-Null
            Get-Job | Wait-Job | Out-Null
            if (Get-Job -State Failed) {
                Write-Host -Object "| -- Error -- some jobs failed as follows:" -ForegroundColor "Red" ; (Get-Job -State Failed).Error
                Get-Job | Remove-Job | Out-Null
                break ; Write-Host -Object "|"
            }
            Get-Job | Remove-Job | Out-Null
            Write-Host -Object "| Rule [ ${rule_name} ]: "
            $nsg = Get-AzNetworkSecurityGroup -Name $nsg_name -ResourceGroupName $nsg_resourceGroup
            Get-AzNetworkSecurityRuleConfig -Name $rule_name -NetworkSecurityGroup $nsg | Select-Object `
            Name,Direction,Access,Priority,Protocol,DestinationPortRange,SourceAddressPrefix,DestinationAddressPrefix
            Write-Host -Object "|"
            Start-Sleep 1
        } else {
            Write-Host -Object "| Rule [ ${rule_name} ] already exists." -ForegroundColor "Yellow"
        }
    }
    Write-Host -Object "| function add_NetworkSecurityRule completed."
    Write-Host -Object "|"
}

