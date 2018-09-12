#!/bin/bash
#Install Azure CLI
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
    sudo tee /etc/apt/sources.list.d/azure-cli.list
curl -L https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
sudo apt-get install apt-transport-https
sudo apt-get update && sudo apt-get install azure-cli

#create users
number_of_users=35
password_file=~/users.txt

#Install apg for password generation
sudo apt-get -y install apg

#On Azure, the following creates errors like
#sent invalidate(group) request, exiting
#sent invalidate(passwd) request, exiting
#This shouldn't be a problem
 touch $password_file
 for i in `seq 1 $number_of_users`;
  do
  username=training_user$i
  sudo useradd -m -d /home/$username $username
  userpassword=`apg -n 1`
  echo $username:$userpassword | sudo chpasswd
  echo "UserID:" $username "has been created with the following password " $userpassword >> $password_file
 done

#Install pre-reqs for jupyterhub
sudo apt-get -y install npm
sudo apt-get -y install python3-pip
sudo apt-get -y install nodejs-legacy

#Install Jupyterhub
sudo npm install -g configurable-http-proxy
sudo python3 -m pip install jupyterhub

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

#Make certificate files readable by the user under which we will run the jupyterhub service
sudo chgrp azureuser /etc/jupyter/ssl/mycert.cert
sudo chgrp azureuser /etc/jupyter/ssl/mycert.prv
sudo chmod g+r /etc/jupyter/ssl/mycert.cert
sudo chmod g+r /etc/jupyter/ssl/mycert.prv

#Configure certificate in Jupyterhub
cat << EOF >> ./jupyterhub_config.py
c.JupyterHub.ssl_key = '/etc/jupyter/ssl/mycert.prv'
c.JupyterHub.ssl_cert = '/etc/jupyter/ssl/mycert.cert'
EOF

#copy the config file
sudo mkdir -p /etc/jupyterhub
sudo cp ./jupyterhub_config.py /etc/jupyterhub/jupyterhub_config.py

#Set up jupyterhub as a service
cp ./jupyterhub.service /etc/systemd/system/jupyterhub.service
