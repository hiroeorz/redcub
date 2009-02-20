module RedCub
  class Deliver < Daemon
    include Util

    def initialize
      super("deliver")
      @interval = @config["deliver"]["interval"].to_i
      @max_send_count = @config["deliver"]["max_send_count"].to_i
      @myhostname = @config["myhostname"]

      Syslog.info("deliver is ready.")
    end

    def start
      super

      QueueDB.open do |db|
        loop do
          begin
            mails = db.query("select * from local_mailqueue
                                order by receive_date")

            mails.each do |mail|
              begin
                user = mail.orig_to.split(/@/)[0]
                mailbox = MailBox.new(user)
                mailbox.save(mail)
                
                Syslog.info("mail deliverd(Message-ID=#{mail.message_id}).")
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
  end
end
