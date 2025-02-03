function add_Subnet {
    foreach ($line in $nw_csv) {
        $vnetName = $line.vNet_name
        $vnetResourceGroup = $line.vNet_resourceGroup
        $subnetNames = $line.subnetNames.Split(";")
        $subnetRanges = $line.subnetRanges.Split(";")
        $nsgNames = $line.NSG_names.Split(";")
        $nsgResourceGroup = $line.vNet_resourceGroup
        $rtNames = $line.RouteTable_names.Split(";")
        $rtResourceGroup = $line.vNet_resourceGroup
        <#
            .SYNOPSIS
            Set New VirtualNetwork Subnet.

            .DESCRIPTION
            This function creates New Subnet in VirtualNetwork.

            .PARAMETER
            This function uses CSV parameters loaded in deploy_AzVm.ps1.

            .EXAMPLE
            NONE. This function is called in "deploy_AzVm.ps1
        #>

        $subnet_num = 0
        foreach ($subnetName in $subnetNames) {
            $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroup $vnetResourceGroup -ErrorAction SilentlyContinue
            $subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet -ErrorAction SilentlyContinue
            if (!($subnet)) {
                Write-Host -Object "| Azure_Virtual_Network_Subnet [ $subnetName ]"
                Write-Host -Object "|"
                Write-Host -Object "| SUBNET [ ${subnetName} ] deploying... "

                if (($nsgNames) -And ($rtNames)) {
                    $nsg = Get-AzNetworkSecurityGroup -Name $nsgNames[$subnet_num] -resourceGroup $nsgResourceGroup -ErrorAction SilentlyContinue
                    $routeTable = Get-AzRouteTable -Name $rtNames[$subnet_num] -resourceGroup $rtResourceGroup -ErrorAction SilentlyContinue
                    if (($nsg) -And ($routeTable)) {
                        Add-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet `
                        -AddressPrefix $subnetRanges[$subnet_num] -NetworkSecurityGroupId $nsg.Id `
                        -RouteTableId $routeTable.Id | set-AzVirtualNetwork -AsJob | Out-Null
                    }
                } elseif ($nsgNames) {
                        $nsg = Get-AzNetworkSecurityGroup -Name $nsgNames[$subnet_num] -resourceGroup $nsgResourceGroup -ErrorAction SilentlyContinue
                        if ($nsg) {
                            Add-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet `
                            -AddressPrefix $subnetRanges[$subnet_num] -NetworkSecurityGroupId $nsg.Id | set-AzVirtualNetwork -AsJob | Out-Null    
                        }
                } elseif ($rtNames) {
                        $routeTable = Get-AzRouteTable -Name $rtNames[$subnet_num] -resourceGroup $rtResourceGroup -ErrorAction SilentlyContinue
                        if ($routeTable) {
                            Add-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet `
                            -AddressPrefix $subnetRanges[$subnet_num] -RouteTableId $routeTable.Id | set-AzVirtualNetwork -AsJob | Out-Null    
                        }
                } else {
                    Add-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet `
                    -AddressPrefix $subnetRanges[$subnet_num] | set-AzVirtualNetwork -AsJob | Out-Null
                }

                Get-Job | Wait-Job | Out-Null
                if (Get-Job -State Failed) {
                    Write-Host -Object "| -- Error -- some jobs failed as follows:" -ForegroundColor "Red" ; (Get-Job -State Failed).Error 
                    Get-Job | Remove-Job | Out-Null
                    Write-Host -Object "|" ; break
                }
            Get-Job | Remove-Job | Out-Null
            Write-Host -Object "| SUBNET ResourceID: "
            $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroup $vnetResourceGroup
            Write-Host "|"(Get-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet).Id
            Write-Host -Object "|" ; $nsg = $null
            $subnet_num ++ ; Start-Sleep 1
        } else {
            Write-Host -Object "| SUBNET [ ${subnetName} ] already exists." -ForegroundColor "Yellow" #; break
        }
    }
        Write-Host -Object "| - - - - -"
    }
    Write-Host -Object "| function add_Subnet completed."
    Write-Host -Object "|"
}

