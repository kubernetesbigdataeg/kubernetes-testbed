# -*- mode: ruby -*-
# vim: set ft=ruby ts=2 et :

VAGRANTFILE_API_VERSION = "2"

# Tested with Vagrant version:
Vagrant.require_version ">= 1.7.2"

# Require YAML module
require 'yaml'

def fail_with_message(msg)
    fail Vagrant::Errors::VagrantError.new, msg
end

# Read YAML file with cluster details
config_file = 'config/cluster.yaml'
if File.exists?(config_file)
    cluster = YAML.load_file(config_file)
else
    fail_with_message "#{config_file} was not found."
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Disabling the default /vagrant share
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.ssh.insert_key = false

  cluster.each do |servers|
    # VM definition
    config.vm.define servers["name"] do |node|
      node.vm.box = servers["box"]
      node.vm.hostname = servers["name"]
      node.vm.network "private_network", ip: servers["ip"]
      node.vm.provider :libvirt do |domain|
        domain.uri = 'qemu+unix:///system'
        # https://github.com/vagrant-libvirt/vagrant-libvirt/issues/986
        domain.qemu_use_session = false
        domain.driver = 'kvm'
        domain.memory = servers["mem"]
        domain.cpus = servers['cpu']
        if servers.key?('aditional_disk')
            for disk in servers['aditional_disk']
                    domain.storage :file, :size => disk
            end
        end
      end
    end # define
  end # cluster
end # vagrant
