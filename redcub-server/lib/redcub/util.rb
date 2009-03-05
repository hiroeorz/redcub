module RedCub
  module Util
    module_function

    def write_backtrace
      Syslog.info(format("%s: %s", $!.class, $!.message))
      Syslog.info("backtrace:")
      for line in $!.backtrace
        Syslog.info(line)
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
        return tmail.body
      end

      tmail.parts.each do |part|
        if part.content_type == "text/plain" or
            part.content_type == "text/html"
          return part.body
        end
      end

      return "\r\n"
    end

    def get_message_id(data, hostname)
      message_id = nil

      begin
        tmail = TMail::Mail.parse(data)
        message_id = tmail.msgid
      rescue TMail::SyntaxError
      end

      if !message_id.nil? and !message_id.empty? and
          TMail::Mail.msgid?(message_id)
        return message_id
      end

      return TMail.new_message_id(hostname)
    end
  end
end
