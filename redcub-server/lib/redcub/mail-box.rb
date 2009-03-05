module RedCub
  class MailBox
    attr_reader :user, :user_id

    def initialize(user)
      @user = user

      @config = Config.instance

      MailBoxDB.open do |db|
        @user_id = db.get_user_id(user)
      end
    end

    def save(mail)
      MailBoxDB.open do |db|
        QueueDB.open do |queue|
          db.transaction do
            queue.transaction do
              db.insert(mail.message_id, mail.helo_name, mail.sender, @user,
                        mail.receive_date, mail.data)
              queue.delete(:local, mail.message_id)
            end
          end
        end
      end
    end

    def exist_user?(name)
      MailBoxDB.open do |db|
        result = db.query("select user_id from users where name = %s",
                          name)
        return !result.empty?
      end
    end
  end

  class NoSuchUserError < StandardError
  end
end
