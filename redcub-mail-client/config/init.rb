# Go to http://wiki.merbivore.com/pages/init-rb
 
require 'config/dependencies.rb'

require "tmail"
require "order-hash"
require "net/smtp"
require "syslog"
require "jcode"
require "mogilefs"
require "sanitize"
require "ftools"

require "redcub/util"
require "redcub/config"

use_orm :datamapper
use_test :rspec
use_template_engine :erb

redcub_config = RedCub::Config.instance
 
Merb::Config.use do |c|
  c[:use_mutex] = false

  ##################################
  #                                #
  # if you select datamapper type: #
  #                                #
  # $ rake sessions:create         #
  #                                #
  ##################################

  c[:session_store] = 'datamapper'  # can also be 'memory', 'memcache', 'container', 'datamapper
  
  # cookie session store configuration
  c[:session_secret_key]  = '57f2e643d2296ed0bd3c7cdb84fbe8446caa4eb5'  # required for cookie session store
  c[:session_id_key] = '_redcub-mail-client_session_id' # cookie session id key, defaults to "_session_id"

  c[:hostname] = "eris.komatsuelec.co.jp"
  c[:inline_data_type] = ["image/jpeg", "image/png", "image/gif"]

  c[:mailer] = {
    :host => "127.0.0.1",
    :port => 20025
  }

  c[:bsfilter] = redcub_config["bsfilter"]
end
 
Merb::BootLoader.before_app_loads do
  # This will get executed after dependencies have been loaded but before your app's classes have loaded.

end
 
Merb::BootLoader.after_app_loads do
  # This will get executed after your app's classes have been loaded.
end

