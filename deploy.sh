#!/bin/bash

vagrant plugin uninstall vagrant-esxi
rm vagrant-esxi-0.4.0.gem
gem build vagrant-esxi.gemspec
vagrant plugin install vagrant-esxi-0.4.0.gem