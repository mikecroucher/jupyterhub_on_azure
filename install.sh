#!/bin/bash
#Install Azure CLI
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
    sudo tee /etc/apt/sources.list.d/azure-cli.list
curl -L https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
sudo apt-get install apt-transport-https
sudo apt-get update && sudo apt-get install azure-cli

#Make JupyterHub conda aware
sudo  /opt/conda/bin/conda install nb_conda_kernels -y

#Install NAG environment
sudo /opt/conda/bin/conda create -n NAGLibrary Python=3.7 ipykernel scipy numba matplotlib pip pandas -y
/opt/conda/envs/NAGLibrary/bin/pip install --extra-index-url https://www.nag.com/downloads/py/naginterfaces_mkl naginterfaces
source /opt/conda/etc/profile.d/conda.sh
conda install -c conda-forge jupyter_contrib_nbextensions -y
conda deactivate

#NAG License set up.  Will need a license manually adding in at /opt/nag.lic
mkdir -p /opt/NAG/
sudo touch /opt/NAG/nag.key

# Install JupyterHub
sudo  /opt/conda/bin/conda install jupyterhub -y

#Configure JupyterHub
#Generate default config
/opt/conda/bin/jupyterhub --generate-config

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

#copy the Jupyterhub config file
sudo mkdir -p /etc/jupyterhub
sudo cp ./jupyterhub_config.py /etc/jupyterhub/jupyterhub_config.py
sudo chown -R azureuser:azureuser /etc/jupyterhub/

#Set up sudospawner
#Following docs at https://github.com/jupyterhub/jupyterhub/wiki/Using-sudo-to-run-JupyterHub-without-root-privileges retrieved 19th September 2018
sudo /opt/conda/bin/conda install -c conda-forge sudospawner -y
echo "Cmnd_Alias JUPYTER_CMD=/opt/conda/bin/sudospawner" | sudo tee -a /etc/sudoers
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
sudo setcap 'cap_net_bind_service=+ep' /opt/conda/bin/node 

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
number_of_users=4
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
  userpassword=NAGpass_$i
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
echo "NAG cloud install done"


