#/bin/bash
keyvaultName=jupyterkeyvault
location=westus2
certificatName=mycert
resourceGroupName=myResourceGroupSecureWeb2
vmName=jupyter2

#Obtain the ID of the certificate we want to use from the keyvault within the VM
secret=$(az keyvault secret list-versions \
          --vault-name $keyvaultName \
          --certificateName $mycert \
          --query "[?attributes.enabled].id" --output tsv)
vm_secret=$(az vm secret format --secrets "$secret")

az vm create \
    --resource-group resourceGroupName \
    --name $vmName \
    --image UbuntuLTS \
    --admin-username azureuser \
    --generate-ssh-keys \
    --secrets "$vm_secret"
