require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/show" do
  before(:each) do
    @response = request("/show")
  end
end