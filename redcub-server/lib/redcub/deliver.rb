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

      loop do
        begin
          mails = Model::Localqueue.all(:order => [:receive_date])

          mails.each do |mail|
            begin
              transaction(Model::Mail) do
                transaction(Model::MailData) do
                  tmail = mail.data
                  
                  user = mail.orig_to.split(/@/)[0]
                  from_id = get_address_id(mail.mail_from)
                  user_id = get_user_id(user)
                                    
                  mail_data = Model::MailData.new
                  
                  if tmail.multipart?
                    
                  else
                    mail_data.message_id = tmail.message_id
                    mail_data.data = tmail
                    mail_data.subject = tmail.subject.toutf8
                    mail_data.receive_date = mail.receive_date
                    mail_data.body = tmail.body.toutf8
                    mail_data.save
                  end

                  new_mail = Model::Mail.new
                  new_mail.message_id = tmail.message_id
                  new_mail.mail_from_id = from_id
                  new_mail.mail_to_id = user_id
                  new_mail.receive_date = mail.receive_date
                  new_mail.subject = tmail.subject.toutf8
                  new_mail.mail_data_id = mail_data.id
                  new_mail.save

                  mail.destroy
                  Syslog.info("mail deliverd(Message-ID=#{mail.message_id}).")
                end
              end

            rescue
              write_backtrace
            end
          end
        rescue
          write_backtrace
        end

        sleep @interval
      end
    end

    private

    def get_address_id(address)
      record = Model::Address.first(:value => address)
      
      unless record.nil?
        return record.id
      end

      record = Model::Address.new
      record.value = address
      record.save
      return record.id
    end

    def get_user_id(username)
      user = Model::User.first(:name => username)

      if user.nil?
        raise ArgumentError.new("no such user '#{username}'")
      end

      return user.id
    end
  end
end
