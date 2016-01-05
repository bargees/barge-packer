# A dummy plugin for DockerRoot to set hostname and network correctly at the very first `vagrant up`
module VagrantPlugins
  module GuestLinux
    class Plugin < Vagrant.plugin("2")
      guest_capability("linux", "change_host_name") do
        Cap::ChangeHostName
      end

      guest_capability("linux", "configure_networks") do
        Cap::ConfigureNetworks
      end
    end
  end
end

Vagrant.configure(2) do |config|
  config.vm.define "docker-root-test"

  config.vm.box = "docker-root"

  config.vm.hostname = "docker-root-test.example.com"

  config.vm.network "private_network", ip: "192.168.33.10"

  config.vm.synced_folder ".", "/vagrant"
# config.vm.synced_folder ".", "/vagrant", type: "nfs", mount_options: ["nolock", "vers=3", "udp"]

  config.vm.provider :virtualbox do |vb|
    vb.name = "docker-root-test"
    vb.gui = true
  end

  if Vagrant.has_plugin?("vagrant-triggers") then
    config.trigger.after [:up, :resume] do
      info "Adjusting datetime after suspend and resume."
      run_remote "sudo sntp -4sSc pool.ntp.org; date"
    end
  end

  # Adjusting datetime before provisioning.
  config.vm.provision :shell, run: "always" do |sh|
    sh.inline = "sntp -4sSc pool.ntp.org; date"
  end

  config.vm.provision :docker do |docker|
    docker.pull_images "busybox"
    docker.run "simple-echo",
      image: "busybox",
      args: "-p 8080:8080 --restart=always",
      cmd: "nc -p 8080 -l -l -e echo hello world!"
  end

  config.vm.network :forwarded_port, guest: 8080, host: 8080
end
