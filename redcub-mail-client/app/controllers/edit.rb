# -*- coding: utf-8 -*-

class Edit < Application
  include RedCub

  before :ensure_authenticated

  def index
    render
  end

  def new
    @mail = Model::Mail.new
    @to = ""
    @subject = ""
    @body = ""
    render :edit, :layout => false
  end

  def return_mail
    mail = Model::Mail.first(:id => params[:id])

    @to = mail.mail_from.friendly_address
    @subject = "Re: ".concat(mail.subject)

    mail_body = mail.body.gsub(/\n|\r\n/, "\n>")
    mail_body.chop! #一つ余計についた">"を削除
    mail_body = ">" + mail_body
    @body = mail_body

    partial :edit
  end

  def sendmail
    user = Model::User.first(:id => session.user.id)

    tmail = TMail::Mail.new
    tmail.from = user.friendly_encoded_address
    tmail.to = params[:to]
    tmail.subject = NKF.nkf("-j --utf8-input", params[:subject])
    tmail.mime_version = "1.0"
    tmail.date = Time.now
    tmail.body = NKF.nkf("-j --utf8-input", params[:body].to_s)
    tmail.message_id = TMail.new_message_id(Merb::Config[:hostname])

    tmail.content_transfer_encoding = "7bit"
    tmail.content_type = "text/plain; charset=ISO-2022-JP"

    Merb.logger.debug("encoded code: #{tmail.encoded}")

    smtp = Net::SMTP.new(Merb::Config[:mailer][:host], 
                         Merb::Config[:mailer][:port])
    smtp.start do |s|
      s.send_mail(tmail.encoded, user.mailaddress, tmail.to)
    end

    header = OrderHash.new
    tmail.each_header do |key, value|
      header[key] = value.to_s.toutf8
    end

    new_mail = Model::Mail.new
    new_mail.user_id = session.user.id
    new_mail.message_id = tmail.message_id
    new_mail.mail_from_id = RedCub::Util.get_address_id(tmail)
    new_mail.receive_date = Time.now

    new_mail.attached_files = 
      RedCub::Util.get_attached_files(session.user.id, tmail)

    new_mail.subject = tmail.subject.toutf8
    new_mail.body_part = RedCub::Util.get_string_part(params[:body].to_s)
    new_mail.sended = true
    new_mail.filter_id = -2 # send mail filter_id: -2

    new_mail.data = tmail.encoded
    new_mail.header = header

    new_mail.save
    ""
  end

  def upload
    user = Model::User.first(:id => session.user.id)

    tmp = Tempfile.new("spec")
    path = File.join(tmp.path, user.id.to_s, 
                     Time.now.strftime("%Y%m%d%H%M%S"))

    begin
      file = open(path, "w+")
#      multipart_post(resource(:matirials),
#                     :material => (:id => nil, 
#                                   :label => "test", 
#                                   :file => file))
      tmp.close
    ensure
      file.close
      File.unlink(path)
    end
  end

  def get_message_id(tmail)
    message_id = tmail.message_id

    if !message_id.nil? and !message_id.empty? and
        TMail::Mail.message_id?(message_id)
      return tmail
    end

    hostname = Merb::Config[:hostname]
    message_id = TMail.new_message_id(hostname)
    return message_id
  end
end
