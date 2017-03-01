require 'spec_helper'
describe 'verdaccio' do

  context 'with defaults for all parameters' do
    it { should contain_class('verdaccio') }
  end
end
