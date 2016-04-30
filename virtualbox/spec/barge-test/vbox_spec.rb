require 'spec_helper'

describe kernel_module('vboxsf') do
  it { should be_loaded }
end

describe kernel_module('vboxguest') do
  it { should be_loaded }
end

describe file('/vagrant') do
  it { should be_mounted }
end

describe file('/sbin/VBoxService') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_executable.by('owner') }
end

describe file('/bin/VBoxControl') do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_executable.by('owner') }
end

describe process("/sbin/VBoxService") do
  it { should be_running }
  its(:count) { should eq 1 }
  its(:user) { should eq "root" }
  its(:args) { should match /--timesync-set-start\b/ }
  its(:args) { should match /--timesync-set-threshold 10000\b/ }
  its(:args) { should match /--disable-automount\b/ }
end
