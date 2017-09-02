# Vagrant ESXi Provider

This is a Vagrant plugin for VMware ESXi.

## Goal
It's to continue the stop development of the original plugin and add new features

  This version support new features such as num of cpus, memory size, vmx properties, vagrant box instead use VM cloning.

## Work in progress

  Add second NIC for public network
  Set IP address to NIC
  
## Prerequistes

  You must install ovftool on your computer running vagrant.

**NOTE:** This is a work in progress, it's forked from
[vagrant-esxi](https://github.com/swobspace) and originally derived from
[vagrant-vsphere](https://github.com/nsidc/vagrant-vsphere) 
and [vagrant-aws](https://github.com/mitchellh/vagrant-aws).

**WARNING:** vagrant-esxi is for standalone ESXi hosts only. If you are 
using a vSphere Server managing datacenters, use 
[vagrant-vsphere](https://github.com/nsidc/vagrant-vsphere). 
Otherwise your datacenter configuration may break.

## Plugin Installation

    git clone https://github.com/Fred78290/vagrant-esxi.git
    cd vagrant-esxi
    gem build vagrant-esxi.gemspec
    vagrant plugin install vagrant-esxi

## ESXi Host Setup

1. enable SSH
2. enable public key authentication, e.g. `cat ~/.ssh/id_rsa.pub | ssh root@host 'cat >> /etc/ssh/keys-root/authorized_keys'`
3. set the license key (if you haven't done so already), e.g. `ssh root@host vim-cmd vimsvc/license --set 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX'`

## Create a Template VM

This vagrant-esxi uses vagrant box or vagrant box_url to create virtual machines.
You need to install ovftool on your host to allow import vagrant box to your esxi.

You need also create a vagrant box for esxi provider
(i.e. with the vSphere client or VMWare Fusion/Workstation) and make it vagrant compatible. 
For example we create a virtual machine running ubuntu xenial with the name "xenial64".

1. Install at least ssh, sudo, rsync
2. Install vmware-tools provided by your esxi installation. 
You need linux-headers-amd64 (for 64bit architecture), gcc and make. This is essential.
Vagrant will fail if vmware-tools are not up and running.
3. Create the user vagrant: `useradd --comment "Vagrant User" -m vagrant`. You don't need a  password for user `vagrant`.
4. Install the vagrant public key 
from [vagrant insecure keypair](https://github.com/mitchellh/vagrant/tree/master/keys)
as `~vagrant/.ssh/authorized_keys` 
5. Add the following line to /etc/sudoers using the command `visudo`:

   `vagrant ALL=NOPASSWD: ALL`

For additional information see [Vagrant: create a base box](http://docs.vagrantup.com/v2/boxes/base.html) and
[Vagrant: VMware/Boxes](http://docs.vagrantup.com/v2/vmware/boxes.html)

## Example Vagrantfile

    Your box must contains an OVF or OVA file

    Vagrant.configure("2") do |config|
      config.vm.box = "xenial64"
      config.vm.box_url = "http://somewhere.com/xenial64_as_ovf.box"
      config.vm.hostname = "myhost"

      config.vm.provider :esxi do |esxi|
        esxi.name = "XENIAL_VM"
        esxi.host = "host"
        esxi.datastore = "datastore1"
        esxi.user = "root"
        esxi.password = "password"
        esxi.add_hd = 1024
        esxi.memory_mb = 8192
        esxi.cpu_count = 4
        esxi.vmx["sata0.present"] = "FALSE"
      end
    end

## Issues

https://github.com/Fred78290/vagrant-esxi/issues
