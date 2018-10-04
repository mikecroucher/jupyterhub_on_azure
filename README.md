# Jupyterhub on azure

This repository contains scripts for automatic creation of customised JupyterHub instances running on Azure cloud designed for multi-user classes.  This doesn't (yet) use docker or elastic scaling. It's just a plan old server in the cloud -- albeit one that we can set up and tear down at will. 

People can use it to set up their own servers -- no need to speak to the IT department if they don't want to.

## Setting Up a new server

I'M CURRENTLY DEVELOPING THIS. IT'S NOT YET READY FOR GENERAL USE. MANY THINGS MISSING. DOCUMENTATION IS NOT UP TO DATE.

* Clone this repository, modify and run `create_vm.sh` from your local machine.  This creates the Azure VM
* Log into the created Azure VM, clone this repo and run `install.sh`

## Useful sysadmin notes when using the resulting server

### Adding accounts to sudoers list

When running your course, you may have classroom assistants or other trusted users who you may want to give full sudo access to.
To add `training_user2` to the sudoers list for example:

```
sudo usermod -aG sudo training_user2
```

You'll get the following error messages
```
sent invalidate(passwd) request, exiting
sent invalidate(group) request, exiting
sent invalidate(passwd) request, exiting
sent invalidate(group) request, exiting
```

These are nothing to worry about

### Stopping and starting the JupyterHub service

The JupyterHub service can be stopped, started etc with the following commands

```
sudo systemctl daemon-reload
sudo systemctl start jupyterhub
sudo systemctl stop jupyterhub
sudo systemctl restart jupyterhub
sudo systemctl status jupyterhub
```

## JupyterHub cloud installs elsewhere

If you don't like how this one works, you may like one of the following

The Data Science VM has JupyterHub pre-installed (and JupyterLab on the Ubuntu DSVM) – https://docs.microsoft.com/en-us/azure/machine-learning/data-science-virtual-machine/overview 

Azure Lab Services - https://azure.microsoft.com/en-us/services/lab-services/ 
