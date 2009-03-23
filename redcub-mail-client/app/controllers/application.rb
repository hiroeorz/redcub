class Application < Merb::Controller
  def entried_user?(args)
    auth_type = args[:auth_type]
    username = args[:username]
    password = args[:password]

    case auth_type
    when :pop3
      begin
        Net::POP3.auth_only(@configuration[:pop3auth_host],
                            @configuration[:pop3auth_port],
                            username, password)
        logger.info("New User authenticated by pop3 user=#{username}")
        return true
      rescue Net::POPAuthenticationError
        logger.warn("pop3 authentication failed user=#{username} password=#{password}")
        return false
      end

      return false
    end
  end
end
