function add_RouteConfig {
    foreach ($line in $route_csv) {
        $rt_name = $line.routeTableName
        $rt_resourceGroup = $line.rtResourceGroup
        $route_name = $line.routeName
        $address = $line.routeAddress
        $nexthop = $line.nexthopType
        $nextIp= $line.nexthopIp
        <#
            .SYNOPSIS
            Set New route.

            .DESCRIPTION
            This function creates New route.

            .PARAMETER
            This function uses CSV parameters loaded in deploy_AzVm.ps1.

            .EXAMPLE
            NONE. This function is called in "deploy_AzVm.ps1
        #>

        # Check if routeTable exist.
        Write-Host -Object "|"
        Write-Host -Object "| Azure_Network_Route_Table [ $rt_name ]"
        $rt = Get-AzRouteTable -Name $rt_name -ResourceGroupName $rt_resourceGroup -ErrorAction SilentlyContinue
        if (!($rt)) {
            Write-Host -Object "| -- Error -- RouteTable [ ${rt_name} ] not found." -ForegroundColor "Red"
            break ; Write-Host -Object "|"
        }
        $route = Get-AzRouteTable -Name $rt_name -ResourceGroupName $rt_resourceGroup | Get-AzRouteConfig -Name $route_name -ErrorAction SilentlyContinue
        if (!($route)) {
            if ($nextIp) {
                Get-AzRouteTable -Name $rt_name -ResourceGroupName $rt_resourceGroup `
                | Add-AzRouteConfig -Name $route_name `
                -AddressPrefix $address `
                -NextHopType $nexthop `
                -NextHopIpAddress $nextIp | Set-AzRouteTable
            } else {
                Get-AzRouteTable -Name $rt_name -ResourceGroupName $rt_resourceGroup `
                | Add-AzRouteConfig -Name $route_name `
                -AddressPrefix $address `
                -NextHopType $nexthop | Set-AzRouteTable
            }
            Write-Host -Object "| Route [ ${route_name} ]: "
            Get-AzRouteTable -Name $rt_name -ResourceGroupName $rt_resourceGroup | Get-AzRouteConfig -Name $route_name
            Write-Host -Object "|"
            Start-Sleep 1
        } else {
            Write-Host -Object "| Route [ ${route_name} ] already exists." -ForegroundColor "Yellow"
        }
    }
    Write-Host -Object "| function add_RouteConfig completed."
    Write-Host -Object "|"
}

