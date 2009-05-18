
$KCODE = "UTF-8"

lib_path = File.expand_path(File.dirname(__FILE__))

begin
  require "rubygems"
rescue LoadError
end

$clamav_loaded = false
begin
  require "clamav"
  $clamav_loaded = true
rescue LoadError
end

require "socket"
require "net/smtp"
require "syslog"
require "resolv"
require "digest/md5"
require "jcode"
require "tmail"
require "getoptlong"
require "dm-core"
require "dm-aggregates"
require "mogilefs"
require "base64"
require "zlib"
require "ftools"
require "sanitize"

require "smtpd"
require "popd"
require "order-hash.rb"

require "redcub/config"
require "redcub/util"
require "redcub/redcub-smtpd"
require "redcub/redcub-popd"
require "redcub/daemon"
require "redcub/receiver"
require "redcub/sender"
require "redcub/deliver"
require "redcub/pop-server"
require "redcub/clamav-scanner"

require "redcub/model/model"
require "redcub/model/queue"
require "redcub/model/localqueue"
require "redcub/model/sendqueue"
require "redcub/model/address"
require "redcub/model/host"
require "redcub/model/user"
require "redcub/model/attached-file"
require "redcub/model/filter"
require "redcub/model/mail"

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

DataMapper.setup(:default, {
                   :adapter => "mysql",
                   :database => "redcub_mailbox",
                   :host => "vdsv04",
                   :username => "mysql",
                   :password => "system",
                   :encoding => "utf8"
                 })

