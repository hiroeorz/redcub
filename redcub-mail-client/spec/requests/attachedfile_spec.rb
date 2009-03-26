require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/attachedfile" do
  before(:each) do
    @response = request("/attachedfile")
  end
end