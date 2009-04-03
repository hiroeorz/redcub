# -*- coding: utf-8 -*-
module RedCub
  module Util
    module_function

    def write_backtrace
      if Syslog.opened?
        Syslog.err("%s: %s", $!.class, $!.message)
        Syslog.err("backtrace:")
        for line in $!.backtrace
          Syslog.err(line)
        end
      end
    end

    def escape_html_tag(str)
      return str.gsub(/<.*?>/, "")
    end

    def get_dispotion_filenames(tmail)
      filenames = []

      tmail.parts.each do |part|
        if part['content-disposition']
          filenames.push(part['content-disposition']['filename'])
        end
      end

      return filenames
    end

    def get_message_body(tmail)
      unless tmail.multipart?
        return tmail.body.toutf8, tmail.content_type
      end

      if ["multipart/related", 
          "multipart/alternative"].include?(tmail.content_type)
          
        
        html_body = nil
        text_body = nil

        tmail.each_part do |part|
          if ["7bit", "base64", 
              "Quoted-printable"].include?(part.content_transfer_encoding)

            case part.content_type
            when "text/plain"
              text_body = part.body

              if part.content_transfer_encoding == "Quoted-printable"
                text_body = text_body.unpack("M*")[0]
              end

            when "text/html"
              html_body = part.body

              if part.content_transfer_encoding == "Quoted-printable"
                html_body = html_body.unpack("M*")[0]
              end
            end
          end
        end

        unless text_body.nil?
          return text_body.toutf8, "text/plain"
        end

        unless html_body.nil?
          return html_body.toutf8, "text/html"
        end
      end

      tmail.parts.each do |part|
        if ["text/plain", "text/html"].include?(part.content_type) and
            ["7bit"].include?(part.content_transfer_encoding)

          if Syslog.opened?
            Syslog.debug("part content type: #{part.content_type}")
          end

          return part.body.toutf8, part.content_type
        end
      end

      return "\r\n", "text/plain"
    end

    def get_attached_files(user_id, tmail)
      unless tmail.multipart?
        return []
      end

      array = []

      tmail.parts.each do |part|
        case part.content_transfer_encoding
        when "base64", "x-uuencode"
          next if part.disposition_param("filename").nil?

          decoded_filename = 
            Base64.decode_b(part.disposition_param("filename")).toutf8

          attached_file = Model::AttachedFile.new
          attached_file.user_id = user_id
          attached_file.filename = decoded_filename
          attached_file.filetype = part.content_type
          attached_file.filesize = part.body.size
          attached_file.file_data = part.body
          array.push(attached_file)
        end
      end

      return array
    end

    def get_string_part(body, count = 64)
      str = ""
      body = Sanitize.clean(body, Sanitize::Config::RESTRICTED)

      body.each_char do |c|
        str.concat(c)
        break if str.jlength >= count
      end

      return str
    end

    def get_tmail_object(data, hostname)
      message_id = nil

      tmail = TMail::Mail.parse(data)

      message_id = tmail.message_id
      
      # InvalidなDateで送ってくるメールはサーバの現在時刻を振り直す。
      begin
        tmail.date
      rescue ArgumentError => e
        if e.message =~ /time out of range/
          tmail.date = Time.now
        end
      end

      if !message_id.nil? and !message_id.empty?
        return tmail
      end

      message_id = TMail.new_message_id(hostname)
      tmail.message_id = message_id
      return tmail
    end


    def transaction
      trs = DataMapper::Transaction.new(DataMapper.repository(:default))
      trs.begin
      DataMapper.repository(:default).adapter.push_transaction(trs)
      aborted = false

      begin
        yield
      rescue Exception => e
        DataMapper.repository(:default).adapter.pop_transaction
        trs.rollback
        aborted = true
        write_backtrace
        raise e.class.new(e.message)
      ensure
        unless aborted
          DataMapper.repository(:default).adapter.pop_transaction
          trs.commit
        end
      end
    end

    def get_address_id(tmail)
      begin
        if tmail.friendly_from == tmail.from
          address = tmail.from
          name_part = nil
        else
          address = "#{tmail.friendly_from}<#{tmail.from}>".toutf8
          name_part = tmail.friendly_from.toutf8
        end
      rescue NoMethodError
        address = tmail.from
        name_part = nil
      end

      record = Model::Address.first(:value => address)
      
      unless record.nil?
        return record.id
      end

      record = Model::Address.new
      record.value = address
      record.address_part = tmail.from
      record.name_part = name_part
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
