#!/bin/bash

# Customise variables for the Azure backend setup
RESOURCE_GROUP="rg-hn-backend"
STORAGE_ACCOUNT="hnbackendstorage"
CONTAINER_NAME="hntfstate"
LOCATION="uksouth"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create storage account
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob

# Set network rules for the storage account
az storage account network-rule add -g $RESOURCE_GROUP --account-name $STORAGE_ACCOUNT --ip-address 81.132.129.133

# Assign role to the user for the storage account
az role assignment create \
  --assignee "f3363925-3637-46be-8570-4acb3cff5d74" \
  --role "Storage Blob Data Contributor" \
  --scope /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT

# Create blob container
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT \
  --auth-mode login

echo "Azure backend storage setup complete."