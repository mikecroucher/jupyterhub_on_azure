# Jupyterhub on azure

A JupyterHub instance running on Azure cloud designe for a multi-user class.  This doesn't (yet) use docker or elastic scaling. It's just a plan old server in the cloud -- albeit one that we can set up and tear down at will. 

People can use it to set up their own servers -- no need to speak to the IT department if they don't want to

## Setting this up yourself

I got it working far too late at night and can't be bothered to turn the commands I fired at the thing into scripts. I'm going to bed!
Will automate all the things in the morning.
and maybe document it!

* Create a Linux VM running Ubuntu 18.04
* Run install.sh
* Log in to Jupyter using http://<Your VM IP Address>:8000

Note to self -- document this stuff:

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

JupyterHub cloud installs elsewhere

The Data Science VM has JupyterHub pre-installed (and JupyterLab on the Ubuntu DSVM) – https://docs.microsoft.com/en-us/azure/machine-learning/data-science-virtual-machine/overview 

Azure Lab Services - https://azure.microsoft.com/en-us/services/lab-services/ 
