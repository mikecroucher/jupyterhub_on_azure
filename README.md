# Jupyterhub on azure

Scripts for automatic creation of customised JupyterHub instances running on Azure cloud designed for multi-user classes.  This doesn't (yet) use docker or elastic scaling. It's just a plan old server in the cloud -- albeit one that we can set up and tear down at will. 

People can use it to set up their own servers -- no need to speak to the IT department if they don't want to

## Setting this up yourself

I'M CURRENTLY DEVELOPING THIS. IT'S NOT YET READY FOR GENERAL USE. MANY THINGS MISSING.

* Clone this repository, modify and run `create_vm.sh` from your local machine.  This creates the Azure VM
* Log into the created Azure VM, clone this repo and run `install.sh`

Start the Jupyterjib service with

```
sudo systemctl start jupyterhub
```

Usernames and passwords will be created on the VM in the file users.txt

* Log in to Jupyter using http://Your VM IP Address:8000

```
sudo systemctl daemon-reload
sudo systemctl start jupyterhub
sudo systemctl status jupyterhub
```

## JupyterHub cloud installs elsewhere

The Data Science VM has JupyterHub pre-installed (and JupyterLab on the Ubuntu DSVM) – https://docs.microsoft.com/en-us/azure/machine-learning/data-science-virtual-machine/overview 

Azure Lab Services - https://azure.microsoft.com/en-us/services/lab-services/ 
