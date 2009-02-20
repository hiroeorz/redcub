lib_path = File.expand_path(File.dirname(__FILE__))

if ENV["RUBYLIB"].nil?
  ENV["RUBYLIB"] = lib_path
else
  ENV["RUBYLIB"] = lib_path + ":" + ENV["RUBYLIB"]
end

begin
  require "rubygems"
rescue
end

require "socket"
require "net/smtp"
require "syslog"
require "resolv"
require "digest/md5"
require "jcode"
require "tmail"
require "hbase"
require "getoptlong"

require "smtpd"
require "popd"
require "order-hash.rb"

require "redcub/config"
require "redcub/util"
require "redcub/redcub-smtpd"
require "redcub/redcub-popd"
require "redcub/database"
require "redcub/queue-db"
require "redcub/hbase-table.rb"
require "redcub/daemon"
require "redcub/receiver"
require "redcub/sender"
require "redcub/deliver"
require "redcub/mail-box"
require "redcub/mail-box-db"
require "redcub/pop-server"

module RedCub
  LOG_FACILITIES = {
    "kern" => Syslog::LOG_KERN,
    "user" => Syslog::LOG_USER,
    "mail" => Syslog::LOG_MAIL,
    "daemon" => Syslog::LOG_DAEMON,
    "auth" => Syslog::LOG_AUTH,
    "syslog" => Syslog::LOG_SYSLOG,
    "lpr" => Syslog::LOG_LPR,
    "news" => Syslog::LOG_NEWS,
    "uucp" => Syslog::LOG_UUCP,
    "cron" => Syslog::LOG_CRON,
    "authpriv" => Syslog::LOG_AUTHPRIV,
    "ftp" => Syslog::LOG_FTP,
    "local0" => Syslog::LOG_LOCAL0,
    "local1" => Syslog::LOG_LOCAL1,
    "local2" => Syslog::LOG_LOCAL2,
    "local3" => Syslog::LOG_LOCAL3,
    "local4" => Syslog::LOG_LOCAL4,
    "local5" => Syslog::LOG_LOCAL5,
    "local6" => Syslog::LOG_LOCAL6,
    "local7" => Syslog::LOG_LOCAL7,
    "local8" => Syslog::LOG_LOCAL2
  }  
end

