function add_NetworkInterface {
    foreach ($line in $vmnw_csv) {
        $nicPrefix = $line.vm_name
        $vmResourceGroup = $line.vm_resourceGroup
        $vnetName = $line.vNet_name
        $vnetResourceGroup = $line.vNet_resourceGroup
        $subnetNames = $line.subnetNames.Split(";")
        $privateIpAddresses = $line.ipAddress.Split(";")
        <#
            .SYNOPSIS
            Deploy New VM NIC.

            .DESCRIPTION
            This function creates New VM NIC.

            .PARAMETER
            This function uses CSV parameters loaded in deploy_AzVm.ps1.

            .EXAMPLE
            NONE. This function is called in "deploy_AzVm.ps1
        #>

        $nic_num = 0
        foreach ($IpAddress in $privateIpAddresses) {
            if(!($IpAddress)){ break }

            $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroup $vnetResourceGroup -ErrorAction SilentlyContinue
            if(!($vnet)){ break }

            $location = $vnet.Location

            # Function call. Create resource group if it does not exist.
            add_ResourceGroup $vmResourceGroup $location

            # Check if VM_NIC exist.
            $nicSuffix = $nic_num + 1
            $nic = Get-AzNetworkInterface -Name "${nicPrefix}-NIC${nicSuffix}" -ResourceGroup $vmResourceGroup -ErrorAction SilentlyContinue
            if (!($nic)) { 
                Write-Host -Object "| Azure_Virtual_Machines_NIC [ $nicPrefix ] "
                Write-Host -Object "|"
                Write-Host -Object "| NIC [ ${nicPrefix}-NIC${nicSuffix} ] deploying..."
                try {
                    $subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetNames[$nic_num] -VirtualNetwork $vnet
                }
                catch{
                    $subname = $subnetNames[$nic_num]
                    Write-Host -Object "| -- Error --  SUBNET [ ${vnetName}-${subname} ] not found." -ForegroundColor "Red"
                    break
                }
                $ipConfig = New-AzNetworkInterfaceIpConfig -Name "ipconfig1" -PrivateIpAddressVersion "IPv4" -PrivateIpAddress $privateIpAddresses[$nic_num] -SubnetId $subnet.Id
                New-AzNetworkInterface -Name "${nicPrefix}-NIC${nicSuffix}" -ResourceGroup $vmResourceGroup -Location $location -IpConfiguration $ipConfig -AsJob -Force | Out-Null
                Get-Job | Wait-Job | Out-Null
                if (Get-Job -State Failed) {
                    Write-Host -Object "| -- Error -- some jobs failed as follows:" -ForegroundColor "Red" ; (Get-Job -State Failed).Error
                    Get-Job | Remove-Job | Out-Null
                    break
                }
                Write-Host -Object "| NIC ResourceID: "
                Write-Host "|"(Get-AzNetworkInterface -Name "${nicPrefix}-NIC${nicSuffix}" -ResourceGroup $vmResourceGroup).Id
                Get-Job | Remove-Job | Out-Null
            } else {
                Write-Host -Object "| NIC [ ${nicPrefix}-NIC${nicSuffix} ] already exists." -ForegroundColor "Yellow"
            }
            $nic_num ++
            Write-Host -Object "| - - - - -"
        }
    }
    Write-Host -Object "| function add_NetworkInterface completed."
    Write-Host -Object "|"

}

