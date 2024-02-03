function add_Tag {
    foreach ($line in $tag_csv) {
        $resource_name = $line.ResourceName
        $rg_name = $line.ResourceGroup
        $tag_name = $line.TagName
        $tag_value = $line.TagValue
        $tags = @{}
        <#
            .SYNOPSIS
            Set Resource Tag.

            .DESCRIPTION
            This function set New Tag to Azure Resource.

            .PARAMETER
            This function uses CSV parameters loaded in deploy_AzVm.ps1.

            .EXAMPLE
            NONE. This function is called in "deploy_AzVm.ps1
        #>

        $target = Get-AzResource -Name $resource_name -resourceGroupName $rg_name -ErrorAction SilentlyContinue
            if (!($target)) {
                Write-Host -Object "| resource [ ${target}] is not exists." -ForegroundColor "Red"
            } else {
                # Function call. Create resource group if it does not exist.
                Write-Host -Object "| Set Tag [ ${tag_name} ] to [ ${resource_name} ]"
                Write-Host -Object "|"
                $tags.add($tag_name, $tag_value)
                New-AzTag -ResourceId $target.ResourceId -Tag $Tags
                Write-Host -Object "|"
            Write-Host -Object "| - - - - -"
        }
    }
    Write-Host -Object "| function add_Tag complete."
    Write-Host -Object "|"
}

