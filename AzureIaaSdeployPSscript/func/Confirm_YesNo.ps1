function Confirm_YesNo {
    param($command)
    $title = "| Confirm (y/n)"
    $message = "| Are you sure you want to deploy new Azure resource with this parameter ? "
    $tChoiceDescription = "System.Management.Automation.Host.ChoiceDescription"
    <#
        .SYNOPSIS
        Display yes/no question.

        .DESCRIPTION
        This function display yes/no question.

        .PARAMETER
        This function uses CSV parameters loaded in deploy_AzVm.ps1.

        .EXAMPLE
        NONE. This function is called in "deploy_AzVm.ps1
    #>
    
    $options = @(
        New-Object $tChoiceDescription (" Yes.(&y)","")
        New-Object $tChoiceDescription (" No.(&n)","")
    )
    $result = $host.ui.PromptForChoice($title, $message, $options, 1)
    switch ($result) {
        0 { "|"; . $command; break}
        1 { "|"; "| Canceled."; "|"; break}
    }
}

