require "rubygems"
require "merb-core"

Merb::Config.setup(:merb_root => ".",
	           :environment => ENV['RACK_ENV'])
Merb.environment = "production"
Merb.root = Merb::Config[:merb_root]
Merb::BootLoader.run

if prefix = ::Merb::Config[:path_prefix]
  use Merb::Rack::PathPrefix, prefix
end

#ENV["INLINEDIR"] = "/home/shin/tmp/merb-cache"

run Merb::Rack::Application.new
