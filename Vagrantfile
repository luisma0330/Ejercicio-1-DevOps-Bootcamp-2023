# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
    #config.vm.box = "generic/ubuntu2204"
    config.vm.box = "hashicorp/bionic64"
    config.vm.network "private_network", ip: "192.168.56.102"
    config.vm.network "forwarded_port", guest: 80, host: 8081 #localhost
    config.vm.network "forwarded_port", guest: 22, host: 2222 #ssh
    config.vm.network "forwarded_port", guest: 8080, host: 1234 #alternative port
    config.vm.network "forwarded_port", guest: 8000, host: 1256 #alternative port
    config.vm.network "forwarded_port", guest: 3306, host: 1260 #mysql
    config.vm.hostname = "lojeda"
    config.vm.synced_folder ".", "/syncd", disabled: false
    config.vm.disk :disk, size: "50GB", primary: true
    config.vm.provider "virtualbox" do |vb|
       vb.memory = "2048"
       vb.cpus = "1"
       vb.name = "devops"#nombre de la maquina virtual
    end
  
    config.vm.provision "shell", inline: <<-SHELL
        echo "-------------------- Updating package lists"
        sudo apt-get update -y
        sudo apt install -y git curl wget
        git config --global user.email "luisma0330@hotmail.com"
        git config --global user.name "Luis Ojeda" 
    SHELL
  end