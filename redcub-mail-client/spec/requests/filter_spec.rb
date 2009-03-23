require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/filter" do
  before(:each) do
    @response = request("/filter")
  end
end