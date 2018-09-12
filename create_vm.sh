#/bin/bash
keyvaultName=jupyterkeyvault
location=westus2
certificateName=mycert
resourceGroupName=myResourceGroupSecureWeb2
vmName=jupyter2

#Obtain the ID of the certificate we want to use from the keyvault within the VM
secret=$(az keyvault secret list-versions \
          --vault-name $keyvaultName \
          --name $certificateName \
          --query "[?attributes.enabled].id" --output tsv)
vm_secret=$(az vm secret format --secrets "$secret")

#Create the VM
az vm create \
    --resource-group $resourceGroupName \
    --name $vmName \
    --image UbuntuLTS \
    --admin-username azureuser \
    --generate-ssh-keys \
    --secrets "$vm_secret"

#Open the port for Jupyter
az vm open-port --resource-group $resourceGroupName --name $vmName --port 8000
