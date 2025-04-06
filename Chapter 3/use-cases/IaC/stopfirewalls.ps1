$azfw = Get-AzFirewall -Name "ingress-fw" -ResourceGroupName "contoso-rg"
$azfw.Deallocate()
Set-AzFirewall -AzureFirewall $azfw
$azfw = Get-AzFirewall -Name "mainhub-fw" -ResourceGroupName "contoso-rg"
$azfw.Deallocate()
Set-AzFirewall -AzureFirewall $azfw