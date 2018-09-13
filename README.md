# jupyterhub on azure

How I got JupyterHub working on an Ubuntu 18.04 machine on Azure 

DON'T USE THIS YET!!!!! 

* Create a Linux VM running Ubuntu 18.04
* Run install.sh
* Log in to Jupyter using http://<Your VM IP Address>:8000

```
sudo systemctl daemon-reload
sudo systemctl start jupyterhub
sudo systemctl status jupyterhub
```

The following goes at the end of `/etc/sudoers`
```
Cmnd_Alias JUPYTER_CMD=/usr/local/bin/sudospawner
%jupyterhub ALL=(azureuser) /usr/bin/sudo
azureuser ALL=(%jupyterhub) NOPASSWD:JUPYTER_CMD
```
