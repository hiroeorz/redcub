require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/edit" do
  before(:each) do
    @response = request("/edit")
  end
end