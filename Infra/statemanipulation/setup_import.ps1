# This script prepares the environment for the import exercise.
$RG_NAME="rg-manual-resource"
$LOCATION="eastus"

Write-Host "Creating Resource Group $RG_NAME via Azure CLI..." -ForegroundColor Cyan
az group create --name $RG_NAME --location $LOCATION

$SUB_ID=$(az account show --query id -o tsv)
$RG_ID="/subscriptions/$SUB_ID/resourceGroups/$RG_NAME"

Write-Host "`nTo import this resource, run:" -ForegroundColor Green
Write-Host "terraform import azurerm_resource_group.manual $RG_ID" -ForegroundColor Yellow
