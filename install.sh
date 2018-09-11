#!/bin/bash
#Install Azure CLI
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
    sudo tee /etc/apt/sources.list.d/azure-cli.list
curl -L https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
sudo apt-get install apt-transport-https
sudo apt-get update && sudo apt-get install azure-cli

#Install pre-reqs
sudo apt-get install npm
sudo apt-get install python3-pip
sudo apt-get install nodejs-legacy

#Install Jupyterhub
sudo npm install -g configurable-http-proxy
python3 -m pip install jupyterhub

#Install the notebook
sudo python3 -m pip install notebook

#Install some packages
sudo python3 -m pip install numpy scipy matplotlib

#Installing by pip didn't add the jupyterhub binary folder to the path so let's do that now
export PATH=$PATH:~/.local/bin

#Generate default config
jupyterhub --generate-config

#Move certificate files
secretsname=$(sudo find /var/lib/waagent/ -name "*.prv" | cut -c -57)
sudo mkdir -p /etc/jupyter/ssl
sudo cp $secretsname.crt /etc/jupyter/ssl/mycert.cert
sudo cp $secretsname.prv /etc/jupyter/ssl/mycert.prv

#Configure certificate in Jupyterhub
cat << EOF >> ./jupyterhub_config.py
c.JupyterHub.ssl_key = '/etc/jupyter/ssl/mycert.prv'
c.JupyterHub.ssl_cert = '/etc/jupyter/ssl/mycert.cert'
EOF

#Run jupyterhub
jupyterhub
