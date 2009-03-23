module Merb
  module GlobalHelpers
    # helpers defined here available to all views.  

    def today?(time)
      now = Time.now

      if now.year == time.year and
          now.month == time.month and
          now.day == time.day
        return true
      end

      return false
    end

    def br(str)
      return str.gsub(/\r\n|\n/, "<br />")
    end

    def list_class(mail)
      if mail.readed?
        return "one-of-list-readed"
      else
        return "one-of-list"
      end
    end
  end
end
