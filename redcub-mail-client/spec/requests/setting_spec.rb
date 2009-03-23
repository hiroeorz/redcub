require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/setting" do
  before(:each) do
    @response = request("/setting")
  end
end