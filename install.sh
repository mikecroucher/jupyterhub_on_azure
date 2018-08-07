#!/bin/bash
#Install pre-reqs
sudo apt-get install npm
sudo apt-get install python3-pip

#Install Jupyterhub
sudo npm install -g configurable-http-proxy
python3 -m pip install jupyterhub

#Installing by pip didn't add the jupyterhub binary folder to the path so let's do that now
export PATH=$PATH:~/.local/bin
