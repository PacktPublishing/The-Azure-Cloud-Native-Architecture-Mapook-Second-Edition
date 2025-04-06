$azfw = Get-AzFirewall -Name "toyota-main-hub-fw" -ResourceGroupName "toyota-main-hub"
$vnet = Get-AzVirtualNetwork -ResourceGroupName "toyota-main-hub" -Name "toyota-main-hub-vnet"
$publicip1 = Get-AzPublicIpAddress -Name "pip-main-hub-fw" -ResourceGroupName "toyota-main-hub"
$azfw.Allocate($vnet,@($publicip1))
Set-AzFirewall -AzureFirewall $azfw


$azfw = Get-AzFirewall -Name "toyota-ingress-hub-fw" -ResourceGroupName "toyota-ingress-hub"
$vnet = Get-AzVirtualNetwork -ResourceGroupName "toyota-ingress-hub" -Name "toyota-ingress-hub-vnet"
$publicip1 = Get-AzPublicIpAddress -Name "pip-ingress-hub-fw" -ResourceGroupName "toyota-ingress-hub"
$azfw.Allocate($vnet,@($publicip1))
Set-AzFirewall -AzureFirewall $azfw

$azfw = Get-AzFirewall -Name "toyota-egress-hub-fw" -ResourceGroupName "toyota-egress-hub"
$vnet = Get-AzVirtualNetwork -ResourceGroupName "toyota-egress-hub" -Name "toyota-egress-hub-vnet"
$publicip1 = Get-AzPublicIpAddress -Name "pip-egress-hub-fw" -ResourceGroupName "toyota-egress-hub"
$azfw.Allocate($vnet,@($publicip1))
Set-AzFirewall -AzureFirewall $azfw


