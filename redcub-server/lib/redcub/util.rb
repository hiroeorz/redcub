module RedCub
  module Util
    module_function

    def write_backtrace
      Syslog.err(format("%s: %s", $!.class, $!.message))
      Syslog.err("backtrace:")
      for line in $!.backtrace
        Syslog.err(line)
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

    def get_tmail_object(data, hostname)
      message_id = nil

      tmail = TMail::Mail.parse(data)
      message_id = tmail.message_id

      if !message_id.nil? and !message_id.empty? and
          TMail::Mail.message_id?(message_id)
        return tmail
      end

      message_id = TMail.new_message_id(hostname)
      tmail.message_id = message_id
      return tmail
    end

    def transaction(model)
      trs = DataMapper::Transaction.new(model)
      trs.begin
      aborted = false

      begin
        yield
      rescue Exception => e
        trs.rollback
        aborted = true
        raise e.class.new(e.message)
      ensure
        trs.commit unless aborted
      end
    end
  end
end
