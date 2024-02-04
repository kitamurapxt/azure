function add_RouteTable {
    foreach ($line in $nw_csv) {
        $location = $line.location
        $rtNames = $line.RouteTable_names.Split(";")
        $rt_rg = $line.vNet_resourceGroup
        <#
            .SYNOPSIS
            Deploy New RouteTable.

            .DESCRIPTION
            This function creates New RouteTable.

            .PARAMETER
            This function uses CSV parameters loaded in deploy_AzVm.ps1.

            .EXAMPLE
            NONE. This function is called in "deploy_AzVm.ps1
        #>

        foreach ($rtName in $rtNames) {
            if(!($rtName)){ break }

            $routeTable = Get-AzRouteTable -Name $rtName -resourceGroup $rt_rg -ErrorAction SilentlyContinue
            if (!($routeTable)) {
                # Function call. Create resource group if it does not exist.
                add_ResourceGroup $rt_rg $location
                Write-Host -Object "| Azure_Route_Table [ ${rtName} ]"
                Write-Host -Object "|"
                Write-Host -Object "| RouteTable [ ${rtName}] deploying..."
                New-AzRouteTable -Name $rtName -resourceGroup $rt_rg -Location $Location -AsJob -Force | Out-Null
                Get-Job | Wait-Job | Out-Null
                if (Get-Job -State Failed) {
                    Write-Host -Object "| -- Error -- some jobs failed as follows:" -ForegroundColor "Red" ; (Get-Job -State Failed).Error
                    Get-Job | Remove-Job | Out-Null
                    break ; Write-Host -Object "|"
                }
                Get-Job | Remove-Job | Out-Null
                Write-Host -Object "|"
                Write-Host -Object "| RouteTable_ID: "
                Write-Host "|"(Get-AzRouteTable -Name $rtName -resourceGroup $rt_rg).Id
                } else {
                    Write-Host -Object "| RouteTable [ ${rtName}] already exists." -ForegroundColor "Yellow"
                }
            Start-Sleep 1
            Write-Host -Object "| - - - - -"
        }
    }
    Write-Host -Object "| function add_RouteTable completed."
    Write-Host -Object "|"
}

