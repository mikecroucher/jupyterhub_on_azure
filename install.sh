#!/bin/bash
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

#Configure certificate in Jupyterhub
cat << EOF >> ./jupyterhub_config.py
c.JupyterHub.ssl_key = '/etc/jupyter/ssl/mycert.prv'
c.JupyterHub.ssl_cert = '/etc/jupyter/ssl/mycert.cert'
EOF

#Run jupyterhub
jupyterhub
