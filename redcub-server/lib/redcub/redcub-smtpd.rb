module RedCub
  class RedCubSMTPD < SMTPD
    attr_accessor :client_name, :remote_addr

    include Util

    def initialize(sock, domain)
      @config = Config.instance
      @myhostname = @config["myhostname"]
      @mydomains = @config["mydomains"]

      @client_name = nil
      @remote_addr = nil

      @local_queue = @config["hbase_table"]["local_queue"]
      @send_queue = @config["hbase_table"]["send_queue"]
      @mailbox = @config["hbase_table"]["mailbox"]
      @databox = @config["hbase_table"]["databox"]
      @mynetworks = @config["mynetworks"]

      super(sock, domain)
    end

    def data_hook(data)
      data = data.to_blob
      Syslog.info("helo=#{@helo_name} from=#{@sender} to=#{@recipients.join(',')}")

      begin
        @recipients.each do |orig_to|
          domain = orig_to.split(/@/)[1]

          if @mydomains.include?(domain)
            mail_id = save_queue(data, orig_to, :local)
            Syslog.info("saved to local mail queue id=#{mail_id}")
          else
            mail_id = save_queue(data, orig_to, :send)
            Syslog.info("saved to send mail queue id=#{mail_id}")
          end
        end
      rescue Exception
        write_backtrace
        raise MailReceiveError.new
      end
    end

    def rcpt_hook(rcpts)
      rcpts.split(/,/).each do |rcpt|
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

    def save_queue(data, orig_to, queue_type = :local)
      QueueDB.open do |db|
        mail_id = get_message_id(data, @myhostname)

        case queue_type
        when :local
          tablename = "local_mailqueue"
        when :send
          tablename = "send_mailqueue"
        end

        db.exec("insert into #{tablename}
                   values (%s, %s, %s, %s, %s, %s, %s)",
                mail_id,
                @helo_name, @sender, @recipients.join(","),
                orig_to, Time.now, data.to_blob)

        return mail_id
      end  
    end

    def error(msg)
      Syslog.err(msg)
      super(msg)
    end

    def write_backtrace
      Syslog.err(format("%s: %s", $!.class, $!.message))
      Syslog.err("backtrace:")
      for line in $!.backtrace
        Syslog.info(line)
      end
    end
  end

  class MailReceiveError < StandardError
  end

  class ConfigError < StandardError
  end
end
