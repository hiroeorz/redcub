class Application < Merb::Controller
  include RedCub

  def entried_user?(args)
    auth_type = args[:auth_type]
    username = args[:username]
    password = args[:password]

    case auth_type
    when :pop3
      begin
        Net::POP3.auth_only(Merb::Config[:pop3auth_host],
                            Merb::Config[:pop3auth_port],
                            username, password)
        logger.info("New User authenticated by pop3 user=#{username}")
        return true
      rescue Net::POPAuthenticationError
        Merb.logger.warn("pop3 authentication failed user=#{username} password=#{password}")
        return false
      end

      return false
    end
  end

  def send_attached_data(id)
    config = RedCub::Config.instance

    file = Model::AttachedFile.first(:id => id,
                                     :user_id => session.user.id)
    send_data(file.file_data,
              :filename => file.filename,
              :type => file.filetype)
  end

  def transaction
    trs = DataMapper::Transaction.new(DataMapper.repository(:default))
    trs.begin
    DataMapper.repository(:default).adapter.push_transaction(trs)
    aborted = false
    
    begin
      yield
    rescue Exception => e
      DataMapper.repository(:default).adapter.pop_transaction
      trs.rollback
      aborted = true
      raise e.class.new(e.message)
    ensure
      unless aborted
        DataMapper.repository(:default).adapter.pop_transaction
        trs.commit
      end
    end
  end
end
