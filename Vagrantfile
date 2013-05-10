# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "debian-6.0.3-i386"
  config.vm.network :forwarded_port, guest: 4567, host: 8080
  # config.vm.synced_folder "../data", "/vagrant_data"
  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "manifests"
    puppet.manifest_file  = "init.pp"
  end
end
