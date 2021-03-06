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
          mails = Localqueue.all(:lock_flg => 0,
                                 :order => [:receive_date])

          mails.each do |mail|
            begin

              transaction do

                begin
                  # debug
                  File.open("/tmp/mail.txt", "wb") do |f|
                    f.write(mail.data)
                  end

                  if mail.data.nil?
                    mail.destroy
                    Syslog.info("mail cannot deliverd(Message-ID=#{mail.message_id.gsub(/\%/, '%%')}).")
                    
                    next
                  end

                  tmail = get_tmail_object(mail.data, @myhostname)
                  
                  if tmail.from.nil?
                    tmail.from = mail.mail_from
                  end
                  
                  user = mail.orig_to.split(/@/)[0]
                  from_id = get_address_id(tmail)
                  user_id = get_user_id(user)
                  
                  filter_id = Filter.filter_id(tmail, user_id)
                  
                  header = OrderHash.new
                  tmail.each_header do |key, value|
                    header[key] = Base64.decode_b(value.to_s).toutf8
                  end
                  
                  body, content_type = get_message_body(tmail)
                  Syslog.debug("mail_type: #{content_type}")
                  
                  new_mail = Mail.new
                  new_mail.user_id = user_id
                  new_mail.message_id = tmail.message_id
                  new_mail.mail_from_id = from_id
                  new_mail.filter_id = filter_id
                  new_mail.receive_date = mail.receive_date
                  new_mail.subject = tmail.subject.toutf8
                  new_mail.body_part = get_string_part(body)
                  new_mail.content_type = content_type
                  
                  new_mail.data = tmail.encoded
                  new_mail.header = header
                  new_mail.attached_files = get_attached_files(user_id, tmail)
                  
                  new_mail.save
                  
                  mail.destroy


                  Syslog.info("mail deliverd(Message-ID=#{mail.message_id.gsub(/\%/, '%%')}).")
                rescue
                  sleep(5)
                end
              end
              
              
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
