#!/bin/bash
#Install pre-reqs
sudo apt-get install npm
sudo apt-get install python3-pip

#Install Jupyterhub
sudo npm install -g configurable-http-proxy
python3 -m pip install jupyterhub
