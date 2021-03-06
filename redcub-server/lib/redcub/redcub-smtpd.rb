module RedCub
  class RedCubSMTPD < SMTPD
    attr_accessor :client_name, :remote_addr, :clamav_scanner

    include Util

    def initialize(sock, domain)
      @config = RedCub::Config.instance
      @myhostname = @config["myhostname"]
      @mydomains = @config["mydomains"]
      @domain_parent_host = @config["sender"]["domain_parent_host"]

      @client_name = nil
      @remote_addr = nil

      @mynetworks = @config["mynetworks"]

      @local_queue = Localqueue.new
      @send_queue = Sendqueue.new

      @clamav_scanner = nil
      @spam_filter = BSFilter.new

      super(sock, domain)
    end

    def data_hook(data)
      Syslog.info("helo=#{@helo_name} from=#{@sender} to=#{@recipients.join(',')}")

      # debug
      File.open("/tmp/mail.txt", "wb") do |f|
        f.write(data)
      end

      begin
        @recipients.each do |rcpt_to|
          name = rcpt_to.split(/@/)[0]
          domain = rcpt_to.split(/@/)[1]
          
          Syslog.info("distributioning mail (#{@sender.gsub(/\%/, '%%')} -> #{rcpt_to.gsub(/\%/, '%%')})")
          
          if @mydomains.include?(domain) and !User.exist?(name) and
              @domain_parent_host.nil?
            raise error("550 Recipient address rejected.")
          end
          
          tmail = get_tmail_object(data, @myhostname)
          
          virus_result = false

          if $clamav_loaded
            virus_result = @clamav_scanner.found_virus?(tmail)
          

            if virus_result
              Syslog.notice("VIRUS MAIL FOUND! messageID: #{tmail.message_id}, virus_type: #{virus_result}")
              Syslog.notice("#{tmail.message_id.gsub(/\%/, '%%')}: not delivered.")
              return false
            else
              Syslog.debug("#{tmail.message_id.gsub(/\%/, '%%')}: no virus found")
            end
          else
              Syslog.debug("#{tmail.message_id.gsub(/\%/, '%%')}: virus scanner not available")
          end
          
          if @config["bsfilter"]
            result, tmail = @spam_filter.spam?(tmail)
          end

          if @mydomains.include?(domain) and User.exist?(name)
            mail_id = save_queue(tmail, rcpt_to, :local)
            Syslog.info("saved to local mail queue id=#{mail_id}")
          else
            mail_id = save_queue(tmail, rcpt_to, :send)
            Syslog.info("saved to send mail queue id=#{mail_id}")
          end
        end

        return true
      rescue Exception
        write_backtrace
        raise MailReceiveError.new
      end
    end

    def rcpt_hook(rcpts)
      rcpts.split(/,/).each do |rcpt|
        Syslog.debug("check rcpt=#{rcpt}")
        array = rcpt.split(/@/)
        
        if array.length != 2 or
            array[0].empty? or array[1].empty?
          raise error("550 Recipient address rejected.")
        end
        
        domain = array[1]
        
        if @mydomains.include?(domain)
          next
        end
        
        unless sender_in_mynetwork?(@remote_addr)
          raise error("550 Recipient address rejected.")
        end
      end
    end
    
    private

    def sender_in_mynetwork?(ip_address)
      @mynetworks.each do |mynetwork|
        array = mynetwork.split(/\//)

        if array.length != 2
          raise ConfigError.new("invalid mynetworks")
        end

        my_address = array[0]
        mask = array[1].to_i

        result = compare_network(my_address, ip_address, mask)

        return result if result
      end

      Syslog.notice("Warning: no mynetworks address connected(#{ip_address})")

      return false
    end

    def compare_network(source_address, target_address, mask = 24)
      s_byte = ""
      t_byte = ""

      source_address.split(/\./).each do |address_part|
        s_byte.concat(format("%08b", address_part.to_i))
      end

      target_address.split(/\./).each do |address_part|
        t_byte.concat(format("%08b", address_part.to_i))
      end

      for i in 0 .. (mask - 1)
        if s_byte[i, 1] != t_byte[i, 1]
          return false
        end
      end

      return true
    end

    def save_queue(tmail, rcpt_to, queue_type = :local)      
      case queue_type
      when :local
        queue = @local_queue
      when :send
        queue = @send_queue
      end
      
      queue.message_id = tmail.message_id
      queue.helo_name = @helo_name
      queue.mail_from = @sender.toutf8
      queue.recipients = @recipients.join(",").toutf8
      queue.orig_to = rcpt_to
      queue.receive_date = Time.now
      queue.data = tmail.encoded
      queue.save_queue
      
      return queue.id
    end
    
    def error(msg)
      Syslog.err(msg)
      super(msg)
    end    
  end

  class MailReceiveError < StandardError
  end

  class ConfigError < StandardError
  end
end
