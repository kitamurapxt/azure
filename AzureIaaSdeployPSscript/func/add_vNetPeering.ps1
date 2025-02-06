function add_vNetPeering {
    foreach ($line in $nw_csv) {
        $vnetName = $line.vNet_name
        $vnetRg = $line.vNet_resourceGroup
        $tovNetNames = $line.Peer_vNets.Split(";")
        $tovNetRgs = $line.Peer_vNetRgs.Split(";")
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

        if (!($tovNetNames)) {
            # do nothing
        } else{
            $vnet_num = 0
            foreach ($tovNetName in $tovNetNames) {
                Write-Host -Object "| Azure_Virtual_Network_Peering [ $vnetName ]"
                Write-Host -Object "|"
                $fromvNet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroup $vnetRg -ErrorAction SilentlyContinue
                $tovNet = Get-AzVirtualNetwork -Name $tovNetName -ResourceGroup $tovNetRgs[$vnet_num] -ErrorAction SilentlyContinue
                if (!($fromvNet)) {
                    Write-Host -Object "| FROMVNET [ ${$fromvNet} ] not found." -ForegroundColor "Yellow" ; break
                }
                if (!($tovNet)) {
                    Write-Host -Object "| PEERVNET [ ${$tovNet} ] not found." -ForegroundColor "Yellow" ; break
                } else {
                    # vNet1 --- vNet2
                    $PeerName = $vnetName +"---"+ $tovNetName
                    $vNetPeering = Get-AzVirtualNetworkPeering -VirtualNetworkName $fromvNet.name -ResourceGroupName $vnetRg -Name $PeerName -ErrorAction SilentlyContinue
                    if (!($vNetPeering)) {
                        Write-Host -Object "| PEERING [ ${PeerName} ] deploying... "
                        Add-AzVirtualNetworkPeering -Name $PeerName -VirtualNetwork $fromvNet -RemoteVirtualNetworkId $tovNet.Id -AsJob
                        Get-Job | Wait-Job | Out-Null

                        $vNetPeering = Get-AzVirtualNetworkPeering -VirtualNetworkName $fromvNet.name -ResourceGroupName $vnetRg -Name $PeerName -ErrorAction SilentlyContinue
                        $vNetPeering.AllowForwardedTraffic = $True
                        Set-AzVirtualNetworkPeering -VirtualNetworkPeering $vNetPeering -AsJob
                        Get-Job | Wait-Job | Out-Null

                        if (Get-Job -State Failed) {
                            Write-Host -Object "| -- Error -- some jobs failed as follows:" -ForegroundColor "Red" ; (Get-Job -State Failed).Error 
                            Get-Job | Remove-Job | Out-Null
                            Write-Host -Object "|" ; break
                        }
                        Get-Job | Remove-Job | Out-Null
                        Write-Host -Object "| VNET PEERING [ ${PeerName} ] connected."
                        Write-Host -Object "|"

                        # vNet2 --- vNet1
                        $PeerName = $tovnetName +"---"+ $vNetName
                        $vNetPeering = Get-AzVirtualNetworkPeering -VirtualNetworkName $tovNetName -ResourceGroupName $tovNetRgs[$vnet_num] -Name $PeerName -ErrorAction SilentlyContinue
                        if (!($vNetPeering)) {
                            Write-Host -Object "| PEERING [ ${PeerName} ] deploying... "
                            Add-AzVirtualNetworkPeering -Name $PeerName -VirtualNetwork $tovNet -RemoteVirtualNetworkId $fromvNet.Id -AsJob
                            Get-Job | Wait-Job | Out-Null
    
                            $vNetPeering = Get-AzVirtualNetworkPeering -VirtualNetworkName $tovNetName -ResourceGroupName $tovNetRgs[$vnet_num] -Name $PeerName -ErrorAction SilentlyContinue
                            $vNetPeering.AllowForwardedTraffic = $True
                            Set-AzVirtualNetworkPeering -VirtualNetworkPeering $vNetPeering -AsJob    
                            Get-Job | Wait-Job | Out-Null
                            
                            if (Get-Job -State Failed) {
                                Write-Host -Object "| -- Error -- some jobs failed as follows:" -ForegroundColor "Red" ; (Get-Job -State Failed).Error 
                                Get-Job | Remove-Job | Out-Null
                                Write-Host -Object "|" ; break
                            }
                            Get-Job | Remove-Job | Out-Null
                            Write-Host -Object "| VNET PEERING [ ${PeerName} ] connected."
                            Write-Host -Object "|"
                        }
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


