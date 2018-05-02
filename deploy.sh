#!/bin/bash

vagrant plugin uninstall vagrant-esxi
rm vagrant-esxi-0.3.6.gem
gem build vagrant-esxi.gemspec
vagrant plugin install vagrant-esxi-0.3.6.gem