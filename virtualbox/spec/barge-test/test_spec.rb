require 'spec_helper'

describe interface('eth0') do
  it { should exist }
  it { should be_up }
end

describe interface('eth1') do
  it { should exist }
  it { should be_up }
  it { should have_ipv4_address("192.168.33.10") }
end

describe routing_table do
  it do
    should have_entry(
      :destination => '192.168.33.0/24',
      :interface   => 'eth1',
      :gateway     => '192.168.33.10',
    )
  end
end

describe docker_image('busybox:latest') do
  it { should exist }
end

describe docker_container('simple-echo') do
  it { should be_running }
end

describe port(8080) do
  it { should be_listening }
end
