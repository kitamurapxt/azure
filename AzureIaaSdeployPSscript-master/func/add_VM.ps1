function add_VM {
    # Define os.list items.
    $osType  = @()
    $publisherName = @()
    $offer = @()
    $sku = @()

    foreach ($line in $vm_csv) {
        $vmName = $line.vm_name
        $resourceGroup = $line.vm_resourceGroup
        $vmSize = $line.vm_size
        $adminUsername = $line.AdminId
        $adminPassword = $line.AdminPass
        $osDiskName = $line.vm_name + "_OsDisk"
        $osDiskSize = $line.vmOsDisk_size
        $osDiskType = $line.vmOsDisk_type
        $dataDiskName = $line.vm_name + "_DataDisk"
        $dataDiskSizeArray = $line.vmDataDisks_size.Split(";")
        $dataDiskTypeArray = $line.vmDataDisks_type.Split(";")
        $imageName = $line.ImageName
        $imageResourceGroup = $line.ImageResourceGroup
        $availabilitysetName = $line.AvailabilitySet
        $proximityPlacementGroupName = $line.ProximityPlacementGroup
        <#
            .SYNOPSIS
            Deploy New VM.

            .DESCRIPTION
            This function creates New VM from MarketPlace or Custom image.

            .PARAMETER
            This function uses CSV parameters loaded in deploy_AzVm.ps1.

            .EXAMPLE
            NONE. This function is called in "deploy_AzVm.ps1
        #>

        $azVM = Get-AzVM -Name $vmName -resourceGroup $resourceGroup -ErrorAction SilentlyContinue
        if ($azVM) {
            Write-Host -Object "| Virtual_Machines [ $vmName ] already exists." -ForegroundColor "Yellow"
        } else {
            Write-Host -Object "| Azure_Virtual_Machines [ $vmName ]"
            Write-Host -Object "|"
    
            # AvailabilitySet settings
            if ($availabilitysetName) {
                $availabilityset = Get-AzAvailabilitySet -Name $availabilitysetName -ResourceGroup $resourceGroup -ErrorAction SilentlyContinue
            } else { $availabilityset = $null }
            
            # ProximityPlacementGroup settings
            if ($proximityPlacementGroupName) {
                $proximityPlacementGroup = Get-AzProximityPlacementGroup -Name $proximityPlacementGroupName -ResourceGroup $resourceGroup -ErrorAction SilentlyContinue
            } else { $proximityPlacementGroup = $null }
            
            # New-AzVMConfig
            if ($availabilityset) {
                $vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize -AvailabilitySetId $availabilityset.Id
            } elseif ($proximityPlacementGroup) {
                $vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize -ProximityPlacementGroupId $proximityPlacementGroup.Id
            } else {
                $vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize
            }

            # NIC Attach
            $nicSuffix = 1
            do {
                $nicName = "${vmName}-NIC${nicSuffix}" 
                $nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $resourceGroup -ErrorAction SilentlyContinue
                if ($nic) {
                    if ($nicSuffix -eq 1) {
                        $vmConfig = Add-AzVMNetworkInterface -NetworkInterfaceId $nic.Id -VM $vmConfig -Primary:$true
                        $location = $nic.Location
                    } else {
                        $vmConfig = Add-AzVMNetworkInterface -NetworkInterfaceId $nic.Id -VM $vmConfig -Primary:$false
                    }
                } else { break ; Write-Host -Object "|" }
                $nicSuffix ++
            } while ($nic)

            # Credential setting
            $password = ConvertTo-SecureString -String $adminPassword -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential $adminUsername, $password

            # OS setting
            if(!($imageName)) {
                $os = Get-Content $list_file | Out-GridView -PassThru
                
                # Load os.list when parameter from Out-GridView is null(or Azure Cloud Shell)
                if (!($os) -Or ($os.substring(0,1) -eq "#")) {
                    Write-Host -Object " - - - - -"
                    Get-Content $list_file
                    Write-Host -Object " - - - - -"
                    [int]$os_num=Read-Host "| Select OS version ##_number"
                    $os = (Get-Content $list_file)[$os_num] 
                    if (!($os) -Or $os_num -eq 0) {
                        Write-Host -Object "| -- Error --  Invalid OS version." -ForegroundColor "Red"; "|"; break
                    }
                }
                $osType = $os | %{ $_.Split(",")[1]}
                $publisherName = $os | %{ $_.Split(",")[2]}
                $offer = $os | %{ $_.Split(",")[3]}
                $version = $os | %{ $_.Split(",")[4]}
                $sku = Get-AzVMImageSku -Location $location -PublisherName $publisherName -Offer $offer |`
                Select-Object skus | Select-String -Pattern $version"-*" | %{ $($_ -split"=")[1].Replace("}","")} |`
                Out-GridView -PassThru

                # List Get-AzVMImageSku when parameter from Out-GridView is null(or Azure Cloud Shell)
                if (!($sku) -Or ($sku.substring(0,1) -eq "#")) {
                    $sku_list = Get-AzVMImageSku -Location $location -PublisherName $publisherName -Offer $offer |`
                    Select-Object skus | Select-String -Pattern $version"-*" | %{ $($_ -split"=")[1].Replace("}","")} 
                    $list_num = 0
                    Write-Host -Object " - - - - -"
                    Write-Host -Object "##,SKU List"
                    foreach ($arr in $sku_list) {
                        "$($list_num) ,"+$arr
                        $list_num ++
                    }
                    Write-Host -Object " - - - - -"
                    [int]$sku_num=Read-Host "| Select SKU ##_number"
                    $sku = $sku_list[$sku_num]
                }

                # Confirm input Infomation
                Write-Host -Object "| VM [ $vmName ]'s OS Version infomation as follows."
                Write-Host -Object "| - - - - -"
                $osType
                $publisherName
                $offer + $sku
                $confirm = Confirm_YesNo -command pwd
                if ($confirm[2] -eq "|") {
                    "|"; "| Canceled."; "|"; break
                } else {
                    $nic = Get-AzNetworkInterface -Name "${vmName}-NIC1" -ResourceGroupName $resourceGroup
                    $image = Get-AzVMImage -PublisherName $publisherName -Offer $offer -Skus $sku -Location $nic.Location
                    if (!($image)) {
                        Write-Host -Object "| -- Error --  SKU [ $sku ] not found in Azure Marketplace." -ForegroundColor "Red"
                        break ; Write-Host -Object "|"
                    }
                    $vmConfig = Set-AzVMSourceImage -PublisherName $publisherName -Offer $offer -Skus $sku -Version "latest" -VM $vmConfig
                    $vmConfig = Set-AzVMOSDisk -Name $osDiskName -CreateOption "FromImage" -Caching "ReadWrite" -VM $vmConfig -StorageAccountType $osDiskType -DiskSizeInGB $osDiskSize
                }
            } else {

                # Custom VM image select
                $image = Get-AzImage -ImageName $imageName -ResourceGroup $imageResourceGroup -ErrorAction SilentlyContinue
                if (!($image)) {
                    Write-Host -Object "| -- Error --  IMAGE [ ${imageName} ] not found in [ ${imageResourceGroup} ]." -ForegroundColor "Red"
                    break ; Write-Host -Object "|"
                }
                Write-Host -Object "| VM_IMAGE ResourceID: "
                $image.Id
                $vmConfig = Set-AzVMSourceImage -Id $image.Id -VM $vmConfig
                $vmConfig = Set-AzVMOSDisk -Name $osDiskName -CreateOption "FromImage" -Caching "ReadWrite" -VM $vmConfig -StorageAccountType $osDiskType
                $osType = $image.StorageProfile.OsDisk.OsType
            }
            
            # Data disk setting
            $lun = 0
            if (!($image.StorageProfile.DataDisks)) {
                if ($dataDiskSizeArray) {
                    foreach ($dataDiskGB in $dataDiskSizeArray) {
                        $dataDisk = $dataDiskName + $lun
                        $vmConfig = Add-AzVMDataDisk -VM $vmConfig -Name $dataDisk -Caching "None" -DiskSizeInGB $dataDiskGB -Lun $lun -CreateOption "Empty" -StorageAccountType $dataDiskTypeArray[$lun]
                        $lun ++
                    }
                }
            }

            # Boot diagnostic disable
            $vmConfig = Set-AzVMBootDiagnostic -VM $vmConfig -Disable

            # VM deploy
            switch ($osType) {
                "Windows" {
                    $vmConfig = Set-AzVMOperatingSystem -ComputerName $vmName -Credential $credential -Windows -VM $vmConfig
                    New-AzVM -ResourceGroup $resourceGroup -Location $location -VM $vmConfig -DisableBginfoExtension -AsJob | Out-Null   
                }
                "Linux" {
                    $vmConfig = Set-AzVMOperatingSystem -ComputerName $vmName -Credential $credential -Linux -VM $vmConfig
                    New-AzVM -ResourceGroup $resourceGroup -Location $location -VM $vmConfig -AsJob | Out-Null   
                }
                Default {
                    Write-Host -Object "| -- Error --  Invalid OsType. Select Windows or Linux OsImage." -ForegroundColor "Red"
                    break ; Write-Host -Object "|"
                }
            }
            Write-Host -Object "|"
            Write-Host -Object "| VM [ $vmName ] deploying..."
            Get-Job | Wait-Job | Out-Null  
            if (Get-Job -State Failed) {
                Write-Host -Object "| -- Error --  some jobs failed as follows:" -ForegroundColor "Red" ; (Get-Job -State Failed).Error
                Get-Job | Remove-Job | Out-Null
                break ; Write-Host -Object "|"
            }
            Get-Job | Remove-Job | Out-Null
            Write-Host -Object "| VM ResourceID: "
            Write-Host "|"(Get-AzVM -Name $vmName -resourceGroup $resourceGroup).id
            Write-Host -Object "|"
        }
        Write-Host -Object "| - - - - -"
        Start-Sleep 1
    }
    Write-Host -Object "| function add_VM completed."
    Write-Host -Object "|"
}

