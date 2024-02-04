function add_VirtualNetwork {
    foreach ($line in $nw_csv) {
        $vnetName = $line.vNet_name
        <#
            .SYNOPSIS
            Deploy New VirtualNetwork.

            .DESCRIPTION
            This function creates New VirtualNetwork.

            .PARAMETER
            This function uses CSV parameters loaded in deploy_AzVm.ps1.

            .EXAMPLE
            NONE. This function is called in "deploy_AzVm.ps1
        #>
        $exists = Get-AzVirtualNetwork -Name $vnetName -ResourceGroup $line.vNet_resourceGroup -ErrorAction SilentlyContinue
        if (!($exists)) {
            # Function call. Create resource group if it does not exist.
            add_ResourceGroup $line.vNet_resourceGroup $line.location
            Write-Host -Object "| Azure_Virtual_Network [ $vnetName ]"
            Write-Host -Object "|"
            Write-Host -Object "| VNET [ $vnetName ] deploying..."
            $vnet = @{}
            $vnet.Name = $line.vNet_name
            $vnet.ResourceGroupName = $line.vNet_resourceGroup
            $vnet.Location = $line.location
            $vnet.AddressPrefix = @()
            $vnetRanges = $line.ranges.Split(";")
            foreach($range in $vnetRanges){ $vnet.AddressPrefix += $range; }

            New-AzVirtualNetwork @vnet -AsJob -Force | Out-Null
            Get-Job | Wait-Job | Out-Null
            if (Get-Job -State Failed) {
                Write-Host -Object "| -- Error -- some jobs failed as follows:" -ForegroundColor "Red" ; (Get-Job -State Failed).Error
                Get-Job | Remove-Job | Out-Null
            }
            Get-Job | Remove-Job | Out-Null
            Write-Host -Object "|"
            Write-Host -Object "| VNET_ID: "
            Write-Host "| "(Get-AzVirtualNetwork -Name $vnetName -ResourceGroup $vnet.ResourceGroupName).Id    
        } else {
            Write-Host -Object "| VNET [ $vnetName ] already exists." -ForegroundColor "Yellow"
        }
        Write-Host -Object "| - - - - -"
    }
    Write-Host -Object "| function add_VirtualNetwork completed."
    Write-Host -Object "|"
}

