$resourceGroupName = "mapbook-aca-rg1"
$envName = "mapbook-aca-env1"
$location = "swedencentral"
$orderImage ="stephaneey/order-aca:dev"
$orderQueryImage ="stephaneey/orderquery-aca:dev"
$shippingImage ="stephaneey/shipping-aca:dev"
# make sure to use a unique name for the service bus namespace
# the YAML file will be updated automatically by the script
$serviceBusNamespace = "mapbookacans1"

az group create --name $resourceGroupName --location $location
az containerapp env create --name $envName --resource-group $resourceGroupName --location $location

az identity create `
  --name mapbookidentity `
  --resource-group $resourceGroupName `
  --location $location

$identity=az identity show `
  --name mapbookidentity `
  --resource-group $resourceGroupName `
  --query principalId `
  --output tsv

$clientId=az identity show `
  --name mapbookidentity `
  --resource-group $resourceGroupName `
  --query clientId `
  --output tsv

az servicebus namespace create `
  --resource-group $resourceGroupName `
  --name $serviceBusNamespace `
  --location $location `
  --sku Standard

$sbResourceId=az servicebus namespace show `
  --name $serviceBusNamespace `
  --resource-group $resourceGroupName `
  --query id `
  --output tsv

az role assignment create `
  --assignee $identity `
  --role "Azure Service Bus Data Owner" `
  --scope $sbResourceId

az servicebus topic create `
  --resource-group $resourceGroupName `
  --namespace-name $serviceBusNamespace `
  --name order.placed #do not change

az servicebus topic create `
  --resource-group $resourceGroupName `
  --namespace-name $serviceBusNamespace `
  --name order.paid #do not change

az servicebus topic create `
  --resource-group $resourceGroupName `
  --namespace-name $serviceBusNamespace `
  --name order.shipped	#do not change

az servicebus topic subscription create `
  --resource-group $resourceGroupName `
  --namespace-name $serviceBusNamespace `
  --topic-name order.paid `
  --name shipping

az servicebus topic subscription create `
  --resource-group $resourceGroupName `
  --namespace-name $serviceBusNamespace `
  --topic-name order.shipped `
  --name foryoutocheck


$conn=az servicebus namespace authorization-rule keys list `
  --resource-group $resourceGroupName `
  --namespace-name $serviceBusNamespace `
  --name RootManageSharedAccessKey `
  --query primaryConnectionString `
  --output tsv

$yamlPath = "./daprsb.yaml"
$yamlContent = Get-Content $yamlPath -Raw

$updatedYamlContent = $yamlContent -replace '<namespace>', "`"$serviceBusNamespace.servicebus.windows.net`""
$updatedYamlContent = $updatedYamlContent -replace '<identity>', "`"$clientId`""
$updatedYamlContent | Set-Content $yamlPath

az containerapp env dapr-component set `
  --name $envName `
  --dapr-component-name daprsb `
  --resource-group $resourceGroupName `
  --yaml ./daprsb.yaml


az containerapp create `
--name order `
--resource-group $resourceGroupName `
--environment $envName `
--image $orderImage `
--target-port 8080 `
--ingress external `
--enable-dapr true `
--dapr-app-port 8080 `
--dapr-app-id order `
--min-replicas 1 `
--user-assigned mapbookidentity


az containerapp create `
--name shipping `
--resource-group $resourceGroupName `
--environment $envName `
--image $shippingImage `
--enable-dapr true `
--dapr-app-port 8080 `
--dapr-app-id shipping `
--min-replicas 1  `
--user-assigned mapbookidentity `



az containerapp create `
--name orderquery `
--resource-group $resourceGroupName `
--environment $envName `
--image $orderQueryImage `
--enable-dapr true `
--dapr-app-id orderquery `
--dapr-app-port 8080 `
--min-replicas 1
 
