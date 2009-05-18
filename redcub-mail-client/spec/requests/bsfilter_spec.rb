require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/bsfilter" do
  before(:each) do
    @response = request("/bsfilter")
  end
end