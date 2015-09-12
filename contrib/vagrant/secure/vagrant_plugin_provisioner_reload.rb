# [Vagrant Reload Provisioner](https://github.com/aidanns/vagrant-reload)
# Copyright (c) 2013 Aidan Nagorcka-Smith
# Licensed under the MIT license
# https://github.com/aidanns/vagrant-reload/blob/master/LICENSE.txt

module VagrantPlugins
  module Reload
    class Plugin < Vagrant.plugin("2")
      name "reload"
      description <<-DESC
      Allows a VM to be reloaded as a provisioning step.
      DESC

      provisioner(:reload) do
        class Provisioner < Vagrant.plugin("2", :provisioner)
          def provision
            options = {}
            options[:provision_ignore_sentinel] = false
            @machine.action(:reload, options)
            begin
              sleep 5
            end until @machine.communicate.ready?
          end
        end
        Provisioner
      end
    end
  end
end
