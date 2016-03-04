require 'spec_helper'

describe user('docker') do
  it { should exist }
  it { should belong_to_group 'docker' }
  it { should belong_to_primary_group 'docker' }
  it { should have_uid 1000 }
  it { should have_home_directory '/home/docker' }
  it { should have_login_shell '/bin/bash' }
end

describe group('docker') do
  it { should exist }
  it { should have_gid 1000 }
end

describe 'Docker Daemon' do
  context command('/etc/init.d/docker status') do
    its(:stdout) { should match /^Docker .* is running.$/ }
  end

  context file('/var/run/docker.sock') do
    it { should be_socket }
  end

  context interface('docker0') do
    it { should exist }
    it { should be_up }
  end

  context routing_table do
    it do
      should have_entry(
        :destination => '172.17.0.0/16',
        :interface   => 'docker0',
        :gateway     => '172.17.0.1',
      )
    end
  end
end

describe 'Linux kernel parameters' do
  context linux_kernel_parameter('net.ipv4.ip_forward') do
    its(:value) { should eq 1 }
  end

  context linux_kernel_parameter('net.ipv6.conf.all.forwarding') do
    its(:value) { should eq 1 }
  end
end
