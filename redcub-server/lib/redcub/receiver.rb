module RedCub
  class Receiver < Daemon
    include Util

    def initialize
      super("receiver")
      @port = @config["smtpd"]["port"].to_i
      @domain = @config["mydomains"][0]
      @sock = TCPServer.new(@port)

      @line_length_limit = @config["smtpd"]["line_length_limit"]
      @input_timeout = @config["smtpd"]["input_timeout"]
      @error_interval = @config["smtpd"]["error_interval"]
      @max_size = @config["smtpd"]["max_size"].to_i * 1024 * 1024

      Syslog.info("receiver is ready.")
    end
    
    def start
      super

      loop do
        Thread.start(@sock.accept) do |s|
          client_name = s.peeraddr[2]
          ipaddr = s.peeraddr[3].gsub(/::ffff:/, "")
          
          begin  
            Syslog.info("connect from #{client_name}(#{ipaddr})")
            server = RedCubSMTPD.new(s, @domain)
            server.client_name = client_name
            server.remote_addr = ipaddr
            server.line_length_limit = @line_length_limit
            server.input_timeout = @input_timeout
            server.error_interval = @error_interval
            server.max_size = @max_size unless @max_size.zero?
            server.start
          rescue Exception
            write_backtrace
          ensure
            s.close
            Syslog.info("disconnct to #{client_name}(#{ipaddr})")
          end
        end
      end
    end
  end
end
