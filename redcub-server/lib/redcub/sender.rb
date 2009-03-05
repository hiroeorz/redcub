module RedCub  
  class Sender < Daemon
    include Util

    def initialize
      super("sender")
      @interval = @config["sender"]["interval"].to_i
      @max_send_count = @config["sender"]["max_send_count"].to_i
      @myhostname = @config["myhostname"]

      Syslog.info("sender is ready.")
    end

    def start
      super

      QueueDB.open do |db|
        loop do
          begin
            mails = db.query("select * from send_mailqueue
                                order by receive_date")
            mails.each do |mail|
              begin
                send_mail(mail.data, mail.sender, mail.orig_to)
                db.exec("delete from send_mailqueue where message_id = %s",
                        mail.message_id)
              
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
    end

    private

    def resolv_mx(mx_name)
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
      mx_name = to.split(/@/)[1]
      servers = resolv_mx(mx_name)
      
      servers.each do |server|
        Net::SMTP.start(server, 25, @myhostname) do |s|
          begin
            s.send_mail(mail_data, from, [to])
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
