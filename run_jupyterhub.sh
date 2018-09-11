#!/bin/bash

#Installing by pip didn't add the jupyterhub binary folder to the path so let's do that now
export PATH=$PATH:~/.local/bin

#Run jupyterhub
jupyterhub
