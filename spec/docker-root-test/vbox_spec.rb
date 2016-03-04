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
