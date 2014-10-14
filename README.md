puppet-master-of-masters
========================
Trying to trigger a jenkins job
This project contains a vagrant environment that defines a puppet enterprise (PE) master-of-masters topology that consists of 4 VMs

* Master-of-masters (MoM)
    * monolithic PE master
    * manages the tenant PE master VMs
* Tenant puppet master
    * PE split compile master
    * manages tenant agents
* Tenant puppetdb
    * PE split puppetdb
    * Stores facts, reports, catalogs for a tenant infrastructure
* Tenant console
    * PE split console (dashboard)
    * displays reports for a tenant infrastructure
    * does live management for a tenant infrastructure

## Prerequisites

* At least 8 GB of RAM. The VMs defined here are configured to use 8 GB. You can adjust the configs if you wish, but 8 GB is the recommended minimum for this configuration
* A Puppet Enterprise installer.
    * Must be 3.3.x
    * The installer should be placed in the root of this project after you clone it
    * Do not extract the installer. The VM provisioning scripts will handle that
    * The installer will be .gitignored, so you don't have to worry about accidentally committing it to your repo.

## VM Definitions

This project uses my [data-driven-vagrantfile](https://github.com/gsarjeant/data-driven-vagrantfile) to define the virtual machines in yaml format. There is extensive documentation of the Vagrantfile at the data-driven-vagrantfile [project wiki](https://github.com/gsarjeant/data-driven-vagrantfile/wiki). Briefly, the VMs described above are defined in the vagrant.yml file distributed with this project. They should work with no modification to create the VMs and do the appropriate PE installation on each. If you would like to make any modifications to the VMs, change the settings in vagrant.yml. You should not need to make any modifications to the Vagrantfile itself.

## Usage

You should be able to create the VMs by doing the following

* Download the PE installer and place it in the project root directory.
* Enter `vagrant up` at a command prompt.

This will create the VMs in the proper order. The VMs will be provisioned using two scripts in the **provision** directory.

* **hosts.sh**: creates host file entries for each vm, so that they can resolve each other by name
* **pe.sh**: Installs puppet enterprise on a target system. Accepts two arguments:
    * PE_INSTALLER_NAME: The filename (no path) of the PE installer to be used when provisioning the VMs. This file must exist in the project root directory before creating VMs.
    * ANSWER_FILE_NAME: The name of the answer file (no path) that will be used to install PE. This file must exist in the **answers** folder of this project. Suitable answer files are distributed with the project. See the [Puppet Labs automated installation documentation](https://docs.puppetlabs.com/pe/latest/install_automated.html) for more information about the answer file syntax.

## Post-install requirements

In order for the master-of-masters to manage the tenant puppet infrastructure, you must do some manual post-configuration. In brief:

* Modify puppet.conf to point to the MoM as its server and certificate authority.
* Move /etc/puppetlabs/puppet/ssl on all three tenant PE servers (but **NOT** on the MoM)
* Regenerate agent certificates on each tenant PE VM
    * puppet agent -t --server pe-mom.example.com
* Copy pe-internal certs from the MoM to the correct locations on each tenant VM

I will add more detailed documentation of these steps in a later commit.

## To-do

There are a few things I'd like to do to make this a bit more of a self-contained demo

* Add more detailed documentation of the provisioning process
* Automate the internal certificate transfer during vagrant provisioning
* Use puppet to move the certificates into place from the MoM after reconfiguring agents
