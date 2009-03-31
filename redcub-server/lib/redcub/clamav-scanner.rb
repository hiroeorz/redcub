module RedCub
  class ClamAVScanner
    def initialize
      @config = Config.instance

      reload_clamav

      @clamav_tmp_dir = @config["clamav"]["tmp_dir"]
      @clamav_refresh_interval = 
        @config["clamav"]["refresh_interval"].to_i * 60 * 60

      File.makedirs(@clamav_tmp_dir)
    end

    def reload_clamav
      @clamav = ClamAV.new
      @clamav_last_refresh_time = Time.now
    end

    def refresh_if_old
      if @clamav_refresh_interval != 0 and
          (Time.now - @clamav_last_refresh_time) > @clamav_refresh_interval
        
        reload_clamav
        Syslog.notice("ClamAV Reloaded") if Syslog.opened?
      end
    end

    def found_virus?(tmail)
      messageID = tmail.message_id
      data = tmail.encoded

      path = File.join(@clamav_tmp_dir, messageID)

      
      File.open(path, "wb") do |f|
        f.write(data)
      end

      begin
        result = @clamav.scanfile(path, 3)

        if result == 0
          return nil  
        end
        
        return result
      ensure
        File.unlink(path)
      end
    end
  end
end
