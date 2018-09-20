#!/bin/bash
#Install Azure CLI
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
    sudo tee /etc/apt/sources.list.d/azure-cli.list
curl -L https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
sudo apt-get install apt-transport-https
sudo apt-get update && sudo apt-get install azure-cli

#By default, users can read the files in each other's home directory.
#Change this so only sudo users have this ability
sudo sed -i s/DIR_MODE=0755/DIR_MODE=0750/g /etc/adduser.conf

#create users
number_of_users=3
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
  sudo adduser --disabled-password --gecos "" $username
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
python3 -m pip install jupyterhub
sudo python3 -m pip install sudospawner

#Install the notebook
sudo python3 -m pip install notebook

#Install some packages
sudo python3 -m pip install numpy scipy matplotlib
#Packages for earth and environment
#cartopy
sudo apt-get -y install libproj-dev proj-data proj-bin
sudo apt-get -y install libgeos-dev
sudo python3 -m pip install cython
sudo python3 -m pip install cartopy
#netcdf
sudo apt-get -y install libnetcdf-dev netcdf-bin
sudo python3 -m pip install netCDF4

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

#Run on port 443 so that it uses https
cat << EOF >> ./jupyterhub_config.py
c.JupyterHub.port = 443
EOF

#copy the config file
sudo mkdir -p /etc/jupyterhub
sudo cp ./jupyterhub_config.py /etc/jupyterhub/jupyterhub_config.py
sudo chown -R azureuser:azureuser /etc/jupyterhub/

#Set up sudospawner
#Following docs at https://github.com/jupyterhub/jupyterhub/wiki/Using-sudo-to-run-JupyterHub-without-root-privileges retrieved 19th September 2018
echo "Cmnd_Alias JUPYTER_CMD=/usr/local/bin/sudospawner" | sudo tee -a /etc/sudoers
echo "%jupyterhub ALL=(azureuser) /usr/bin/sudo" | sudo tee -a /etc/sudoers
echo "azureuser ALL=(%jupyterhub) NOPASSWD:JUPYTER_CMD" | sudo tee -a /etc/sudoers

#Set up jupyterhub as a service
sudo cp ./jupyterhub.service /etc/systemd/system/jupyterhub.service

#Make our user part of the shadow group so that PAM authentication works
sudo usermod -a -G shadow azureuser

#Do this next line or we'll not be able to connect to port 443
#Details at https://github.com/jupyterhub/jupyterhub/issues/774
sudo setcap 'cap_net_bind_service=+ep' `which nodejs`

#Enable the jupyterhub service so it starts at boot
sudo systemctl enable jupyterhub
#start the service now
sudo systemctl start jupyterhub

#Connect the data drive
sudo mkdir /datadrive
#The datadrive is probably going to be connected /dev/sdc1 but I should come up with some way of checking properly
sudo mount /dev/sdc1 /datadrive
