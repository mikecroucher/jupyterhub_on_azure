#/bin/bash
keyvaultName=jupyterkeyvault
location=westus2
certificateName=mycert
resourceGroupName=myResourceGroupSecureWeb2
disk_name=earth_data
backup_diskname=jupyterbackup
vmName=jupyter34

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
    --custom-data cloud-init.txt \
    --generate-ssh-keys \
    --secrets "$vm_secret"

#Open the port for Jupyter
az vm open-port --resource-group $resourceGroupName --name $vmName --port 443
az vm open-port --resource-group $resourceGroupName --name $vmName --port 80

jupyter_ip=$(az vm list --show-details --query "[?name=='$vmName'].{IP:publicIps}" -o tsv)

echo "Jupyterhub should be running at https://$jupyter_ip"
echo "Give it a minute to start up before you try to access it"

#Connect data disk
#diskId=$(az disk show -g $resourceGroupName -n $disk_name --query 'id' -o tsv)
#az vm disk attach -g $resourceGroupName --vm-name $vmName --disk $diskId

#Connect backup disk
#diskIdBackup=$(az disk show -g $resourceGroupName -n $backup_diskname --query 'id' -o tsv)
#az vm disk attach -g $resourceGroupName --vm-name $vmName --disk $diskIdBackup
