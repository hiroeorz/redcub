module RedCub
  class BSFilter
    def initialize
      @config = RedCub::Config.instance
      @command = @config["bsfilter"]["command"]
      @tmp_dir = @config["bsfilter"]["tmp_dir"]; File.makedirs(@tmp_dir)
      @spam_mark = @config["bsfilter"]["spam_mark"]
      @spam_score = @config["bsfilter"]["spam_score"].to_f
    end

    def spam?(tmail)
      messageID = tmail.message_id
      data = tmail.encoded
      
      path = File.join(@tmp_dir, messageID)
      result = false

      begin
        File.open(path, "wb") do |f|
          f.write(data)
        end
        
        command = "#{@command} \"#{path}\" 2>&1"
        msg = `#{command}`.strip
        score = msg.split(/\s/)[-1].to_f
        result = (score >= @spam_score)

        Syslog.debug("spam filter command: #{command}")
        Syslog.debug("spam filter: #{msg}")
        Syslog.info("spam score: #{score}")
        Syslog.info("spam result: #{result.to_s}")

        if result
          tmail["x-spam-flag"] = "YES"
          tmail["x-spam-status"] = "YES"
          tmail.subject = "#{@spam_mark}#{tmail.subject}"
        else
          tmail["x-spam-flag"] = "NO"
          tmail["x-spam-status"] = "NO"
        end
      rescue Exception => e
        Syslog.err("error in bsfiltering! #{e.class} #{e.message.gsub(/\%/, '\\%')}")
        return false, tmail
      ensure
        File.unlink(path) if File.exist?(path)
      end

      return result, tmail
    end
  end
end
