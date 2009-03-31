module RedCub  
  class Sender < Daemon
    include Util

    def initialize
      super("sender")
      @interval = @config["sender"]["interval"].to_i
      @max_send_count = @config["sender"]["max_send_count"].to_i
      @myhostname = @config["myhostname"]
      @mydomains = @config["mydomains"]
      @relay_hosts = @config["sender"]["relay_hosts"]
      @domain_parent_host = @config["sender"]["domain_parent_host"]
      
      Syslog.info("sender is ready.")
    end

    def start
      super

      loop do
        begin
          mails = Model::Sendqueue.all(:lock_flg => 0,
                                       :order => [:receive_date])

          mails.each do |mail|
            begin
              send_mail(mail.data, mail.mail_from, mail.orig_to)
              mail.destroy
              
              Syslog.info("mail sended(message_id=#{mail.message_id}).")
            rescue Exception
              write_backtrace
            end
          end
        rescue Exception
          write_backtrace
        end
        
        sleep @interval
      end
    end

    private

    def resolv_mx(mx_name)
      Syslog.debug("mx_name: #{mx_name}")
      records = Resolv::DNS.new.getresources(mx_name, 
                                             Resolv::DNS::Resource::IN::MX)
      names_with_preference = records.collect { |r|
        [r.preference, r.exchange.to_s]
      }

      names_with_preference.sort!

      names = []

      names_with_preference.each do |n|
        names.push(n[1])
      end

      return names
    end

    def send_mail(mail_data, from, to)
      name = to.split(/@/)[0]
      mx_name = to.split(/@/)[1]

      if @mydomains.include?(mx_name) and !Model::User.exist?(name)
        servers = [@domain_parent_host]
      else
        if @relay_hosts.nil?
          servers = resolv_mx(mx_name)
        else
          servers = @relay_hosts.dup
        end
      end 

      servers.each do |server|
        Net::SMTP.start(server, 25, @myhostname) do |s|
          begin
            Syslog.info("connecting to #{server}...")
            s.send_mail(mail_data, from, [to])
            Syslog.info("disconnect from #{server}.")
            return true
          rescue Exception
            write_backtrace
          end
        end
      end
      
      return false
    end
  end
end
