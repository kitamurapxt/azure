function add_vNetPeering {
    foreach ($line in $nw_csv) {
        $vnetName = $line.vNet_name
        $vnetResourceGroup = $line.vNet_resourceGroup
        $PeervNetNames = $line.Peer_vNets.Split(";")
        $PeervNetRgs = $line.Peer_vNetRgs.Split(";")
        <#
            .SYNOPSIS
            Set New vNetPeering.

            .DESCRIPTION
            This function creates New vNetPeering.

            .PARAMETER
            This function uses CSV parameters loaded in deploy_AzVm.ps1.

            .EXAMPLE
            NONE. This function is called in deploy_AzVm.ps1
        #>

        if (!($PeervNetNames)) {
            # do nothing
        } else{
            $vnet_num = 0
            foreach ($PeervNetName in $PeervNetNames) {
                Write-Host -Object "| Azure_Virtual_Network_Peering [ $vnetName ]"
                Write-Host -Object "|"
                $fromvNet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroup $vnetResourceGroup -ErrorAction SilentlyContinue
                $PeervNet = Get-AzVirtualNetwork -Name $PeervNetName -ResourceGroup $PeervNetRgs[$vnet_num] -ErrorAction SilentlyContinue
                if (!($fromvNet)) {
                    Write-Host -Object "| FROMVNET [ ${$fromvNet} ] not found." -ForegroundColor "Yellow" ; break
                }
                if (!($PeervNet)) {
                    Write-Host -Object "| PEERVNET [ ${$PeervNet} ] not found." -ForegroundColor "Yellow" ; break
                } else {
                    $PeerName = $vnetName +"---"+ $PeervNetName
                    if (!(Get-AzVirtualNetworkPeering -VirtualNetworkName $fromvNet.name -ResourceGroupName $vnetResourceGroup -Name $PeerName -ErrorAction SilentlyContinue)) {
                        Write-Host -Object "| PEERING [ ${PeerName} ] deploying... "
                        Add-AzVirtualNetworkPeering -Name $PeerName -VirtualNetwork $fromvNet -RemoteVirtualNetworkId $PeervNet.Id -AsJob
                        Get-Job | Wait-Job | Out-Null
                        if (Get-Job -State Failed) {
                            Write-Host -Object "| -- Error -- some jobs failed as follows:" -ForegroundColor "Red" ; (Get-Job -State Failed).Error 
                            Get-Job | Remove-Job | Out-Null
                            Write-Host -Object "|" ; break
                        }
                        Get-Job | Remove-Job | Out-Null
                        Write-Host -Object "| VNET PEERING [ ${PeerName} ] connected."
                        Write-Host -Object "|"
                    } else {
                        Write-Host -Object "| VNET PEERING [ ${PeerName} ] already exists." -ForegroundColor "Yellow"
                    }
                }
                Write-Host -Object "| - - - - -"
                $vnet_num ++ ; Start-Sleep 1
            }
        }
    }
    Write-Host -Object "| function add_vNetPeering completed."
    Write-Host -Object "|"
}

