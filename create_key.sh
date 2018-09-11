#!/bin/bash
#Creates a keyvault on Azure and puts a self signed SSL key in it
#Closely follows the documentation at https://docs.microsoft.com/en-us/azure/virtual-machines/linux/tutorial-secure-web-server
#Retrieved 11th September 2018
resourceGroupName=myResourceGroupSecureWeb2
keyvaultName=jupyterkeyvault
location=westus2
certificatName=mycert

#Creates the resource group in Azure
az group create --name $resourceGroupName --location $location

#Creates the keyvault in Azure
az keyvault create \
    --resource-group $resourceGroupName \
    --name $keyvaultName \
    --enabled-for-deployment

# Creates the self signed certificate in Azure
az keyvault certificate create \
    --vault-name $keyvault_name \
    --name $certificateName \
    --policy "$(az keyvault certificate get-default-policy)"

