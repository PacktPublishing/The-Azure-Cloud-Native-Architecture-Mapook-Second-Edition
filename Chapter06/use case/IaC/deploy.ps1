$resourceGroupName = "mapbook-chapter6"
$location = "swedencentral"
$uniqueNameSb = "mapbookchap6sb$([System.Random]::new().Next(10000,99999))"
$functionappidentity = "validationfunctionidentity"
$invoiceTopic = "invoices"
$invalidInvoicesSubscription = "invoices.invalid"
$invoicesApprovalRequiredSubscription = "invoices.approval-required"
$invoicesAutoApprovedSubscription = "invoices.auto-approved"
$uniqueNameFa = "mapbookchap06fa$([System.Random]::new().Next(10000,99999))"
$uniqueNameFaSa = "mapbookchap06fasa$([System.Random]::new().Next(10000,99999))"
$uniqueNameSa = "mapbookchap06saapp$([System.Random]::new().Next(10000,99999))"
$appServicePlan = "mapbookchap06plan"
  
az group create --name $resourceGroupName --location $location

az functionapp plan create `
  --name $appServicePlan `
  --resource-group $resourceGroupName `
  --location $location `
  --sku EP1 `

az identity create `
  --name $functionappidentity `
  --resource-group $resourceGroupName `
  --location $location

$identity_id=$(az identity show `
  --name $functionappidentity `
  --resource-group $resourceGroupName `
  --query id `
  --output tsv)

$clientId=$(az identity show `
  --name $functionappidentity `
  --resource-group $resourceGroupName `
  --query clientId `
  --output tsv)

az storage account create `
--name $uniqueNameFaSa `
--location $location `
--resource-group $resourceGroupName `
--sku Standard_LRS

az storage account create `
--name $uniqueNameSa `
--location $location `
--resource-group $resourceGroupName `
--sku Standard_LRS

az storage container create `
  --name invoices `
  --account-name $uniqueNameSa `
  --auth-mode login

# using auth-mode key because the current user (meaning you) is not granted access to the storage account by default
az storage blob upload `
  --container-name invoices `
  --name dummyinvoice.json `
  --file ./dummyinvoice.json `
  --account-name $uniqueNameSa `
  --auth-mode key


$saResourceId=az storage account show `
  --name $uniqueNameSa `
  --resource-group $resourceGroupName `
  --query id `
  --output tsv

az functionapp create `
  --name $uniqueNameFa `
  --storage-account $uniqueNameFaSa `
  --resource-group $resourceGroupName `
  --plan $appServicePlan `
  --runtime dotnet-isolated `
  --functions-version 4 `
  --assign-identity $identity_id `
  --os-type Windows


$principalId=az identity show `
  --name $functionappidentity `
  --resource-group $resourceGroupName `
  --query principalId `
  --output tsv

az servicebus namespace create `
  --resource-group $resourceGroupName `
  --name $uniqueNameSb `
  --location $location `
  --sku Standard

$sbResourceId=az servicebus namespace show `
  --name $uniqueNameSb `
  --resource-group $resourceGroupName `
  --query id `
  --output tsv

#required to let the function app send messages to the Service Bus topic
az role assignment create `
  --assignee $principalId `
  --role "Azure Service Bus Data Sender" `
  --scope $sbResourceId

#required for blob trigger  
az role assignment create `
  --assignee $principalId `
  --role "Storage Blob Data Contributor" `
  --scope $saResourceId

#required for poison message handling
az role assignment create `
  --assignee $principalId `
  --role "Storage Queue Data Contributor" `
  --scope $saResourceId


az servicebus topic create `
  --resource-group $resourceGroupName `
  --namespace-name $uniqueNameSb `
  --name $invoiceTopic

az servicebus topic subscription create `
  --resource-group $resourceGroupName `
  --namespace-name $uniqueNameSb `
  --topic-name $invoiceTopic `
  --name invoices.invalid

az servicebus topic subscription create `
  --resource-group $resourceGroupName `
  --namespace-name $uniqueNameSb `
  --topic-name $invoiceTopic `
  --name $invoicesAutoApprovedSubscription

az servicebus topic subscription create `
  --resource-group $resourceGroupName `
  --namespace-name $uniqueNameSb `
  --topic-name invoices `
  --name $invoicesApprovalRequiredSubscription
 
az servicebus topic subscription rule create `
  --resource-group $resourceGroupName `
  --namespace-name $uniqueNameSb `
  --topic-name $invoiceTopic `
  --subscription-name $invoicesAutoApprovedSubscription `
  --name InvoiceFilter `
  --filter-sql-expression "valid = true AND version = 'v1' AND amount < 10000"

az servicebus topic subscription rule create `
  --resource-group $resourceGroupName `
  --namespace-name $uniqueNameSb `
  --topic-name $invoiceTopic `
  --subscription-name $invoicesApprovalRequiredSubscription `
  --name InvoiceFilter `
  --filter-sql-expression "valid = true AND version = 'v1' AND amount > 10000"

az servicebus topic subscription rule create `
  --resource-group $resourceGroupName `
  --namespace-name $uniqueNameSb `
  --topic-name $invoiceTopic `
  --subscription-name $invalidInvoicesSubscription `
  --name InvoiceFilter `
  --filter-sql-expression "valid = false AND version = 'v1'"

az functionapp config appsettings set `
  --name $uniqueNameFa `
  --resource-group $resourceGroupName `
  --settings AzureWebJobsBusinessStorage__blobServiceUri="https://$uniqueNameSa.blob.core.windows.net/" `
  AzureWebJobsBusinessStorage__clientId=$clientId `
  AzureWebJobsBusinessStorage__credential=ManagedIdentity `
  AzureWebJobsBusinessStorage__queueServiceUri="https://$uniqueNameSa.queue.core.windows.net/" `
  ServiceBusConnectionclientId=$clientId `
  ServiceBusConnectionFQDN="$uniqueNameSb.servicebus.windows.net"
