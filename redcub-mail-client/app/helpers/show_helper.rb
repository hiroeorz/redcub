module Merb
  module ShowHelper
    def tray_image_tag(filter)
      if filter.unread_mail_count == 0
        return image_tag("tray_empty.png")
      end

      return image_tag("tray.png")
    end
  end
end # Merb
