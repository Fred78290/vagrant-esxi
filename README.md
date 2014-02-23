# Vagrant ESXi Provider

This is a Vagrant plugin for VMware ESXi. Virtual vagrant machines are cloned 
from an other virtual machine located on your ESXi host. Boxes are not used 
yet, the box name specifies the name of your template virtual machine.
Just create a vagrant compatible virtual machine on the ESXi host 
(see below) and use it as template.

**NOTE:** This is a work in progress, it's forked from
[vagrant-esxi](https://github.com/pdericson/vagrant-esxi) and originally derived from
[vagrant-vsphere](https://github.com/nsidc/vagrant-vsphere) 
and [vagrant-aws](https://github.com/mitchellh/vagrant-aws).

**WARNING:** vagrant-esxi is for standalone ESXi hosts only. If you are 
using a vSphere Server managing datacenters, use 
[vagrant-vsphere](https://github.com/nsidc/vagrant-vsphere). 
Otherwise your datacenter configuration may break.

## Plugin Installation

    git clone https://github.com/swobspace/vagrant-esxi.git
    cd vagrant-esxi
    gem build vagrant-esxi.gemspec
    vagrant plugin install vagrant-esxi

## ESXi Host Setup

1. enable SSH
2. enable public key authentication, e.g. `cat ~/.ssh/id_rsa.pub | ssh root@host 'cat >> /etc/ssh/keys-root/authorized_keys'`
3. set the license key (if you haven't done so already), e.g. `ssh root@host vim-cmd vimsvc/license --set 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX'`

## Create a Template VM

vagrant-esxi uses an existing virtual machine as template for creating 
further virtual machines.  Just create a virtual machine as usual 
(i.e. with the vSphere client) and make it vagrant compatible. 
For example we create a virtual machine running debian wheezy with the name "wheezy".

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

`config.vm.box` contains the template name. The corresponding template 
configuration file must exist in your datastore under 
`/vmfs/volumes/<datastore>/<template name>/<template name>.vmx` 
(i.e. `/vmfs/volumes/datastore1/wheezy/wheezy.vmx`).

    Vagrant.configure("2") do |config|
      config.vm.box = "wheezy"
      config.vm.box_url = "http://files.vagrantup.com/just_an_unused_dummy_yet.box"
      config.vm.hostname = "mywheezy"

      config.vm.provider :esxi do |esxi|
        esxi.name = "mywheezy"
        esxi.host = "host"
        esxi.datastore = "datastore1"
        esxi.user = "root"
      end
    end

## Issues

https://github.com/swobspace/vagrant-esxi/issues
