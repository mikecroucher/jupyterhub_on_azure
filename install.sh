#!/bin/bash
#MATLAB works on this commit
#Install Azure CLI
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
    sudo tee /etc/apt/sources.list.d/azure-cli.list
curl -L https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
sudo apt-get install apt-transport-https
sudo apt-get update && sudo apt-get install azure-cli

# Install node
## Standard repo is too old
sudo apt-get install nodejs npm -y
#curl -sL https://deb.nodesource.com/setup_18.x -o nodesource_setup.sh
#sudo bash nodesource_setup.sh
#sudo apt-get install -y nodejs

# Install JupyterHub
sudo apt install python3-pip -y
sudo apt install unzip -y
sudo npm install -g configurable-http-proxy
sudo pip install jupyterhub
sudo pip install jupyterlab
sudo pip install jupyterthemes
#Forces downgrade of jupyterlab. Seems to resolve the stylesheet problem
sudo pip install jupyterlab-simpledark

#For MATLAB kernel support
sudo apt-get install xvfb -y 

# Install MATLAB
wget -q https://www.mathworks.com/mpm/glnxa64/mpm && chmod +x mpm
sudo ./mpm install \
        --release=R2023a \
        --destination=/opt/ \
        --products MATLAB Parallel_Computing_Toolbox Statistics_and_Machine_Learning_Toolbox Deep_Learning_Toolbox \
	--no-gpu

# Install Python modules required
sudo pip install numpy
sudo pip install torch
sudo pip install jupyter-matlab-proxy

#Configure JupyterHub
#Generate default config
/usr/local/bin/jupyterhub --generate-config

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

#Redirect http:// to https://
cat << EOF >> ./jupyterhub_config.py
c.ConfigurableHTTPProxy.command = ['configurable-http-proxy', '--redirect-port', '80']
EOF

#Add jupyterhub admin users
cat << EOF >> ./jupyterhub_config.py
c.Authenticator.admin_users = {'azureuser', 'instructor'}
EOF

#Make Jupyter Lab the default
cat << EOF >> ./jupyterhub_config.py
c.Spawner.default_url = '/lab'
EOF

#copy the Jupyterhub config file
sudo mkdir -p /etc/jupyterhub
sudo cp ./jupyterhub_config.py /etc/jupyterhub/jupyterhub_config.py
sudo chown -R azureuser:azureuser /etc/jupyterhub/

#Set up sudospawner
#Following docs at https://github.com/jupyterhub/jupyterhub/wiki/Using-sudo-to-run-JupyterHub-without-root-privileges retrieved 19th September 2018
sudo pip install sudospawner
echo "Cmnd_Alias JUPYTER_CMD = /usr/local/bin/sudospawner" | sudo tee -a /etc/sudoers
echo "%jupyterhub ALL=(azureuser) /usr/bin/sudo" | sudo tee -a /etc/sudoers
echo "azureuser ALL=(%jupyterhub) NOPASSWD:JUPYTER_CMD" | sudo tee -a /etc/sudoers

#Set up jupyterhub as a service
sudo cp ./jupyterhub.service /etc/systemd/system/jupyterhub.service

#Make our user part of the shadow group so that PAM authentication works
sudo usermod -a -G shadow azureuser

#Do this next line or we'll not be able to connect to port 443
#Details at https://github.com/jupyterhub/jupyterhub/issues/774
#sudo setcap 'cap_net_bind_service=+ep' `which nodejs`
#sudo setcap 'cap_net_bind_service=+ep' `which node`
sudo setcap 'cap_net_bind_service=+ep' /usr/bin/node 

#Enable the jupyterhub service so it starts at boot
sudo systemctl enable jupyterhub
#start the service now
sudo systemctl start jupyterhub

#By default, users can read the files in each other's home directory.
#Change this so only sudo users have this ability
sudo sed -i s/DIR_MODE=0755/DIR_MODE=0750/g /etc/adduser.conf

#Add the aliases requested from the academics to .bashrc
cat << EOF >> /etc/skel/.bashrc
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'
EOF

#create users
number_of_users=5
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
  #userpassword=`apg -n 1`
  userpassword=mathPass_$i
  echo $username:$userpassword | sudo chpasswd
  echo "UserID:" $username "has been created with the following password " $userpassword >> $password_file
 done
 
 #Install the instructor username
 sudo adduser --disabled-password --gecos "" instructor
 userpassword=`apg -n 1`
 echo instructor:$userpassword | sudo chpasswd
 echo "UserID:" instructor "has been created with the following password " $userpassword >> $password_file

#Connect the data drive
#sudo mkdir /datadrive
#The datadrive is probably going to be connected /dev/sdc1 but I should come up with some way of checking properly
#sudo mount /dev/sdc1 /datadrive

#Connect the backup drive
#sudo mkdir /backup
#The backup drive is probably going to be connected /dev/sdc1 but I should come up with some way of checking properly
#sudo mount /dev/sdd1 /backup

#Install rsnapshot to do the backups
#sudo apt-get -y install rsnapshot
#Snapshot_root location
#sudo sed -i s,/var/cache/rsnapshot/,/backup/,g /etc/rsnapshot.conf
#We don't want to back up /etc and /usr/local so comment these lines out
#sudo sed -i 's,backup\t/etc,#backup\t/etc,g' /etc/rsnapshot.conf
#sudo sed -i 's,backup\t/usr/local,#backup /usr/local,g' /etc/rsnapshot.conf
#Activate the cron job by uncommenting the relevant lines
#sed -i '/alpha/s/^#//g' /etc/cron.d/rsnapshot
#sed -i '/beta/s/^#//g' /etc/cron.d/rsnapshot
#sed -i '/gamma/s/^#//g' /etc/cron.d/rsnapshot

#Tell the install log we are done
echo "Install done"

