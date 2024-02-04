function add_AvailabilitySet {
    foreach ($line in $availability_csv) {
        $asetName = $line.AvailabilitySet
        $rgName = $line.vm_resourceGroup
        $location = $line.Location
        $updateDomain = $line.UpdateDomain
        $faultDomain = $line.FaultDomain
        $ppgName = $line.ProximityPlacementGroup
        <#
            .SYNOPSIS
            Deploy New availabilitySet and a ProximityPlacementGroup.

            .DESCRIPTION
            This function creates New AvailabilitySet and a ProximityPlacementGroup.

            .PARAMETER
            This function uses CSV parameters loaded in deploy_AzVm.ps1.

            .EXAMPLE
            NONE. This function is called in "deploy_AzVm.ps1
        #>
        # Check if VM_RESOURCEGROUP exists.
        if ($ppgName) {
            $ppg = Get-AzProximityPlacementGroup -Name $ppgName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
            if (!($ppg)) {
                # Function call. Create resource group if it does not exist.
                add_ResourceGroup $rgName $location
                Write-Host -Object "| Proximity_Placement_Group [ $ppgName ]"
                Write-Host -Object "|"
                        Write-Host -Object "| ProximityPlacementGroup [ ${ppgName} ] deploying..."
                New-AzProximityPlacementGroup -Name $ppgName -ResourceGroupName $rgName -Location $location -AsJob | Out-Null
                Get-Job | Wait-Job | Out-Null
                if (Get-Job -State Failed) {
                    Write-Host -Object "| -- Error -- some jobs failed as follows:" -ForegroundColor "Red" ; (Get-Job -State Failed).Error
                    Get-Job | Remove-Job | Out-Null
                    break ; Write-Host -Object "|"
                }
                Get-Job | Remove-Job | Out-Null
                Write-Host -Object "| ProximityPlacementGroup ResourceID: "
                (Get-AzProximityPlacementGroup -Name $ppgName -ResourceGroupName $rgName).Id
                Write-Host -Object "|"
            }
        }

        $aset = Get-AzAvailabilitySet -Name $asetName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
        if (!($aset)) {
            Write-Host -Object "| Availability_Set [ $asetName ]"
            Write-Host -Object "|"
            Write-Host -Object "| AvailabilitySet [ ${asetName} ] deploying..."
            if ($ppgName) {
                $ppg=get-AzProximityPlacementGroup -Name $ppgName -ResourceGroupName $rgName
                New-AzAvailabilitySet -Name $asetName -ResourceGroupName $rgName -Location $location -Sku aligned `
                -PlatformUpdateDomainCount $updateDomain -PlatformFaultDomainCount $faultDomain -ProximityPlacementGroupId $ppg.Id -AsJob | Out-Null
            } else {
                New-AzAvailabilitySet -Name $asetName -ResourceGroupName $rgName -Location $location -Sku aligned `
                -PlatformUpdateDomainCount $updateDomain -PlatformFaultDomainCount $faultDomain -AsJob | Out-Null
            }
            Get-Job | Wait-Job | Out-Null
            if (Get-Job -State Failed) {
                Write-Host -Object "| -- Error -- some jobs failed as follows:" -ForegroundColor "Red" ; (Get-Job -State Failed).Error
                Get-Job | Remove-Job | Out-Null
                break ; Write-Host -Object "|"
            }
            Get-Job | Remove-Job | Out-Null
            Write-Host -Object "| AvailabilitySet ResourceID: "
            Write-Host "|"($aset = Get-AzAvailabilitySet -Name $asetName -ResourceGroupName $rgName).Id
            Write-Host -Object "|"
            Start-Sleep 1
        } else {
            Write-Host -Object "| AvailabilitySet [ ${asetName} ] already exists." -ForegroundColor "Yellow"
        }
            Write-Host -Object "| - - - - -"
    }
    Write-Host -Object "| function add_AvailabilitySet completed."
    Write-Host -Object "|"
}

