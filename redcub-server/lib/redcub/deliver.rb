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
          mails = Model::Localqueue.all(:lock_flg => 0,
                                        :order => [:receive_date])

          mails.each do |mail|
            begin

              transaction do
                File.open("/tmp/mail.txt", "wb") do |f|
                  f.write(mail.data)
                end

                tmail = get_tmail_object(mail.data, @myhostname)

                if tmail.from.nil?
                  tmail.from = mail.mail_from
                end

                user = mail.orig_to.split(/@/)[0]
                from_id = get_address_id(tmail)
                user_id = get_user_id(user)

                filter_id = Model::Filter.filter_id(tmail, user_id)
                
                header = OrderHash.new
                tmail.each_header do |key, value|
                  header[key] = Base64.decode_b(value.to_s).toutf8
                end

                mail_data = Model::MailData.new
                body = get_message_body(tmail).toutf8
                mail_data.message_id = tmail.message_id
                mail_data.receive_date = mail.receive_date
                mail_data.header = header
                mail_data.body = body
                
                new_mail = Model::Mail.new
                new_mail.user_id = user_id
                new_mail.message_id = tmail.message_id
                new_mail.mail_from_id = from_id
                new_mail.filter_id = filter_id
                new_mail.receive_date = mail.receive_date
                new_mail.mail_data = mail_data
                new_mail.attached_files = get_attached_files(user_id, tmail)
                new_mail.subject = tmail.subject.toutf8
                new_mail.body_part = get_string_part(body)
                
                new_mail.save

                mail.destroy
              end
              
              Syslog.info("mail deliverd(Message-ID=#{mail.message_id}).")
              
            rescue Exception
              write_backtrace
            end
          end
        rescue
          write_backtrace
        end

        sleep @interval
      end
    end
  end
end
