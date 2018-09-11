#!/bin/bash

resourceGroupName=myResourceGroupSecureWeb2
keyvault_name=jupyterkeyvault
az group create --name $resourceGroupName --location westus2

az keyvault create \
    --resource-group $resourceGroupName \
    --name $keyvault_name \
    --enabled-for-deploymen

